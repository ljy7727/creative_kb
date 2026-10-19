// 模型启发式标签（A3 规则）、上下文表、用途推荐与拉取入库（docs/00 D4 / docs/02 A2-A3）。
import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/core/llm/llm_client.dart';
import 'package:creative_kb/core/llm/model_catalog.dart';
import 'package:creative_kb/core/llm/providers.dart';
import 'package:flutter_test/flutter_test.dart';

class _StaticClient implements LlmClient {
  _StaticClient(this.modelIds);

  final List<String> modelIds;

  @override
  Future<List<ModelInfo>> listModels(ProviderConfig provider) async => [
    for (final id in modelIds) ModelInfo(id: id),
  ];

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
  }) async => const ChatResult(
    content: '',
    usage: UsageInfo(inputTokens: 0, outputTokens: 0),
  );

  @override
  Future<List<List<double>>> embed({
    required ProviderConfig provider,
    required String model,
    required List<String> texts,
  }) async => [];
}

void main() {
  group('ModelTagger 启发式标签（A3）', () {
    test('reasoner/r1/thinking/o1/o3 → reasoning；默认 general', () {
      expect(ModelTagger.tag('deepseek-reasoner').first, 'reasoning');
      expect(ModelTagger.tag('deepseek-r1').first, 'reasoning');
      expect(ModelTagger.tag('qwen3-thinking').first, 'reasoning');
      expect(ModelTagger.tag('o1-mini').first, 'reasoning');
      expect(ModelTagger.tag('qwen-o3').first, 'reasoning');
      expect(ModelTagger.tag('deepseek-chat').first, 'general');
      expect(ModelTagger.tag('GLM-4-Flash').first, 'general');
    });

    test('含 embed → embedding（不再叠加其他标签）', () {
      expect(ModelTagger.tag('text-embedding-v3'), ['embedding']);
      expect(ModelTagger.tag('embedding-3'), ['embedding']);
    });

    test('上下文 ≥64k 追加 long_context；查表缺省不加', () {
      expect(ModelTagger.tag('deepseek-chat'), ['general', 'long_context']);
      expect(ModelTagger.tag('deepseek-reasoner'), [
        'reasoning',
        'long_context',
      ]);
      expect(ModelTagger.tag('doubao-pro-32k'), ['general']);
      expect(ModelTagger.tag('qwen-max'), ['general']);
      expect(ModelTagger.tag('qwen-turbo'), ['general', 'long_context']);
    });

    test('上下文表最长前缀优先', () {
      expect(ModelContextTable.lookup('doubao-pro-128k'), 131072);
      expect(ModelContextTable.lookup('glm-4-long'), 1048576);
      expect(ModelContextTable.lookup('glm-4-plus'), 131072);
      expect(ModelContextTable.lookup('unknown-model'), isNull);
    });
  });

  group('ModelRecommender 用途推荐（A3）', () {
    final models = [
      const ModelInfo(id: 'a-embed', tags: ['embedding']),
      const ModelInfo(id: 'b-general', tags: ['general', 'long_context']),
      const ModelInfo(id: 'c-reasoning', tags: ['reasoning', 'long_context']),
    ];

    test('结构化/深度任务 → reasoning 优先，缺 reasoning 回落 general', () {
      expect(
        ModelRecommender.pick(models, ModelPurpose.structured)!.id,
        'c-reasoning',
      );
      expect(
        ModelRecommender.pick(models, ModelPurpose.deep)!.id,
        'c-reasoning',
      );
      final noReasoning = [models[0], models[1]];
      expect(
        ModelRecommender.pick(noReasoning, ModelPurpose.deep)!.id,
        'b-general',
      );
    });

    test('日常优化 → general 优先；向量化 → 仅 embedding；无匹配 → null', () {
      expect(
        ModelRecommender.pick(models, ModelPurpose.daily)!.id,
        'b-general',
      );
      expect(
        ModelRecommender.pick(models, ModelPurpose.embedding)!.id,
        'a-embed',
      );
      expect(
        ModelRecommender.pick([models[0]], ModelPurpose.structured),
        isNull,
      );
      expect(
        ModelRecommender.pick([models[1]], ModelPurpose.embedding),
        isNull,
      );
    });
  });

  group('ModelCatalog 拉取入库', () {
    late AppDatabase db;
    late int providerId;

    setUp(() async {
      db = AppDatabase.inMemory();
      providerId = await db.providersDao.add(
        ProvidersCompanion.insert(
          name: 'DeepSeek',
          baseUrl: 'https://api.deepseek.com/v1',
          presetCode: 'deepseek',
        ),
      );
    });

    tearDown(() async => db.close());

    test('拉取模型入库并写启发式标签', () async {
      final catalog = ModelCatalog(
        _StaticClient(['deepseek-chat', 'deepseek-reasoner']),
        db,
      );
      final result = await catalog.refresh(
        provider: const ProviderConfig(
          name: 'DeepSeek',
          baseUrl: 'https://api.deepseek.com/v1',
          apiKey: 'k',
        ),
        providerId: providerId,
      );
      expect(
        result.map((m) => m.id),
        unorderedEquals(['deepseek-chat', 'deepseek-reasoner']),
      );
      final rows = await db.modelsDao.byProvider(providerId);
      expect(rows, hasLength(2));
      final chatRow = rows.singleWhere((r) => r.modelId == 'deepseek-chat');
      expect(chatRow.tags, contains('general'));
      expect(chatRow.tags, contains('long_context'));
      final reasonerRow = rows.singleWhere(
        (r) => r.modelId == 'deepseek-reasoner',
      );
      expect(reasonerRow.tags, contains('reasoning'));
    });

    test('重复拉取保留用户手动改过的 tags；新模型走启发式', () async {
      final catalog = ModelCatalog(_StaticClient(['deepseek-chat']), db);
      const provider = ProviderConfig(
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com/v1',
        apiKey: 'k',
      );
      await catalog.refresh(provider: provider, providerId: providerId);

      // 用户手动改标签（docs/02 A3：tags 覆盖）。
      final row = (await db.modelsDao.byProvider(providerId)).single;
      await catalog.setTags(row.id, ['reasoning']);

      // 第二次拉取带一个新模型：旧模型标签不动，新模型打启发式标签。
      final catalog2 = ModelCatalog(
        _StaticClient(['deepseek-chat', 'text-embedding-v3']),
        db,
      );
      await catalog2.refresh(provider: provider, providerId: providerId);
      final rows = await db.modelsDao.byProvider(providerId);
      expect(rows, hasLength(2));
      expect(
        rows.singleWhere((r) => r.modelId == 'deepseek-chat').tags,
        contains('reasoning'),
      );
      expect(
        rows.singleWhere((r) => r.modelId == 'text-embedding-v3').tags,
        contains('embedding'),
      );
    });

    test('modelInfoFromRow：tags JSON 非法时按无标签处理', () async {
      await db.modelsDao.upsertModelId(
        providerId: providerId,
        modelId: 'm1',
        displayName: 'm1',
      );
      final row = (await db.modelsDao.byProvider(providerId)).single;
      await db.modelsDao.updateTags(row.id, '不是 JSON');
      final info = modelInfoFromRow(
        (await db.modelsDao.byProvider(providerId)).single,
      );
      expect(info.id, 'm1');
      expect(info.tags, isEmpty);
    });
  });
}
