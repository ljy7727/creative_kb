// AI 搜集管线单测：检索词生成 → 搜索（去重/上限）→ 抓取 → 组装素材 → 结构化。
// 全部使用假客户端/假网关，不访问网络。
import 'dart:convert';
import 'dart:io';

import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/core/llm/deepseek_tools.dart';
import 'package:creative_kb/core/llm/llm_client.dart';
import 'package:creative_kb/core/llm/providers.dart';
import 'package:creative_kb/core/seed/app_seeder.dart';
import 'package:creative_kb/core/storage/secure_keys.dart';
import 'package:creative_kb/features/kb/services/kb_ingest_task.dart';
import 'package:creative_kb/features/kb/services/kb_research_service.dart';
import 'package:creative_kb/features/kb/services/schema_registry.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../llm/fake_adapter.dart';
import 'fake_gateway.dart';

/// 内存 KeyStore：避免 flutter_secure_storage 平台通道。
class _MemoryKeyStore implements KeyStore {
  final Map<String, String> values = {};

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

/// 脚本化 LlmClient（仅用于检索词生成）。
class _ScriptedLlmClient implements LlmClient {
  _ScriptedLlmClient(this.responses);

  final List<String> responses;
  int calls = 0;
  ProviderConfig? lastProvider;
  String? lastModel;

  @override
  Future<ChatResult> chat({
    required ProviderConfig provider,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
    Map<String, dynamic>? extra,
    void Function(String delta)? onDelta,
  }) async {
    calls++;
    lastProvider = provider;
    lastModel = model;
    return ChatResult(
      content: responses.removeAt(0),
      usage: const UsageInfo(inputTokens: 30, outputTokens: 20),
    );
  }

  @override
  Future<List<ModelInfo>> listModels(ProviderConfig provider) async => const [];

  @override
  Future<List<List<double>>> embed({
    required ProviderConfig provider,
    required String model,
    required List<String> texts,
  }) async => [for (final _ in texts) const [1.0, 0.0]];
}

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late SchemaRegistry registry;
  late _ScriptedLlmClient llm;
  late _MemoryKeyStore keyStore;
  late FakeKbAiGateway gateway;

  const ingestJson =
      '{"cleaned":"唐朝官服与俸禄资料整理","proposedCategory":"历史/唐朝",'
      '"proposedSchemaId":"general","entries":[{"entryName":"唐朝官服",'
      '"summary":"五品以上服绯","contentMd":"## 官服\\n五品以上穿绯色。\\n来源: '
      'https://example.com/a","tags":["唐朝"],"relatedEntries":[],'
      '"credibility":"mid"}]}';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('creative_kb_research');
    db = AppDatabase.inMemory();
    await AppSeeder(db, appDirResolver: () async => tempDir).run();
    registry = SchemaRegistry(
      Directory('${tempDir.path}${Platform.pathSeparator}schemas'),
    );
    keyStore = _MemoryKeyStore();
    gateway = FakeKbAiGateway(const []);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<IntensityParams> standardIntensity() async {
    final preset = await db.intensityPresetsDao.byCode('standard');
    return IntensityParams.fromPreset(preset!);
  }

  Future<int> seedDeepSeekProvider() async {
    final providerId = await db.providersDao.add(
      ProvidersCompanion.insert(
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com/v1',
        keyRef: const Value('key_deepseek'),
        presetCode: 'deepseek',
      ),
    );
    await db.modelsDao.upsertModelId(
      providerId: providerId,
      modelId: 'deepseek-chat',
      displayName: 'DeepSeek Chat',
    );
    await keyStore.write('key_deepseek', 'sk-test');
    return providerId;
  }

  KbResearchService buildService(DeepSeekToolsClient tools) => KbResearchService(
    db,
    tools: tools,
    ingest: KbIngestTask(
      db,
      gateway: gateway,
      loadSchemas: () => registry.load(),
    ),
    client: llm,
    secureKeys: SecureKeys(store: keyStore),
  );

