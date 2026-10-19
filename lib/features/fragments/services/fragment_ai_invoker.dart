// 灵感优化 AI 调用缝 + 生产绑定（core/llm StructuredOutput，docs/01 第五节）。
// FragmentAiInvoker 是本模块与 LLM 层的唯一边界：测试注入脚本化假实现，
// 生产默认实现 StructuredOutputInvoker 走 StructuredOutput.request（围栏剥离、
// Schema 校验、失败重试 ≤2 均由其内部完成）。
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/llm/intensity.dart';
import '../../../core/llm/llm_client.dart';
import '../../../core/llm/providers.dart';
import '../../../core/llm/structured_output.dart';
import '../../../core/storage/secure_keys.dart';
import '../models/fragment_models.dart';

/// 一次灵感优化 AI 调用的输入。
class FragmentAiRequest {
  const FragmentAiRequest({
    required this.systemPrompt,
    required this.userPrompt,
    required this.providerName,
    required this.baseUrl,
    required this.keyRef,
    required this.modelId,
    required this.params,
  });

  final String systemPrompt;
  final String userPrompt;

  /// 目标厂商信息：实现方据此组装 chat 请求（Key 按 keyRef 从安全存储读取）。
  final String providerName;
  final String baseUrl;
  final String keyRef;
  final String modelId;

  /// 强度参数：temperature/maxTokens/extra（docs/02 A4）。
  final OptimizeParams params;
}

/// AI 调用回复：模型原始输出（应仅含 JSON）+ usage。
class FragmentAiReply {
  const FragmentAiReply({
    required this.content,
    this.inputTokens = 0,
    this.outputTokens = 0,
  });

  final String content;
  final int inputTokens;
  final int outputTokens;
}

abstract interface class FragmentAiInvoker {
  Future<FragmentAiReply> invoke(FragmentAiRequest request);
}

/// 供「AI 是否可用」提示用的统一文案（docs/00 验收2、docs/01 第四节）。
const aiNotConfiguredMessage = '请先在设置中配置 API Key 并启用模型';

/// docs/02 B2 输出契约对应的 Schema（与 parseOptimizeOutput 同一约定）。
const fragmentContractSchema = StructSchema.object(
  properties: {
    'items': StructSchema.array(
      items: StructSchema.object(
        properties: {
          'title': StructSchema.string(),
          'content': StructSchema.string(),
          'tags': StructSchema.array(items: StructSchema.string()),
          'context': StructSchema.string(),
        },
        required: {'title', 'content'},
      ),
    ),
  },
  required: {'items'},
);

/// 生产实现：core/llm StructuredOutput（T2）+ SecureKeys 读 Key（docs/00 D2）。
class StructuredOutputInvoker implements FragmentAiInvoker {
  StructuredOutputInvoker({LlmClient? client, SecureKeys? secureKeys})
    : _client = client ?? OpenAiCompatLlmClient(),
      _secureKeys = secureKeys ?? SecureKeys();

  final LlmClient _client;
  final SecureKeys _secureKeys;

  @override
  Future<FragmentAiReply> invoke(FragmentAiRequest request) async {
    final apiKey = await _secureKeys.read(request.keyRef);
    if (apiKey == null || apiKey.isEmpty) {
      throw FragmentOptimizeException(
        '未找到厂商「${request.providerName}」的 API Key，请到设置中重新保存',
      );
    }

    final structured = StructuredOutput(client: _client);
    final result = await structured.request<Map<String, dynamic>>(
      provider: ProviderConfig(
        name: request.providerName,
        baseUrl: request.baseUrl,
        apiKey: apiKey,
      ),
      model: request.modelId,
      messages: [
        ChatMessage.system(request.systemPrompt),
        ChatMessage.user(request.userPrompt),
      ],
      schema: fragmentContractSchema,
      decode: (json) => json,
      intensity: IntensityParams(
        temperature: request.params.temperature,
        maxTokens: request.params.maxTokens,
        extra: request.params.extra,
      ),
    );

    return switch (result) {
      StructuredSuccess(:final rawText, :final usage) => FragmentAiReply(
        content: rawText,
        inputTokens: usage.inputTokens,
        outputTokens: usage.outputTokens,
      ),
      StructuredFailure(:final violations) =>
        // StructuredOutput 内部已按 ≤2 次重试仍失败；转业务异常，
        // 不再触发任务层重试（避免双重重试放大调用量）。
        throw FragmentOptimizeException(
          'AI 输出不符合约定格式：${violations.map((v) => '${v.path}：${v.message}').join('；')}',
        ),
    };
  }
}

/// 生产默认实现；测试以脚本化假实现 override。
final fragmentAiInvokerProvider = Provider<FragmentAiInvoker>(
  (ref) => StructuredOutputInvoker(),
);

/// 选取用于优化的厂商与模型：取第一个配置了 Key 且有启用模型的厂商。
/// 无可用模型返回 null（由调用方决定提示文案）。
Future<({ProviderRow provider, ModelRow model})?> pickOptimizeModel(
  AppDatabase db,
) async {
  final providers = await db.providersDao.getAll();
  for (final provider in providers) {
    if (provider.keyRef == null || provider.keyRef!.isEmpty) continue;
    final models = await db.modelsDao.activeByProvider(provider.id);
    if (models.isNotEmpty) return (provider: provider, model: models.first);
  }
  return null;
}

/// AI 就绪状态摘要（录入页/详情页置灰与提示用）。
class OptimizeAiContext {
  const OptimizeAiContext({required this.providerName, required this.modelId});

  final String providerName;
  final String modelId;
}

/// 未就绪（未配置可用模型）时以 null 值结束而非抛错——抛 StateError 会触发
/// riverpod 自动重试；数据库未注入（冒烟壳层）时以 AsyncError 结束。
final optimizeAiContextProvider = FutureProvider<OptimizeAiContext?>((
  ref,
) async {
  final db = ref.watch(appDatabaseProvider);
  final pick = await pickOptimizeModel(db);
  if (pick == null) return null;
  return OptimizeAiContext(
    providerName: pick.provider.name,
    modelId: pick.model.modelId,
  );
});
