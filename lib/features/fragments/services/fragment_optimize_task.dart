// FragmentOptimizeTask：灵感优化 AI 任务（docs/02 B1/B2）。
// 职责：构建提示词 → 调用 AI（校验失败把错误拼回消息重试 ≤2 次）→
// 契约解析 → 多条拆分入库（首条回写原行，其余插入派生行）。
// 队列状态机、日额度拦截、单次 max_tokens 封顶与 usage_log 记账均由
// core/tasks TaskRunner/UsageLedger 统一负责（docs/02 A5），本任务只上报用量。
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ProviderException（watch 错误态 provider 时的包装异常）在 misc 导出中。
import 'package:flutter_riverpod/misc.dart';

import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/tasks/task_runner.dart';
import '../../../core/tasks/task_runner_provider.dart';
import '../models/fragment_models.dart';
import 'fragment_ai_invoker.dart';
import 'fragment_prompt.dart';

/// 任务收尾上报给 TaskContext 的一次用量汇总（含重试的各次尝试累计）。
typedef FragmentUsageReport = ({
  String providerName,
  String modelId,
  String presetCode,
  int inputTokens,
  int outputTokens,
  int durationMs,
});

/// 一次任务的结果。
class FragmentOptimizeOutcome {
  const FragmentOptimizeOutcome({
    required this.ok,
    required this.fragmentId,
    this.count = 0,
    this.error,
  });

  final bool ok;
  final int fragmentId;

  /// 本次产出的条目数（含原始行自身）。
  final int count;
  final String? error;
}

/// 重试后契约校验仍失败：携带失败前已消耗的 usage 供上报。
class _ContractFailure implements Exception {
  _ContractFailure(
    this.exception, {
    required this.inputTokens,
    required this.outputTokens,
    required this.retries,
  });

  final FragmentContractException exception;
  final int inputTokens;
  final int outputTokens;
  final int retries;
}

class FragmentOptimizeTask {
  FragmentOptimizeTask({required this.db, required this.invoker});

  final AppDatabase db;
  final FragmentAiInvoker invoker;

  static const module = FragmentOptimizePrompt.module;
  static const taskType = FragmentOptimizePrompt.taskType;

  /// 任务队列 payload 契约（context.payload / task_queue.payload 均按此解码）。
  static String payloadJson({
    required int fragmentId,
    required String intensityCode,
  }) => jsonEncode({'fragmentId': fragmentId, 'intensity': intensityCode});

  static ({int fragmentId, String intensityCode}) decodePayload(
    Object payload,
  ) {
    final decoded = payload is Map ? payload : jsonDecode(payload as String);
    if (decoded is! Map) throw const FormatException('payload 不是 JSON 对象');
    final fragmentId = (decoded['fragmentId'] as num?)?.toInt();
    final intensity = decoded['intensity'];
    if (fragmentId == null || intensity is! String) {
      throw const FormatException('payload 缺少 fragmentId/intensity');
    }
    return (fragmentId: fragmentId, intensityCode: intensity);
  }

  /// 构造 TaskRunner 处理器（fragmentsTaskBridgeProvider 与测试共用）。
  /// 失败一律转 NonRetryableTaskError：任务内的重试（含 StructuredOutput
  /// 内部重试）已按 docs/01 第五节执行完毕，队列层不再重试。
  static TaskHandler makeHandler({
    required AppDatabase db,
    required FragmentAiInvoker invoker,
  }) {
    return (context) async {
      final params = decodePayload(context.payload);
      final outcome = await FragmentOptimizeTask(db: db, invoker: invoker).run(
        fragmentId: params.fragmentId,
        intensityCode: params.intensityCode,
        maxTokensCap: context.maxTokensCap,
        onUsage: (usage) => context.reportUsage(
          providerName: usage.providerName,
          model: usage.modelId,
          presetCode: usage.presetCode,
          inputTokens: usage.inputTokens,
          outputTokens: usage.outputTokens,
          durationMs: usage.durationMs,
        ),
      );
      if (!outcome.ok) {
        throw NonRetryableTaskError(outcome.error ?? '灵感优化失败');
      }
      context.result = '整理为 ${outcome.count} 条灵感';
    };
  }

