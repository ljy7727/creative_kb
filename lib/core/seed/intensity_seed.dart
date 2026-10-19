import 'dart:convert';

/// 内置思考强度预设种子（docs/02 A4）。params 的 JSON 序列化后直接入
/// intensity_presets.params，key 命名与 LlmClient 参数对齐（T2 消费）。
abstract final class IntensitySeed {
  static const fast = {'temperature': 0.3, 'maxTokens': 2048};
  static const standard = {'temperature': 0.7, 'maxTokens': 4096};
  static const deep = {
    'temperature': 0.5,
    'maxTokens': 8192,
    // 深度档附加：请求分步思考 + 厂商自适应推理参数（DeepSeek reasoner 由推荐逻辑处理）。
    'extra': {'stepByStep': true, 'vendorReasoning': 'auto'},
  };
  static const custom = {'temperature': 0.7, 'maxTokens': 4096};

  static List<({String code, String name, String paramsJson})> all() => [
        (code: 'fast', name: '极速', paramsJson: jsonEncode(fast)),
        (code: 'standard', name: '标准', paramsJson: jsonEncode(standard)),
        (code: 'deep', name: '深度', paramsJson: jsonEncode(deep)),
        (code: 'custom', name: '自定义', paramsJson: jsonEncode(custom)),
      ];
}