  test('完整管线：生成检索词 → 搜索去重 → 抓取 → 结构化入库结果', () async {
    await seedDeepSeekProvider();
    llm = _ScriptedLlmClient([
      '{"queries":["唐朝官服","唐朝俸禄"]}',
    ]);
    gateway.enqueue(ingestJson);
    var searchCalls = 0;
    var fetchCalls = 0;
    final adapter = FakeAdapter((options) async {
      if (options.path == '/v1/tools/search') {
        searchCalls++;
        return ResponseBody.fromString(
          jsonEncode({
            'results': [
              {
                'title': '唐朝官服-结果$searchCalls',
                'url': 'https://example.com/a',
                'summary': '五品以上服绯',
                'content': '五品以上穿绯色官服。',
              },
              {
                'title': '唐朝俸禄-结果$searchCalls',
                'url': 'https://example.com/b',
                'summary': '俸禄按品级发放',
                'content': '俸禄米粟按品级发放。',
              },
            ],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      fetchCalls++;
      expect(options.path, '/v1/tools/fetch');
      return ResponseBody.fromString(
        jsonEncode({'title': '全文页', 'content': '完整正文 Markdown'}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final tools = DeepSeekToolsClient(
      dio: Dio()..httpClientAdapter = adapter,
    );
    final service = buildService(tools);
    final outcome = await service.run(
      topic: '唐朝官员服饰与俸禄',
      intensity: await standardIntensity(),
      fetchPages: true, // 全管线验证；默认已改为不抓取（见下方专项测试）。
    );

    // 结构化成功，且素材里带来源 URL。
    expect(outcome.error, isNull);
    expect(outcome.ingest?.result, isNotNull);
    expect(outcome.ingest!.result!.entries.single.entryName, '唐朝官服');
    expect(outcome.queries, ['唐朝官服', '唐朝俸禄']);
    // 两个检索词返回重复 URL：按 URL 去重后共 2 条。
    expect(outcome.items, hasLength(2));
    expect(searchCalls, 2);
    // 抓取正文默认抓前两条（上限 3）。
    expect(fetchCalls, 2);
    expect(outcome.fetchedPages, 2);
    expect(gateway.lastUser, contains('https://example.com/a'));
    expect(gateway.lastUser, contains('完整正文 Markdown'));
    // 素材头部带整理要求：时间顺序组织 + cleaned 要点化 + 来源小节。
    expect(gateway.lastUser, contains('整理要求'));
    expect(gateway.lastUser, contains('按时间顺序'));
    expect(gateway.lastUser, contains('要点汇总'));
    expect(gateway.lastUser, contains('## 来源'));
    // 结构化调用 maxTokens 抬底到 8192（防 JSON 截断）。
    expect(gateway.lastMaxTokens, 8192);

    // 检索词调用计入 kb_research 账目。
    final rows = await db.usageLogDao.recent(limit: 20);
    expect(rows.any((r) => r.taskType == 'kb_research'), isTrue);
    // 结构化调用仍由 ingest 任务记账。
    expect(rows.any((r) => r.taskType == 'kb_ingest'), isTrue);
  });

  test('未配置 DeepSeek：明确提示需要 DeepSeek 厂商', () async {
    llm = _ScriptedLlmClient(const []);
    final tools = DeepSeekToolsClient(
      dio: Dio()
        ..httpClientAdapter = FakeAdapter(
          (options) async => ResponseBody.fromString('{}', 200),
        ),
    );
    final outcome = await buildService(tools).run(
      topic: '任意主题',
      intensity: await standardIntensity(),
    );
    expect(outcome.error, contains('DeepSeek'));
    expect(outcome.ingest, isNull);
  });

  test('默认不抓取正文：搜索摘要已够用，fetch 接口不调用', () async {
    await seedDeepSeekProvider();
    llm = _ScriptedLlmClient(['{"queries":["唐朝官服"]}']);
    gateway.enqueue(ingestJson);
    var fetchCalls = 0;
    final adapter = FakeAdapter((options) async {
      if (options.path == '/v1/tools/search') {
        return ResponseBody.fromString(
          jsonEncode({
            'results': [
              {'title': 'T', 'url': 'https://e.com/x', 'summary': 'S'},
            ],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      fetchCalls++;
      return ResponseBody.fromString(
        jsonEncode({'title': '', 'content': ''}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final tools = DeepSeekToolsClient(dio: Dio()..httpClientAdapter = adapter);
    // 不传 fetchPages：验证默认关闭。
    final outcome = await buildService(tools).run(
      topic: '李白的一生',
      intensity: await standardIntensity(),
    );
    expect(fetchCalls, 0);
    expect(outcome.fetchedPages, 0);
    expect(outcome.ingest?.result, isNotNull);
  });

  test('检索词 JSON 非法：回退为主题原文检索', () async {
    await seedDeepSeekProvider();
    llm = _ScriptedLlmClient(['不是 JSON']);
    gateway.enqueue(ingestJson);
    final queried = <String>[];
    final adapter = FakeAdapter((options) async {
      if (options.path == '/v1/tools/search') {
        queried.add((options.data as Map)['query'] as String);
        return ResponseBody.fromString(
          jsonEncode({
            'results': [
              {'title': 'T', 'url': 'https://e.com/x', 'summary': 'S'},
            ],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      return ResponseBody.fromString(
        jsonEncode({'title': '', 'content': ''}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final tools = DeepSeekToolsClient(
      dio: Dio()..httpClientAdapter = adapter,
    );
    final outcome = await buildService(tools).run(
      topic: '唐朝官服',
      intensity: await standardIntensity(),
      fetchPages: false,
    );
    expect(queried, ['唐朝官服']);
    expect(outcome.ingest?.result, isNotNull);
  });
}