  /// 执行一次优化。AI/校验类失败不抛异常，返回 ok=false 的结果；
  /// 程序性错误（灵感不存在）抛 [FragmentOptimizeException]。
  Future<FragmentOptimizeOutcome> run({
    required int fragmentId,
    required String intensityCode,
    int? maxTokensCap,
    void Function(FragmentUsageReport report)? onUsage,
  }) async {
    final fragment = await db.fragmentsDao.byId(fragmentId);
    if (fragment == null) {
      throw FragmentOptimizeException('灵感 #$fragmentId 不存在，可能已被删除');
    }

    final preset = await db.intensityPresetsDao.byCode(intensityCode);
    var params = OptimizeParams.fromPresetJson(preset?.params ?? '{}');
    if (maxTokensCap != null && maxTokensCap > 0) {
      params = params.cappedMaxTokens(maxTokensCap);
    }

    final pick = await pickOptimizeModel(db);
    if (pick == null) {
      await db.fragmentsDao.markFailed(
        fragmentId,
        aiMetaWithError(aiNotConfiguredMessage),
      );
      return FragmentOptimizeOutcome(
        ok: false,
        fragmentId: fragmentId,
        error: aiNotConfiguredMessage,
      );
    }

    final stopwatch = Stopwatch()..start();
    FragmentUsageReport usageReport({
      required int inputTokens,
      required int outputTokens,
    }) => (
      providerName: pick.provider.name,
      modelId: pick.model.modelId,
      presetCode: intensityCode,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      durationMs: stopwatch.elapsedMilliseconds,
    );

    try {
      final attempt = await _requestItems(
        rawText: fragment.rawText,
        params: params,
        providerName: pick.provider.name,
        baseUrl: pick.provider.baseUrl,
        keyRef: pick.provider.keyRef!,
        modelId: pick.model.modelId,
      );
      final count = await _persist(
        fragment: fragment,
        items: attempt.items,
        providerName: pick.provider.name,
        modelId: pick.model.modelId,
        presetCode: intensityCode,
        inputTokens: attempt.inputTokens,
        outputTokens: attempt.outputTokens,
        retries: attempt.retries,
      );
      stopwatch.stop();
      onUsage?.call(
        usageReport(
          inputTokens: attempt.inputTokens,
          outputTokens: attempt.outputTokens,
        ),
      );
      return FragmentOptimizeOutcome(
        ok: true,
        fragmentId: fragmentId,
        count: count,
      );
    } on _ContractFailure catch (failure) {
      stopwatch.stop();
      onUsage?.call(
        usageReport(
          inputTokens: failure.inputTokens,
          outputTokens: failure.outputTokens,
        ),
      );
      final message =
          'AI 输出不符合约定格式，已重试 ${failure.retries} 次仍失败：${failure.exception.message}';
      await db.fragmentsDao.markFailed(fragmentId, aiMetaWithError(message));
      return FragmentOptimizeOutcome(
        ok: false,
        fragmentId: fragmentId,
        error: message,
      );
    } on FragmentOptimizeException catch (error) {
      stopwatch.stop();
      await db.fragmentsDao.markFailed(
        fragmentId,
        aiMetaWithError(error.message),
      );
      return FragmentOptimizeOutcome(
        ok: false,
        fragmentId: fragmentId,
        error: error.message,
      );
    } on Exception catch (error) {
      stopwatch.stop();
      // 网络/调用类失败：usage token 不可知记 0。
      final message = 'AI 调用失败：$error';
      await db.fragmentsDao.markFailed(fragmentId, aiMetaWithError(message));
      return FragmentOptimizeOutcome(
        ok: false,
        fragmentId: fragmentId,
        error: message,
      );
    }
  }

  /// 失败时写入 aiMeta（仅错误信息，供详情页展示与排查）。
  String aiMetaWithError(String message) => const JsonEncoder().convert({
    'error': message,
    'ts': DateTime.now().toIso8601String(),
  });

