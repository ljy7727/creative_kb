// 异步任务队列（docs/01 core/tasks/task_runner.dart，docs/02 A5）。
// 约束：并发 1；状态机 pending→running→success/failed（随时可 cancelled）；
// 失败自动重试 ≤2（指数退避 2s/8s）；单任务超时 120s；
// 启动时把遗留 running 重置为 pending 并恢复队列；
// 记账统一在任务收尾写 usage_log（成功/失败都记），日额度超限直接拦截。
// 与 LLM 层解耦：handler 由业务模块注册，本类不依赖 core/llm（并行开发）。
import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import 'usage_ledger.dart';

/// 任务处理器：正常返回即成功；抛异常即失败（默认可重试）。
/// 取消是协作式的：长任务应周期性检查 [TaskContext.isCancelled] 或调用
/// [TaskContext.throwIfCancelled]。
typedef TaskHandler = Future<void> Function(TaskContext context);

/// 非临时性错误（如鉴权失败、任务配置错误）：不参与自动重试。
/// 其他异常（网络类、JSON 校验失败等）默认按可重试处理（docs/02 A5）。
class NonRetryableTaskError implements Exception {
  const NonRetryableTaskError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 显式标记可重试的错误（供上层包装网络异常/校验失败用）。
class RetryableTaskError implements Exception {
  const RetryableTaskError(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => cause == null ? message : '$message（$cause）';
}

/// 任务被用户取消时由 [TaskContext.throwIfCancelled] 抛出。
class TaskCancelledException implements Exception {
  const TaskCancelledException();

  @override
  String toString() => '任务已取消';
}

/// 传给 handler 的执行上下文。
class TaskContext {
  TaskContext._(
    this.taskId,
    this.module,
    this.taskType,
    this.payload,
    this.maxTokensCap,
    this._isCancelled,
  );

  final int taskId;
  final String module;
  final String taskType;

  /// 解码后的任务参数；其中 maxTokens 已按「单次上限」设置封顶。
  final Map<String, dynamic> payload;

  /// 单次任务 token 上限设置值（null = 未限制），payload 未带 maxTokens 时
  /// handler 应以此值作为 max_tokens。
  final int? maxTokensCap;

  final bool Function() _isCancelled;

  /// 本次执行累计上报的用量（含重试的各次尝试），收尾统一落账。
  final List<UsageReport> reports = <UsageReport>[];

  /// handler 通过它向 task_queue.result 写回结果（通常为 JSON 字符串）。
  String? result;

  int _attempt = 0;

  /// 当前尝试次数（1 起）。
  int get attempt => _attempt;

  bool get isCancelled => _isCancelled();

  void throwIfCancelled() {
    if (isCancelled) throw const TaskCancelledException();
  }

  /// 上报一次 LLM 调用用量；费用由记账层按价格表估算。
  void reportUsage({
    required String providerName,
    required String model,
    String? presetCode,
    int inputTokens = 0,
    int outputTokens = 0,
    int durationMs = 0,
  }) {
    reports.add(
      UsageReport(
        providerName: providerName,
        model: model,
        presetCode: presetCode,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        durationMs: durationMs,
      ),
    );
  }
}

class TaskRunner {
  TaskRunner(
    this._db, {
    UsageLedger? ledger,
    Future<void> Function(Duration delay)? sleep,
    this.taskTimeout = const Duration(seconds: 120),
    this.maxRetries = 2,
    bool Function(Object error)? isRetryable,
  }) : _ledger = ledger ?? UsageLedger(_db),
       _sleep = sleep ?? ((delay) => Future<void>.delayed(delay)),
       _isRetryable =
           isRetryable ?? ((error) => error is! NonRetryableTaskError);

  final AppDatabase _db;
  final UsageLedger _ledger;
  final Future<void> Function(Duration delay) _sleep;
  final Duration taskTimeout;

  /// 每个失败后的最大重试次数（不含首次执行，docs/02 A5：≤2）。
  final int maxRetries;
  final bool Function(Object error) _isRetryable;

