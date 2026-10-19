/// 内置价格常量表（docs/02 A5）：模型名前缀 → 每百万 token 单价（元）。
/// 参考值，不用于精确对账（docs/00 D5）；未命中的模型只记账、不估价（返回 null）。
/// 记录 (前缀, 每百万输入单价, 每百万输出单价)，匹配按“最长前缀优先”。
abstract final class PriceTable {
  static const _entries = <(String, double, double)>[
    ('deepseek-reasoner', 4.0, 16.0),
    ('deepseek-chat', 2.0, 8.0),
    ('qwen-turbo', 0.3, 0.6),
    ('qwen-plus', 0.8, 2.0),
    ('qwen-max', 2.4, 9.6),
    ('qwen-long', 0.5, 2.0),
    ('text-embedding-v4', 0.7, 0.0),
    ('text-embedding-v3', 0.7, 0.0),
    ('doubao-pro-128k', 5.0, 9.0),
    ('doubao-pro-256k', 5.0, 9.0),
    ('doubao-pro', 0.8, 2.0),
    ('doubao-lite', 0.3, 0.6),
    ('glm-4-plus', 50.0, 50.0),
    ('glm-4-flash', 0.0, 0.0),
    ('glm-4-air', 1.0, 1.0),
    ('glm-4-long', 1.0, 1.0),
    ('glm-4', 100.0, 100.0),
    ('embedding-3', 0.5, 0.0),
    ('embedding-2', 0.2, 0.0),
  ];

  /// 最长前缀匹配；未命中返回 null。
  static (double, double)? match(String modelId) {
    (double, double)? best;
    var bestLen = -1;
    for (final (prefix, input, output) in _entries) {
      if (modelId.startsWith(prefix) && prefix.length > bestLen) {
        best = (input, output);
        bestLen = prefix.length;
      }
    }
    return best;
  }

  /// 估算单次调用费用（元）。查不到价格返回 null（docs/00 D5）。
  static double? estimateCost({
    required String modelId,
    required int inputTokens,
    required int outputTokens,
  }) {
    final price = match(modelId);
    if (price == null) return null;
    final (inputPerMillion, outputPerMillion) = price;
    return inputTokens / 1000000 * inputPerMillion +
        outputTokens / 1000000 * outputPerMillion;
  }
}
