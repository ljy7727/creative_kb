// core/tasks 单测（docs/03 测试策略：状态机流转、重试与退避、超时、日额度拦截、记账字段）。
import 'dart:async';

import 'package:creative_kb/core/db/app_setting_keys.dart';
import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/core/tasks/task_runner.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> noSleep(Duration delay) async {}

  UsageLogsCompanion usageRow({
    int input = 0,
    int output = 0,
    UsageStatus status = UsageStatus.ok,
  }) => UsageLogsCompanion.insert(
    module: 'fragments',
    taskType: 'seed',
    providerName: 'p',
    model: 'seed-model',
    status: status,
    inputTokens: Value(input),
    outputTokens: Value(output),
  );

  test(
    '状态机成功路径：pending→running→success，记录起止时间与 result，并补零 token 记账行',
    () async {
      final runner = TaskRunner(db, sleep: noSleep);
      runner.registerHandler('demo', (ctx) async {
        ctx.result = '"ok"';
        ctx.throwIfCancelled();
      });
      final id = await runner.enqueue(
        module: 'fragments',
        taskType: 'demo',
        payload: {'a': 1},
      );

      final row = await runner.whenFinished(id);
      expect(row.status, QueueTaskStatus.success);
      expect(row.result, '"ok"');
      expect(row.startedAt, isNotNull);
      expect(row.finishedAt, isNotNull);
      expect(row.retries, 0);
      expect(row.module, 'fragments');
      expect(row.taskType, 'demo');

      final logs = await db.usageLogDao.recent();
      expect(logs, hasLength(1));
      expect(logs.single.status, UsageStatus.ok);
      expect(logs.single.module, 'fragments');
    },
  );

  test('持续失败：指数退避 2s/8s，重试 ≤2 后置 failed，记账 status=error', () async {
    final delays = <Duration>[];
    final runner = TaskRunner(db, sleep: (delay) async => delays.add(delay));
    runner.registerHandler('boom', (ctx) async => throw StateError('boom'));

    final id = await runner.enqueue(module: 'prompts', taskType: 'boom');
    final row = await runner.whenFinished(id);

    expect(row.status, QueueTaskStatus.failed);
    expect(row.retries, 2);
    expect(delays, [const Duration(seconds: 2), const Duration(seconds: 8)]);
    expect(row.error, contains('boom'));

    final logs = await db.usageLogDao.recent();
    expect(logs, hasLength(1));
    expect(logs.single.status, UsageStatus.error);
    expect(logs.single.error, contains('boom'));
  });

  test('前两次失败第三次成功：重试 2 次后 success，retries=2', () async {
    var calls = 0;
    final delays = <Duration>[];
    final runner = TaskRunner(db, sleep: (delay) async => delays.add(delay));
    runner.registerHandler('flaky', (ctx) async {
      calls++;
      if (calls < 3) throw const RetryableTaskError('临时失败');
      ctx.result = '{"ok":true}';
    });

    final id = await runner.enqueue(module: 'kb', taskType: 'flaky');
    final row = await runner.whenFinished(id);

    expect(calls, 3);
    expect(row.status, QueueTaskStatus.success);
    expect(row.retries, 2);
    expect(delays, [const Duration(seconds: 2), const Duration(seconds: 8)]);
  });

  test('任务超时按失败处理，错误信息可读', () async {
    final runner = TaskRunner(
      db,
      sleep: noSleep,
      taskTimeout: const Duration(milliseconds: 50),
      maxRetries: 0,
    );
    runner.registerHandler('slow', (ctx) async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });

    final id = await runner.enqueue(module: 'kb', taskType: 'slow');
    final row = await runner.whenFinished(id);

    expect(row.status, QueueTaskStatus.failed);
    expect(row.error, contains('超时'));
    // 让悬挂的内层计时器跑完，避免污染测试环境。
    await Future<void>.delayed(const Duration(milliseconds: 450));
  });

  test('当日额度超限：任务不执行直接 failed，记账写入 blocked 行', () async {
    await db.appSettingsDao.set(AppSettingKeys.dailyMaxTokens, '100');
    await db.usageLogDao.add(usageRow(input: 60, output: 41));

    var ran = false;
    final runner = TaskRunner(db, sleep: noSleep);
    runner.registerHandler('demo', (ctx) async => ran = true);

    final id = await runner.enqueue(module: 'kb', taskType: 'demo');
    final row = await runner.whenFinished(id);

    expect(ran, isFalse);
    expect(row.status, QueueTaskStatus.failed);
    expect(row.error, contains('额度'));

    final logs = await db.usageLogDao.recent();
    expect(logs.first.status, UsageStatus.blocked);
    expect(logs.first.error, contains('额度'));
    expect(logs, hasLength(2));
  });

  test('单次上限封顶 payload.maxTokens；未带 maxTokens 时 handler 可读取 cap', () async {
    await db.appSettingsDao.set(AppSettingKeys.singleTaskMaxTokens, '8192');
    final payloads = <Map<String, dynamic>>[];
    final caps = <int?>[];
    final runner = TaskRunner(db, sleep: noSleep);
    runner.registerHandler('cap', (ctx) async {
      payloads.add(Map<String, dynamic>.of(ctx.payload));
      caps.add(ctx.maxTokensCap);
    });

    final first = await runner.enqueue(
      module: 'fragments',
      taskType: 'cap',
      payload: {'maxTokens': 999999, 'k': 'v'},
    );
    final second = await runner.enqueue(
      module: 'fragments',
      taskType: 'cap',
      payload: {'k': 'v'},
    );
    await runner.whenFinished(first);
    await runner.whenFinished(second);

    expect(payloads[0]['maxTokens'], 8192);
    expect(payloads[0]['k'], 'v');
    expect(payloads[1]['maxTokens'], isNull);
    expect(caps[0], 8192);
  });

  test('记账字段完整：模块/任务/厂商/模型/强度/token/时长/费用估值', () async {
    final runner = TaskRunner(db, sleep: noSleep);
    runner.registerHandler('pay', (ctx) async {
      ctx.reportUsage(
        providerName: 'DeepSeek',
        model: 'deepseek-chat',
        presetCode: 'fast',
        inputTokens: 1000000,
        outputTokens: 500000,
        durationMs: 1200,
      );
    });

    final id = await runner.enqueue(module: 'prompts', taskType: 'pay');
    final row = await runner.whenFinished(id);
    expect(row.status, QueueTaskStatus.success);

    final log = (await db.usageLogDao.recent()).single;
    expect(log.module, 'prompts');
    expect(log.taskType, 'pay');
    expect(log.providerName, 'DeepSeek');
    expect(log.model, 'deepseek-chat');
    expect(log.presetCode, 'fast');
    expect(log.inputTokens, 1000000);
    expect(log.outputTokens, 500000);
    expect(log.durationMs, 1200);
    expect(log.status, UsageStatus.ok);
    expect(log.error, isNull);
    // deepseek-chat：输入 2 元/百万 + 输出 8 元/百万 → 2 + 4 = 6。
    expect(log.costEstimate, closeTo(6.0, 1e-9));
    expect(log.ts, isNotNull);
  });

  test('失败也记账：已上报 token 保留，未知模型费用为 null', () async {
    final runner = TaskRunner(db, sleep: noSleep);
    runner.registerHandler('payfail', (ctx) async {
      ctx.reportUsage(
        providerName: 'X',
        model: 'unknown-model',
        inputTokens: 10,
        outputTokens: 20,
      );
      throw const NonRetryableTaskError('bad');
    });

    final id = await runner.enqueue(module: 'kb', taskType: 'payfail');
    final row = await runner.whenFinished(id);

    expect(row.status, QueueTaskStatus.failed);
    expect(row.retries, 0);

    final log = (await db.usageLogDao.recent()).single;
    expect(log.status, UsageStatus.error);
    expect(log.error, contains('bad'));
    expect(log.inputTokens, 10);
    expect(log.outputTokens, 20);
    expect(log.costEstimate, isNull);
  });

  test('取消排队中的任务：置 cancelled 且不再执行', () async {
    final release = Completer<void>();
    var secondRan = false;
    final runner = TaskRunner(db, sleep: noSleep);
    runner.registerHandler('block', (ctx) async => release.future);
    runner.registerHandler('second', (ctx) async => secondRan = true);

    final first = await runner.enqueue(module: 't', taskType: 'block');
    final second = await runner.enqueue(module: 't', taskType: 'second');
    expect(await runner.cancel(second), isTrue);

    release.complete();
    final cancelledRow = await runner.whenFinished(second);
    expect(cancelledRow.status, QueueTaskStatus.cancelled);
    expect(secondRan, isFalse);
    expect((await runner.whenFinished(first)).status, QueueTaskStatus.success);
  });

  test('取消运行中的任务：协作取消后终态为 cancelled', () async {
    final runner = TaskRunner(db, sleep: noSleep);
    runner.registerHandler('long', (ctx) async {
      while (!ctx.isCancelled) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });

    final id = await runner.enqueue(module: 't', taskType: 'long');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(await runner.cancel(id), isTrue);

    final row = await runner.whenFinished(id);
    expect(row.status, QueueTaskStatus.cancelled);
  });

  test('start() 把遗留 running 重置为 pending 并恢复执行', () async {
    await db.taskQueueDao.add(
      TaskQueueCompanion.insert(
        module: 't',
        taskType: 'demo',
        payload: '{}',
        status: const Value(QueueTaskStatus.running),
      ),
    );
    await db.taskQueueDao.add(
      TaskQueueCompanion.insert(module: 't', taskType: 'demo', payload: '{}'),
    );

    var ran = 0;
    final runner = TaskRunner(db, sleep: noSleep);
    runner.registerHandler('demo', (ctx) async => ran++);
    await runner.start();

    for (var i = 0; i < 100 && ran < 2; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(ran, 2);
    expect(await db.taskQueueDao.byStatus(QueueTaskStatus.pending), isEmpty);
    expect(await db.taskQueueDao.byStatus(QueueTaskStatus.running), isEmpty);
    expect(
      await db.taskQueueDao.byStatus(QueueTaskStatus.success),
      hasLength(2),
    );
  });
}