  TaskQueueDao get _queueDao => _db.taskQueueDao;

  final _handlers = <String, TaskHandler>{};
  final _pendingIds = Queue<int>();
  final _completers = <int, Completer<TaskQueueItem>>{};
  final _cancelRequested = <int>{};
  int? _runningId;
  bool _draining = false;
  bool _started = false;

  /// 注册任务处理器（同 taskType 后注册覆盖前者）。
  void registerHandler(String taskType, TaskHandler handler) =>
      _handlers[taskType] = handler;

  /// 启动：重置上次异常退出遗留的 running → pending，并把持久化任务装回内存队列。
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _queueDao.resetRunningToPending();
    final restored = await _queueDao.pending(limit: 100000);
    for (final row in restored) {
      _completers.putIfAbsent(row.id, Completer<TaskQueueItem>.new);
      _pendingIds.addLast(row.id);
    }
    _kick();
  }

  /// 入队并持久化（status=pending），返回任务 id。
  Future<int> enqueue({
    required String module,
    required String taskType,
    Map<String, dynamic> payload = const {},
  }) async {
    final id = await _queueDao.add(
      TaskQueueCompanion(
        module: Value(module),
        taskType: Value(taskType),
        payload: Value(jsonEncode(payload)),
      ),
    );
    _completers.putIfAbsent(id, Completer<TaskQueueItem>.new);
    _pendingIds.addLast(id);
    _kick();
    return id;
  }

  /// 等待任务到达终态（success/failed/cancelled），返回最终行。
  Future<TaskQueueItem> whenFinished(int id) {
    final completer = _completers[id];
    if (completer != null) return completer.future;
    // 非 runner 装载过的任务（如上个会话已完成）：直接查库。
    return _queueDao
        .byId(id)
        .then((row) => row ?? (throw StateError('任务不存在：$id')));
  }

  /// 取消任务：排队中 → 移出队列并置 cancelled；运行中 → 请求协作取消，
  /// DB 立即置 cancelled，handler 结束后不再覆盖。返回是否受理。
  Future<bool> cancel(int id) async {
    if (_runningId == id) {
      _cancelRequested.add(id);
      await _queueDao.markCancelled(id);
      return true;
    }
    final wasQueued = _pendingIds.remove(id);
    final row = await _queueDao.byId(id);
    if (row == null) return false;
    if (row.status != QueueTaskStatus.pending &&
        row.status != QueueTaskStatus.running) {
      if (wasQueued) _pendingIds.addFirst(id);
      return false;
    }
    _cancelRequested.add(id);
    await _queueDao.markCancelled(id);
    await _completeWithRow(id);
    return true;
  }

  /// 指数退避：第 1 次失败后 2s、第 2 次后 8s（docs/02 A5）。
  static Duration backoffDelay(int failedAttempts) {
    const table = [Duration(seconds: 2), Duration(seconds: 8)];
    // num.clamp 返回 num，需转回 int 作下标。
    final index = failedAttempts.clamp(1, table.length).toInt() - 1;
    return table[index];
  }

  void _kick() {
    if (_draining) return;
    _draining = true;
    unawaited(_drain());
  }

  Future<void> _drain() async {
    try {
      while (_pendingIds.isNotEmpty) {
        final id = _pendingIds.removeFirst();
        await _runOne(id);
      }
    } finally {
      _draining = false;
    }
    // 排空期间又有任务入队（enqueue 里的 _kick 会因 _draining 而跳过）。
    if (_pendingIds.isNotEmpty) _kick();
  }

