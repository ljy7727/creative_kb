import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_setting_keys.dart';
import '../../../core/db/database.dart';
import '../../../core/seed/price_table.dart';
import '../models/kb_ingest_models.dart';
import '../models/kb_schema.dart';
import 'kb_ai_gateway.dart';

/// 思考强度参数（intensity_presets.params JSON：temperature/maxTokens）。
class IntensityParams {
  const IntensityParams({required this.code, this.temperature, this.maxTokens});

  factory IntensityParams.fromPreset(IntensityPreset preset) {
    double? temperature;
    int? maxTokens;
    try {
      final params = jsonDecode(preset.params);
      if (params is Map<String, dynamic>) {
        temperature = (params['temperature'] as num?)?.toDouble();
        maxTokens = (params['maxTokens'] as num?)?.toInt();
      }
    } catch (_) {
      // 非法 params 按无参处理。
    }
    return IntensityParams(
      code: preset.code,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  final String code;
  final double? temperature;
  final int? maxTokens;
}

/// 入库任务执行结果（UI 据此渲染步骤 2→3）。
class KbIngestOutcome {
  const KbIngestOutcome({
    this.result,
    this.error,
    this.blocked = false,
    this.attempts = 0,
    this.inputTokens = 0,
    this.outputTokens = 0,
  });

  final KbIngestResult? result;

  /// 失败原因（重试耗尽后的最终错误，展示给用户）。
  final String? error;

  /// true = 被日额度拦截（docs/02 A5）。
  final bool blocked;
  final int attempts;
  final int inputTokens;
  final int outputTokens;
}

/// KbIngestTask（docs/02 D2 第2步）：清洗 + 分类 + 结构化。
/// JSON 校验失败自动重试 ≤2 次（共 ≤3 次调用，docs/01 第五节）；
/// 全链路写 task_queue 与 usage_log（module=kb, taskType=kb_ingest）。
class KbIngestTask {
  KbIngestTask(this._db, {required this.gateway, required this.loadSchemas});

  static const module = 'kb';
  static const taskType = 'kb_ingest';

  final AppDatabase _db;
  final KbAiGateway gateway;

  /// Schema 注册表读取器（热加载：每次执行现读目录）。
  final Future<List<KbSchema>> Function() loadSchemas;

  Future<KbIngestOutcome> run({
    required String rawText,
    required IntensityParams intensity,
  }) async {
    // —— 额度防护：日上限（docs/01 第三节；拦截也要留下用量记录供看板可见）。
    final settings = await _db.appSettingsDao.getAll();
    final dailyMax = int.tryParse(
      settings[AppSettingKeys.dailyMaxTokens] ?? '',
    );
    if (dailyMax != null && dailyMax > 0) {
      final today = await _db.usageLogDao.todayTokens();
      if (today >= dailyMax) {
        await _logUsage(
          providerName: '-',
          model: '-',
          presetCode: intensity.code,
          inputTokens: 0,
          outputTokens: 0,
          durationMs: 0,
          status: UsageStatus.blocked,
          error: '今日额度已用尽（$today/$dailyMax），任务被拦截',
        );
        return KbIngestOutcome(
          blocked: true,
          error: '今日 token 额度已用尽（已用 $today / 上限 $dailyMax），可在设置中调整限额',
        );
      }
    }
    // 单次上限以 max_tokens 封顶。
    var maxTokens = intensity.maxTokens;
    final singleMax = int.tryParse(
      settings[AppSettingKeys.singleTaskMaxTokens] ?? '',
    );
    if (singleMax != null &&
        singleMax > 0 &&
        (maxTokens == null || maxTokens > singleMax)) {
      maxTokens = singleMax;
    }

    // —— 队列行（可审计；向导内联执行，进度由向导页呈现）。
    final schemas = await loadSchemas();
    final categories = await _db.kbCategoriesDao.getAll();
    final knownNames = (await _db.kbEntriesDao.getAll())
        .map((e) => e.entryName)
        .toList();
    final system = buildSystemPrompt(
      schemas: schemas,
      categoryPaths: categories.map((c) => c.path).toList(),
      knownEntryNames: knownNames,
    );
    final baseUser = '请整理以下资料：\n\n$rawText';
    final queueId = await _db.taskQueueDao.add(
      TaskQueueCompanion.insert(
        module: module,
        taskType: taskType,
        payload: jsonEncode({
          'textLength': rawText.length,
          'intensity': intensity.code,
        }),
      ),
    );
    await _db.taskQueueDao.markRunning(queueId);

    final watch = Stopwatch()..start();
    var user = baseUser;
    var inputTokens = 0;
    var outputTokens = 0;
    String? lastError;
    const maxAttempts = 3; // 首次 + 重试 ≤2

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final KbAiCompletion completion;
      try {
        completion = await gateway.complete(
          system: system,
          user: user,
          temperature: intensity.temperature,
          maxTokens: maxTokens,
        );
      } catch (e) {
        lastError = '调用模型失败：$e';
        break; // 网络/鉴权类异常重试由网关层负责，这里直接失败并留痕
      }
      inputTokens += completion.inputTokens;
      outputTokens += completion.outputTokens;
      try {
        final result = KbIngestParser.parse(completion.text);
        await _db.taskQueueDao.markFinished(
          queueId,
          success: true,
          result: jsonEncode({
            'entries': [for (final e in result.entries) e.entryName],
            'proposedCategory': result.proposedCategory,
            'proposedSchemaId': result.proposedSchemaId,
          }),
        );
        await _logUsage(
          providerName: completion.providerName,
          model: completion.model,
          presetCode: intensity.code,
          inputTokens: inputTokens,
          outputTokens: outputTokens,
          durationMs: watch.elapsedMilliseconds,
          status: UsageStatus.ok,
        );
        return KbIngestOutcome(
          result: result,
          attempts: attempt,
          inputTokens: inputTokens,
          outputTokens: outputTokens,
        );
      } on KbIngestValidationException catch (e) {
        lastError = e.message;
        if (attempt < maxAttempts) {
          // 校验错误拼回消息重试（docs/01 第五节）。
          user =
              '$baseUser\n\n'
              '你上一次的输出未通过校验，错误：\n'
              '${e.issues.map((s) => '- $s').join('\n')}\n'
              '请修正后重新输出，仍然只输出 JSON 对象。';
        }
      }
    }

    await _db.taskQueueDao.markFinished(
      queueId,
      success: false,
      error: lastError,
    );
    await _logUsage(
      providerName: '-',
      model: '-',
      presetCode: intensity.code,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      durationMs: watch.elapsedMilliseconds,
      status: UsageStatus.error,
      error: lastError,
    );
    return KbIngestOutcome(
      error: lastError,
      attempts: maxAttempts,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );
  }

  /// 系统提示词（docs/02 D2/D3 契约：附分类树现状 + Schema 摘要 + 已有条目名）。
  static String buildSystemPrompt({
    required List<KbSchema> schemas,
    required List<String> categoryPaths,
    required List<String> knownEntryNames,
  }) {
    final treeDesc = categoryPaths.isEmpty
        ? '（暂无分类，proposedCategory 一律填 未分类）'
        : categoryPaths.map((p) => '- $p').join('\n');
    final schemaDesc = schemas.isEmpty
        ? '（暂无，proposedSchemaId 填 general）'
        : schemas.map((s) => s.promptDigest()).join('\n');
    final namesDesc = knownEntryNames.isEmpty
        ? '（暂无）'
        : knownEntryNames.take(300).join('、');
    return '''
你是创作资料库的资料整理助手，负责把原始创作资料清洗、结构化为知识条目。只输出一个 JSON 对象，禁止输出解释文字、开场白或 Markdown 代码围栏之外的内容。

输出结构：
{"cleaned":"去广告/冗余后的完整正文(Markdown 字符串)",
 "proposedCategory":"建议分类路径(用/分隔层级，必须从下方分类树中选择；都不合适填 未分类)",
 "proposedSchemaId":"建议 Schema id(必须从下方 Schema 列表中选择；无合适项填 general)",
 "entries":[{
   "entryName":"条目名称(简短、唯一)",
   "summary":"一句话概述",
   "contentMd":"条目正文(结构化 Markdown，可用小标题/列表)",
   "tags":["标签"],
   "relatedEntries":["关联条目名"],
   "credibility":"high|mid|low",
   "<扩展字段key>":"按条目适用 Schema 的 fields 填写"
 }]}

规则：
1. 一段资料包含多个独立主题时拆分为多个 entries；单一主题只输出一条。
2. 不得编造原文没有的事实性信息；不确定的保留原表述并在句尾加 (存疑)。
3. relatedEntries 只能引用「已有条目」列表中确定存在的名称，宁缺毋滥，没有则给空数组。
4. credibility 依据原文可信程度取 high/mid/low，无法判断填 mid。
5. 扩展字段按适用的 Schema fields 填写；number 类型填数字，markdown 类型填 Markdown 文本；不适用则省略该 key，不得发明列表之外的字段。

【分类树】
$treeDesc

【Schema 列表】
$schemaDesc

【已有条目】
$namesDesc''';
  }

  Future<void> _logUsage({
    required String providerName,
    required String model,
    required String presetCode,
    required int inputTokens,
    required int outputTokens,
    required int durationMs,
    required UsageStatus status,
    String? error,
  }) {
    final cost = status == UsageStatus.ok && model != '-'
        ? PriceTable.estimateCost(
            modelId: model,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
          )
        : null;
    return _db.usageLogDao.add(
      UsageLogsCompanion.insert(
        module: module,
        taskType: taskType,
        providerName: providerName,
        model: model,
        presetCode: Value(presetCode),
        inputTokens: Value(inputTokens),
        outputTokens: Value(outputTokens),
        costEstimate: Value(cost),
        durationMs: Value(durationMs),
        status: status,
        error: Value(error),
      ),
    );
  }
}
