// 模型目录：/models 拉取 + 启发式标签（docs/00 D4 / docs/02 A3）+ 用途推荐 + 入库。
import 'dart:convert';

import '../db/database.dart';
import 'llm_client.dart';
import 'providers.dart';

/// 模型标签取值（models.tags JSON 数组元素，docs/01）。
abstract final class ModelTags {
  static const general = 'general';
  static const reasoning = 'reasoning';
  static const longContext = 'long_context';
  static const embedding = 'embedding';
}

/// 常见模型上下文长度表（token）：最长前缀优先；查不到返回 null（无 long_context
/// 判据）。数值为厂商公开文档的参考值，标签可手动修正（docs/00 D4）。
abstract final class ModelContextTable {
  static const _entries = <(String, int)>[
    ('deepseek-reasoner', 65536),
    ('deepseek-chat', 65536),
    ('qwen-turbo', 1000000),
    ('qwen-plus', 131072),
    ('qwen-max', 32768),
    ('qwen-long', 10000000),
    ('doubao-pro-256k', 262144),
    ('doubao-pro-128k', 131072),
    ('doubao-pro-32k', 32768),
    ('doubao-lite-256k', 262144),
    ('doubao-lite-128k', 131072),
    ('doubao-lite-32k', 32768),
    ('glm-4-long', 1048576),
    ('glm-4-plus', 131072),
    ('glm-4-flash', 131072),
    ('glm-4-air', 131072),
    ('glm-4', 131072),
  ];

  static const longContextThreshold = 65536;

  static int? lookup(String modelId) {
    (String, int)? best;
    var bestLen = -1;
    for (final entry in _entries) {
      if (modelId.startsWith(entry.$1) && entry.$1.length > bestLen) {
        best = entry;
        bestLen = entry.$1.length;
      }
    }
    return best?.$2;
  }
}

/// 启发式标签规则（docs/02 A3）：modelId 含 reasoner|r1|thinking|o1|o3 →
/// reasoning；含 embed → embedding；上下文 ≥64k 追加 long_context；默认 general。
/// UI 需注明「自动识别，可手动修正」。
abstract final class ModelTagger {
  static final RegExp _reasoning = RegExp(
    r'reasoner|r1|thinking|o1|o3',
    caseSensitive: false,
  );
  static final RegExp _embedding = RegExp(r'embed', caseSensitive: false);

  static List<String> tag(String modelId) {
    if (_embedding.hasMatch(modelId)) return const [ModelTags.embedding];
    return [
      if (_reasoning.hasMatch(modelId))
        ModelTags.reasoning
      else
        ModelTags.general,
      if (isLongContext(modelId)) ModelTags.longContext,
    ];
  }

  static bool isLongContext(String modelId) {
    final ctx = ModelContextTable.lookup(modelId);
    return ctx != null && ctx >= ModelContextTable.longContextThreshold;
  }
}

/// 用途推荐（docs/02 A3）：结构化入库/深度任务 → reasoning 优先；
/// 日常优化 → general；向量化设置 → 仅 embedding。
enum ModelPurpose { structured, deep, daily, embedding }

abstract final class ModelRecommender {
  /// 按用途从候选中挑默认模型；无匹配时 null（调用方提示去拉取模型）。
  /// firstOrNull 来自 dart:core 的 IterableExtensions（SDK ≥3.0）。
  static ModelInfo? pick(List<ModelInfo> models, ModelPurpose purpose) {
    switch (purpose) {
      case ModelPurpose.embedding:
        return models
            .where((m) => m.tags.contains(ModelTags.embedding))
            .firstOrNull;
      case ModelPurpose.structured:
      case ModelPurpose.deep:
        return models
                .where((m) => m.tags.contains(ModelTags.reasoning))
                .firstOrNull ??
            models.where((m) => m.tags.contains(ModelTags.general)).firstOrNull;
      case ModelPurpose.daily:
        return models
                .where((m) => m.tags.contains(ModelTags.general))
                .firstOrNull ??
            models
                .where((m) => m.tags.contains(ModelTags.reasoning))
                .firstOrNull;
    }
  }
}

/// models 表行 → ModelInfo（tags JSON 解析失败按无标签处理）。
ModelInfo modelInfoFromRow(ModelRow row) {
  var tags = const <String>[];
  try {
    final decoded = jsonDecode(row.tags);
    if (decoded is List) {
      tags = [
        for (final t in decoded)
          if (t is String) t,
      ];
    }
  } on FormatException {
    tags = const [];
  }
  return ModelInfo(id: row.modelId, tags: tags);
}

/// 模型目录服务：拉取 /models → 启发式标签 → 入库（保留用户手动改过的标签）。
class ModelCatalog {
  ModelCatalog(this._client, this._db);

  final LlmClient _client;
  final AppDatabase _db;

  /// 拉取模型并入库。已有模型只更新名称（保留 tags/isActive）；
  /// tags 仍为空（'[]'，含历史拉取未标注的）时写启发式标签。
  /// 返回本次入库的模型（带启发式标签）。
  Future<List<ModelInfo>> refresh({
    required ProviderConfig provider,
    required int providerId,
  }) async {
    final fetched = await _client.listModels(provider);
    final result = <ModelInfo>[];
    for (final info in fetched) {
      final tags = ModelTagger.tag(info.id);
      await _db.modelsDao.upsertModelId(
        providerId: providerId,
        modelId: info.id,
        displayName: info.id,
      );
      final row = await _db.modelsDao.byProviderAndModelId(providerId, info.id);
      if (row != null && (row.tags.isEmpty || row.tags == '[]')) {
        await _db.modelsDao.updateTags(row.id, jsonEncode(tags));
      }
      result.add(ModelInfo(id: info.id, tags: tags));
    }
    return result;
  }

  /// 某厂商已入库模型（带已存标签，含用户手动修正）。
  Future<List<ModelInfo>> storedModels(int providerId) async => [
    for (final row in await _db.modelsDao.byProvider(providerId))
      modelInfoFromRow(row),
  ];

  /// 手动改标签（docs/02 A3：isActive 保持、tags 覆盖）。
  Future<void> setTags(int modelRowId, List<String> tags) =>
      _db.modelsDao.updateTags(modelRowId, jsonEncode(tags));
}
