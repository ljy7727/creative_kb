/// 与 Agent 中枢（core/llm）的窄对接面。
/// 生产实现见 kb_ai_gateway_impl.dart 的 [LlmClientKbAiGateway]
/// （OpenAiCompatLlmClient + SecureKeys，与 fragments 模块同模式）；
/// 测试以脚本化假实现 override kbAiGatewayProvider（定义在 kb_providers.dart）。
abstract class KbAiGateway {
  /// 单轮补全：返回模型原始文本输出（入库契约要求其只含 JSON）。
  Future<KbAiCompletion> complete({
    required String system,
    required String user,
    double? temperature,
    int? maxTokens,
  });

  /// 文本向量化（docs/02 A1 embed 语义）。
  Future<List<double>> embed({required String model, required String text});
}

class KbAiCompletion {
  const KbAiCompletion({
    required this.text,
    required this.model,
    this.providerName = '',
    this.inputTokens = 0,
    this.outputTokens = 0,
  });

  final String text;
  final String model;
  final String providerName;
  final int inputTokens;
  final int outputTokens;
}

/// 额度防护拦截（docs/02 A5 / docs/01 第三节）。
class KbQuotaExceededException implements Exception {
  const KbQuotaExceededException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 未配置可用模型/Key 时访问 AI 能力。
class KbAiNotConfiguredException implements Exception {
  const KbAiNotConfiguredException(this.message);

  final String message;

  @override
  String toString() => message;
}
