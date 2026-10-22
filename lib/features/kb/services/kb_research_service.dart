// 资料库「AI 搜集」管线（DeepSeek Search/Fetch）：
// 检索词生成 → 联网搜索 → 可选抓取正文 → 汇总素材 → 复用 KbIngestTask 结构化。
// 搜索/抓取消耗 DeepSeek API（不计 token）；检索词与结构化调用计入 usage_log。
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_setting_keys.dart';
import '../../../core/db/database.dart';
import '../../../core/llm/deepseek_tools.dart';
import '../../../core/llm/llm_client.dart';
import '../../../core/llm/providers.dart';
import '../../../core/seed/price_table.dart';
import '../../../core/storage/secure_keys.dart';
import 'kb_ingest_task.dart';

/// 一次 AI 搜集的结果。
class KbResearchOutcome {
  const KbResearchOutcome({
    this.ingest,
    this.error,
    this.blocked = false,
    this.queries = const <String>[],
    this.items = const <DeepSeekSearchItem>[],
    this.fetchedPages = 0,
    this.inputTokens = 0,
    this.outputTokens = 0,
  });

  /// 结构化结果（非空时由调用方进入预览入库）。
  final KbIngestOutcome? ingest;
  final String? error;
  final bool blocked;
  final List<String> queries;
  final List<DeepSeekSearchItem> items;

  /// 成功抓取正文的页面数。
  final int fetchedPages;
  final int inputTokens;
  final int outputTokens;
}

/// 搜集阶段回调（UI 进度展示）。
typedef ResearchStageCallback = void Function(String stage);

/// 执行 AI 搜集。需要已配置 DeepSeek 厂商（其 /v1/tools 接口）。
class KbResearchService {
  KbResearchService(
    this._db, {
    required this.tools,
    required this.ingest,
    LlmClient? client,
    SecureKeys? secureKeys,
  }) : _client = client ?? OpenAiCompatLlmClient(),
       _secureKeys = secureKeys ?? SecureKeys();

  static const module = 'kb';
  static const taskType = 'kb_research';

  /// 单条搜索结果的正文截断与素材总长上限（控制提示词体积）。
  static const _itemTextCap = 2500;
  static const _fetchTextCap = 5000;
  static const _materialCap = 30000;
  static const _maxItems = 24;
  static const _maxFetchPages = 3;

  final AppDatabase _db;
  final DeepSeekToolsClient tools;
  final KbIngestTask ingest;
  final LlmClient _client;
  final SecureKeys _secureKeys;