  Future<void> _runOne(int id) async {
    final row = await _queueDao.byId(id);
    if (row == null || row.status != QueueTaskStatus.pending) return;

    // 日额度防护：执行前查当日累计，超限直接拦截（docs/01 第三节）。
    final quota = await _ledger.dailyUsage();
    if (quota.exceeded) {
      final message = quota.blockedMessage();
      await _ledger.recordBlocked(
        module: row.module,
        taskType: row.taskType,
        error: message,
      );
      await _queueDao.markFinished(id, success: false, error: message);
      await _completeWithRow(id);
      return;
    }

    final cap = await _ledger.singleTaskTokenCap();
    await _queueDao.markRunning(id);
    _runningId = id;
    final startedAt = DateTime.now();
    final context = TaskContext._(
      id,
      row.module,
      row.taskType,
      _clampedPayload(row.payload, cap),
      cap,
      () => _cancelRequested.contains(id),
    );
    try {
      var attempt = 0;
      while (true) {
        attempt++;
        context._attempt = attempt;
        try {
          final handler = _handlers[row.taskType];
          if (handler == null) {
            throw NonRetryableTaskError('任务类型未注册处理器：${row.taskType}');
          }
          await handler(context).timeout(taskTimeout);
          if (_cancelRequested.remove(id)) {
            await _finishCancelled(context);
          } else {
            await _finishSuccess(context, startedAt);
          }
          return;
        } catch (error) {
          if (_cancelRequested.remove(id)) {
            await _finishCancelled(context);
            return;
          }
          if (attempt <= maxRetries && _isRetryable(error)) {
            await _queueDao.incrementRetries(id);
            await _sleep(backoffDelay(attempt));
            continue;
          }
          await _finishFailure(context, error, startedAt);
          return;
        }
      }
    } finally {
      if (_runningId == id) _runningId = null;
      _cancelRequested.remove(id);
    }
  }

  Future<void> _finishSuccess(TaskContext context, DateTime startedAt) async {
    final wallMs = DateTime.now().difference(startedAt).inMilliseconds;
    await _queueDao.markFinished(
      context.taskId,
      success: true,
      result: context.result,
    );
    await _ledger.writeTaskReports(
      module: context.module,
      taskType: context.taskType,
      reports: context.reports,
      status: UsageStatus.ok,
      fallbackDurationMs: wallMs,
    );
    await _completeWithRow(context.taskId);
  }

  Future<void> _finishFailure(
    TaskContext context,
    Object error,
    DateTime startedAt,
  ) async {
    final wallMs = DateTime.now().difference(startedAt).inMilliseconds;
    final text = _errorText(error);
    await _queueDao.markFinished(context.taskId, success: false, error: text);
    await _ledger.writeTaskReports(
      module: context.module,
      taskType: context.taskType,
      reports: context.reports,
      status: UsageStatus.error,
      error: text,
      fallbackDurationMs: wallMs,
    );
    await _completeWithRow(context.taskId);
  }

  Future<void> _finishCancelled(TaskContext context) async {
    await _queueDao.markCancelled(context.taskId);
    // 已上报的用量照记（status=error），但没有上报则不补零行。
    await _ledger.writeTaskReports(
      module: context.module,
      taskType: context.taskType,
      reports: context.reports,
      status: UsageStatus.error,
      error: '任务已取消',
      writeSyntheticWhenEmpty: false,
    );
    await _completeWithRow(context.taskId);
  }

  String _errorText(Object error) {
    if (error is TimeoutException) {
      final seconds = taskTimeout.inSeconds;
      return seconds >= 1
          ? '任务超时（超过 ${seconds}s 未完成）'
          : '任务超时（超过 ${taskTimeout.inMilliseconds}ms 未完成）';
    }
    return error.toString();
  }

  /// payload 中 maxTokens 超过单次上限时封顶（docs/01 第三节）。
  Map<String, dynamic> _clampedPayload(String raw, int? cap) {
    var payload = <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } on FormatException {
      payload = <String, dynamic>{};
    }
    if (cap != null) {
      final requested = payload['maxTokens'];
      if (requested is num && requested.round() > cap) {
        payload['maxTokens'] = cap;
      }
    }
    return payload;
  }

  Future<void> _completeWithRow(int id) async {
    final completer = _completers[id];
    if (completer == null || completer.isCompleted) return;
    final row = await _queueDao.byId(id);
    if (row != null && !completer.isCompleted) completer.complete(row);
  }
}
