import 'dart:convert';

import '../../../core/db/database.dart';
import '../../../core/llm/llm_client.dart';
import '../../../core/llm/providers.dart';
import '../../../core/storage/secure_keys.dart';
import 'kb_ai_gateway.dart';
import 'kb_embedding_config.dart';

/// 从库内挑选一个可用于结构化任务的模型（docs/02 A3 推荐策略：
/// 结构化/深度任务 reasoning 优先，其次 general，再取第一个）。
/// 仅考虑配置了 Key 且有启用模型的厂商；无可用项返回 null。
Future<({ProviderRow provider, ModelRow model})?> pickKbChatModel(
  AppDatabase db,
) async {
  final candidates = <({ProviderRow provider, ModelRow model})>[];
  for (final provider in await db.providersDao.getAll()) {
    if (provider.keyRef == null || provider.keyRef!.isEmpty) continue;
    for (final model in await db.modelsDao.activeByProvider(provider.id)) {
      candidates.add((provider: provider, model: model));
    }
  }
  if (candidates.isEmpty) return null;
  int rank(ModelRow model) {
    final tags = decodeTags(model.tags);
    if (tags.contains('reasoning')) return 0;
    if (tags.contains('general')) return 1;
    return 2;
  }

  candidates.sort((a, b) => rank(a.model).compareTo(rank(b.model)));
  return candidates.first;
}

/// 任一厂商「有 Key 且有启用模型」即视为 AI 可用（跟随 providers/models 表变化）。
Future<bool> hasUsableChatModel(AppDatabase db) async {
  for (final provider in await db.providersDao.getAll()) {
    if (provider.keyRef == null || provider.keyRef!.isEmpty) continue;
    if ((await db.modelsDao.activeByProvider(provider.id)).isNotEmpty) {
      return true;
    }
  }
  return false;
}

List<String> decodeTags(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) return [for (final tag in decoded) '$tag'];
  } catch (_) {
    // tags 损坏按空处理。
  }
  return const [];
}

/// 生产实现：core/llm 的 OpenAiCompatLlmClient + SecureKeys 读 Key
/// （docs/00 D2：密文不落库，运行时解出后组装 ProviderConfig）。
class LlmClientKbAiGateway implements KbAiGateway {
  LlmClientKbAiGateway(this._db, {LlmClient? client, SecureKeys? secureKeys})
    : _client = client ?? OpenAiCompatLlmClient(),
      _secureKeys = secureKeys ?? SecureKeys();

  final AppDatabase _db;
  final LlmClient _client;
  final SecureKeys _secureKeys;

  @override
  Future<KbAiCompletion> complete({
    required String system,
    required String user,
    double? temperature,
    int? maxTokens,
  }) async {
    final picked = await pickKbChatModel(_db);
    if (picked == null) {
      throw const KbAiNotConfiguredException('未配置可用模型，请先到设置添加厂商并拉取模型');
    }
    final apiKey = await _secureKeys.read(picked.provider.keyRef!);
    if (apiKey == null || apiKey.isEmpty) {
      throw KbAiNotConfiguredException(
        '未找到厂商「${picked.provider.name}」的 API Key，请到设置中重新保存',
      );
    }
    final result = await _client.chat(
      provider: ProviderConfig(
        name: picked.provider.name,
        baseUrl: picked.provider.baseUrl,
        apiKey: apiKey,
      ),
      model: picked.model.modelId,
      messages: [ChatMessage.system(system), ChatMessage.user(user)],
      temperature: temperature,
      maxTokens: maxTokens,
    );
    return KbAiCompletion(
      text: result.content,
      model: picked.model.modelId,
      providerName: picked.provider.name,
      inputTokens: result.usage.inputTokens,
      outputTokens: result.usage.outputTokens,
    );
  }

  @override
  Future<List<double>> embed({
    required String model,
    required String text,
  }) async {
    // 嵌入厂商以 kb.embedding_model 设置为准（模型名一致性由调用方保证）。
    final config = await KbEmbeddingConfigResolver.resolve(_db);
    if (config == null) {
      throw const KbAiNotConfiguredException('未配置嵌入模型，无法向量化');
    }
    final provider = await _db.providersDao.byId(config.providerId);
    if (provider == null || (provider.keyRef ?? '').isEmpty) {
      throw const KbAiNotConfiguredException('嵌入模型厂商不存在或未配置 Key');
    }
    final apiKey = await _secureKeys.read(provider.keyRef!);
    if (apiKey == null || apiKey.isEmpty) {
      throw KbAiNotConfiguredException(
        '未找到厂商「${provider.name}」的 API Key，请到设置中重新保存',
      );
    }
    final vectors = await _client.embed(
      provider: ProviderConfig(
        name: provider.name,
        baseUrl: provider.baseUrl,
        apiKey: apiKey,
      ),
      model: config.model,
      texts: [text],
    );
    if (vectors.isEmpty) {
      throw const KbAiNotConfiguredException('嵌入接口返回为空');
    }
    return vectors.first;
  }
}