  Future<KbResearchOutcome> run({
    required String topic,
    required IntensityParams intensity,
    bool fetchPages = true,
    ResearchStageCallback? onStage,
  }) async {
    final trimmedTopic = topic.trim();
    if (trimmedTopic.isEmpty) {
      return const KbResearchOutcome(error: '请先填写要搜集的主题');
    }

    // —— 额度防护（与 KbIngestTask 同语义：日上限 ≤ 已用即拦截并留痕）
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
        return const KbResearchOutcome(
          blocked: true,
          error: '今日 token 额度已用尽，可在设置中调整限额',
        );
      }
    }

    // —— 解析 DeepSeek 厂商与模型（搜索/抓取仅 DeepSeek 提供）
    final picked = await _pickDeepSeek();
    if (picked == null) {
      return const KbResearchOutcome(
        error: 'AI 搜集需要 DeepSeek 厂商：请到设置添加 DeepSeek API Key 并拉取模型',
      );
    }
    final apiKey = await _secureKeys.read(picked.$1.keyRef!);
    if (apiKey == null || apiKey.isEmpty) {
      return KbResearchOutcome(
        error: '未找到厂商「${picked.$1.name}」的 API Key，请到设置中重新保存',
      );
    }

    var maxTokens = intensity.maxTokens;
    final singleMax = int.tryParse(
      settings[AppSettingKeys.singleTaskMaxTokens] ?? '',
    );
    if (singleMax != null &&
        singleMax > 0 &&
        (maxTokens == null || maxTokens > singleMax)) {
      maxTokens = singleMax;
    }
    final provider = ProviderConfig(
      name: picked.$1.name,
      baseUrl: picked.$1.baseUrl,
      apiKey: apiKey,
    );
    final model = picked.$2.modelId;

    // —— 阶段 1：生成检索词
    onStage?.call('生成检索词…');
    var inputTokens = 0;
    var outputTokens = 0;
    List<String> queries;
    final watch = Stopwatch()..start();
    try {
      final completion = await _client.chat(
        provider: provider,
        model: model,
        messages: [
          const ChatMessage.system(_querySystemPrompt),
          ChatMessage.user(trimmedTopic),
        ],
        temperature: 0.4,
        maxTokens: 512,
      );
      inputTokens += completion.usage.inputTokens;
      outputTokens += completion.usage.outputTokens;
      queries = _parseQueries(completion.content, trimmedTopic);
      await _logUsage(
        providerName: picked.$1.name,
        model: model,
        presetCode: intensity.code,
        inputTokens: completion.usage.inputTokens,
        outputTokens: completion.usage.outputTokens,
        durationMs: watch.elapsedMilliseconds,
        status: UsageStatus.ok,
      );
    } catch (e) {
      await _logUsage(
        providerName: picked.$1.name,
        model: model,
        presetCode: intensity.code,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        durationMs: watch.elapsedMilliseconds,
        status: UsageStatus.error,
        error: '检索词生成失败：$e',
      );
      return KbResearchOutcome(error: '检索词生成失败：$e');
    }

    // —— 阶段 2：联网搜索（逐条，失败按空结果处理并计数）
    final collected = <DeepSeekSearchItem>[];
    final seenUrls = <String>{};
    var searchFailures = 0;
    for (final query in queries) {
      onStage?.call('搜索：$query');
      try {
        final results = await tools.search(
          apiKey: apiKey,
          query: query,
          count: 8,
          needContent: true,
        );
        for (final item in results) {
          final url = item.url.trim();
          if (url.isNotEmpty && !seenUrls.add(url)) continue;
          if (item.bestText.isEmpty) continue;
          collected.add(item);
          if (collected.length >= _maxItems) break;
        }
      } on DeepSeekToolsException {
        searchFailures += 1;
      }
      if (collected.length >= _maxItems) break;
    }
    if (collected.isEmpty) {
      return KbResearchOutcome(
        queries: queries,
        error: searchFailures == queries.length
            ? '搜索全部失败：请检查 DeepSeek API Key 是否具备 Search 权限或网络是否可达'
            : '没有搜索到可用资料，请换个主题措辞再试',
      );
    }

    // —— 阶段 3：抓取正文（可选，仅抓前几条含 URL 的条目）
    final fetched = <({String title, String url, String content})>[];
    if (fetchPages) {
      for (final item in collected.where((i) => i.url.trim().isNotEmpty).take(
        _maxFetchPages,
      )) {
        onStage?.call('抓取正文：${item.siteName.isEmpty ? item.url : item.siteName}');
        try {
          final page = await tools.fetch(apiKey: apiKey, url: item.url);
          if (page.content.trim().isNotEmpty) {
            fetched.add((
              title: page.title.isEmpty ? item.title : page.title,
              url: item.url,
              content: page.content,
            ));
          }
        } on DeepSeekToolsException {
          // 单页失败不影响整体（摘要/正文已兜底）。
        }
      }
    }

    // —— 阶段 4：汇总素材并交给 KbIngestTask 结构化
    onStage?.call('结构化整理（${collected.length} 条资料）…');
    final material = _buildMaterial(trimmedTopic, collected, fetched);
    final outcome = await ingest.run(rawText: material, intensity: intensity);
    return KbResearchOutcome(
      ingest: outcome,
      error: outcome.error,
      blocked: outcome.blocked,
      queries: queries,
      items: collected,
      fetchedPages: fetched.length,
      inputTokens: inputTokens + outcome.inputTokens,
      outputTokens: outputTokens + outcome.outputTokens,
    );
  }

  /// 挑选 DeepSeek 厂商：baseUrl 含 api.deepseek.com、已存 Key、有启用模型。
  /// 模型优先非 embedding 标签。
  Future<(ProviderRow, ModelRow)?> _pickDeepSeek() async {
    for (final provider in await _db.providersDao.getAll()) {
      if (!provider.baseUrl.contains('api.deepseek.com')) continue;
      final keyRef = provider.keyRef;
      if (keyRef == null || keyRef.isEmpty) continue;
      final models = await _db.modelsDao.activeByProvider(provider.id);
      final usable = [
        for (final model in models)
          if (!_tagsOf(model.tags).contains('embedding')) model,
      ];
      if (usable.isNotEmpty) return (provider, usable.first);
    }
    return null;
  }

  List<String> _tagsOf(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return [for (final tag in decoded) '$tag'];
    } catch (_) {
      // tags 损坏按空处理。
    }
    return const [];
  }

  List<String> _parseQueries(String raw, String fallback) {
    var text = raw.trim();
    final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
    if (fenced != null) text = fenced.group(1)!.trim();
    try {
      final decoded = jsonDecode(text);
      Object? list = decoded is Map ? decoded['queries'] : decoded;
      if (list is List) {
        final queries = <String>[];
        for (final entry in list) {
          final query = entry is Map ? '${entry['query'] ?? ''}' : '$entry';
          final trimmed = query.trim();
          if (trimmed.isNotEmpty && !queries.contains(trimmed)) {
            queries.add(trimmed);
          }
          if (queries.length >= 5) break;
        }
        if (queries.isNotEmpty) return queries;
      }
    } catch (_) {
      // 解析失败走兜底：直接用主题检索。
    }
    return [fallback];
  }

  String _buildMaterial(
    String topic,
    List<DeepSeekSearchItem> items,
    List<({String title, String url, String content})> fetched,
  ) {
    final buffer = StringBuffer()
      ..writeln('以下是从互联网收集的创作资料（主题：$topic）。')
      ..writeln('整理时请保留每条的来源 URL，写入对应条目正文的「来源」部分。')
      ..writeln();
    for (final item in items) {
      if (buffer.length >= _materialCap) break;
      buffer
        ..writeln('## ${item.title.isEmpty ? '（无标题）' : item.title}')
        ..writeln('来源: ${item.url}');
      if (item.siteName.isNotEmpty || item.date.isNotEmpty) {
        buffer.writeln(
          [
            if (item.siteName.isNotEmpty) '站点: ${item.siteName}',
            if (item.date.isNotEmpty) '日期: ${item.date}',
          ].join(' · '),
        );
      }
      final text = item.bestText;
      buffer.writeln(_truncate(text, _itemTextCap));
      buffer.writeln();
    }
    for (final page in fetched) {
      if (buffer.length >= _materialCap) break;
      buffer
        ..writeln('## [网页正文] ${page.title.isEmpty ? '（无标题）' : page.title}')
        ..writeln('来源: ${page.url}')
        ..writeln(_truncate(page.content, _fetchTextCap))
        ..writeln();
    }
    final material = buffer.toString();
    return material.length > _materialCap
        ? material.substring(0, _materialCap)
        : material;
  }

  String _truncate(String text, int cap) {
    final trimmed = text.trim();
    return trimmed.length <= cap ? trimmed : '${trimmed.substring(0, cap)}…';
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

  /// 检索词生成提示词（只输出 JSON，解析失败时回退主题原文检索）。
  static const String _querySystemPrompt =
      '你是资料检索助手。针对用户给出的创作主题，生成 3-5 条适合中文互联网搜索引擎的检索式，'
      '覆盖不同角度（定义/细节/案例/争议）。只输出 JSON，不要输出其他文字，格式：'
      '{"queries":["检索式1","检索式2","检索式3"]}';
}