  /// 调用并解析；校验失败把错误拼回消息重试 ≤2 次（docs/01 第五节）。
  Future<
    ({
      List<FragmentOptimizeItem> items,
      int retries,
      int inputTokens,
      int outputTokens,
    })
  >
  _requestItems({
    required String rawText,
    required OptimizeParams params,
    required String providerName,
    required String baseUrl,
    required String keyRef,
    required String modelId,
  }) async {
    const maxRetries = 2;
    var userPrompt = FragmentOptimizePrompt.userPrompt(rawText);
    var inputTokens = 0;
    var outputTokens = 0;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      final reply = await invoker.invoke(
        FragmentAiRequest(
          systemPrompt: FragmentOptimizePrompt.systemPrompt,
          userPrompt: userPrompt,
          providerName: providerName,
          baseUrl: baseUrl,
          keyRef: keyRef,
          modelId: modelId,
          params: params,
        ),
      );
      inputTokens += reply.inputTokens;
      outputTokens += reply.outputTokens;
      try {
        return (
          items: parseOptimizeOutput(reply.content),
          retries: attempt,
          inputTokens: inputTokens,
          outputTokens: outputTokens,
        );
      } on FragmentContractException catch (error) {
        if (attempt < maxRetries) {
          userPrompt = FragmentOptimizePrompt.retryUserPrompt(
            rawText,
            error.message,
          );
        } else {
          throw _ContractFailure(
            error,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            retries: attempt,
          );
        }
      }
    }
    // 循环必在 return/throw 处退出；此处不可达。
    throw StateError('unreachable');
  }

  /// 拆分入库：首条回写原行（保留 manual 来源与 rawText 双版本），
  /// 其余插入派生行（source=ai，aiMeta.originId 指向原行）。返回总条数。
  Future<int> _persist({
    required Fragment fragment,
    required List<FragmentOptimizeItem> items,
    required String providerName,
    required String modelId,
    required String presetCode,
    required int inputTokens,
    required int outputTokens,
    required int retries,
  }) async {
    // 重新优化：替换上次拆分产生的派生行，避免重复累积。
    await removeDerivedRows(db, fragment.id);

    final userTags = decodeTags(fragment.tags);

    final first = items.first;
    await db.fragmentsDao.applyOptimization(
      id: fragment.id,
      title: first.title,
      optimizedJson: jsonEncode(first.toJson()),
      tagsJson: encodeTags(mergeTags(userTags, first.tags)),
      aiMetaJson: FragmentAiMeta(
        providerName: providerName,
        model: modelId,
        presetCode: presetCode,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        ts: DateTime.now(),
        retries: retries,
      ).encode(),
    );

    for (final item in items.skip(1)) {
      await db.fragmentsDao.add(
        FragmentsCompanion.insert(
          rawText: fragment.rawText,
          source: FragmentSource.ai,
          title: Value(item.title),
          optimizedJson: Value(jsonEncode(item.toJson())),
          tags: Value(encodeTags(item.tags)),
          aiMeta: Value(
            FragmentAiMeta(
              providerName: providerName,
              model: modelId,
              presetCode: presetCode,
              inputTokens: inputTokens,
              outputTokens: outputTokens,
              ts: DateTime.now(),
              originId: fragment.id,
              retries: retries,
            ).encode(),
          ),
          status: const Value(FragmentStatus.optimized),
        ),
      );
    }
    return items.length;
  }
}

/// 删除某条灵感拆分出的派生行（删除原行与重新优化前均调用）。
Future<void> removeDerivedRows(AppDatabase db, int originId) async {
  final all = await db.fragmentsDao.getAll();
  for (final row in all) {
    final meta = FragmentAiMeta.tryDecode(row.aiMeta);
    if (meta?.originId == originId) {
      await db.fragmentsDao.remove(row.id);
    }
  }
}

/// 把 FragmentOptimizeTask 注册进全局 TaskRunner（docs/02 A5）。
/// FragmentsPage/FragmentDetailPage watch 本 provider：首页常驻即等效
/// 应用启动完成注册。数据库未注入（冒烟壳层）时静默跳过。
final fragmentsTaskBridgeProvider = Provider<void>((ref) {
  try {
    final runner = ref.watch(taskRunnerProvider);
    final db = ref.watch(appDatabaseProvider);
    final invoker = ref.watch(fragmentAiInvokerProvider);
    runner.registerHandler(
      FragmentOptimizeTask.taskType,
      FragmentOptimizeTask.makeHandler(db: db, invoker: invoker),
    );
  } on ProviderException {
    // 裸 ProviderScope（无数据库注入）：跳过任务注册。
  }
});
