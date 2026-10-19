/// 厂商预设与运行时配置（docs/02 A2）。
/// presetCode 取值与 providers 表约定一致：deepseek|qwen|doubao|zhipu|custom。
/// API Key 不入库：数据库只存 keyRef 引用名（buildKeyRef），密文在 secure storage。
library;

/// 生成 secure storage 的 key 引用名，形如 key_deepseek_main（docs/00 D2）。
/// providerName 归一为 [a-z0-9_] 片段；全为非 ASCII（如中文）时回落 main。
String buildKeyRef({required String presetCode, required String providerName}) {
  final slug = _slug(providerName);
  return 'key_${presetCode}_${slug.isEmpty ? 'main' : slug}';
}

String _slug(String input) {
  final s = input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return s.replaceAll(RegExp(r'^_+|_+$'), '');
}

/// LlmClient 的运行时连接配置：apiKey 已由上层从 SecureKeys 解出后注入。
class ProviderConfig {
  const ProviderConfig({
    required this.name,
    required this.baseUrl,
    required this.apiKey,
  });

  final String name;

  /// OpenAI 兼容根路径，形如 https://api.deepseek.com/v1（不含尾斜杠）。
  final String baseUrl;
  final String apiKey;
}

/// 内置厂商预设（docs/02 A2，baseUrl 见 docs/01 第三节）。
enum ProviderPreset {
  deepseek('DeepSeek', 'https://api.deepseek.com/v1'),
  qwen('通义千问', 'https://dashscope.aliyuncs.com/compatible-mode/v1'),
  doubao('豆包', 'https://ark.cn-beijing.volces.com/api/v3'),
  zhipu('智谱', 'https://open.bigmodel.cn/api/paas/v4'),
  custom('自定义', '');

  const ProviderPreset(this.displayName, this.baseUrl);

  final String displayName;

  /// custom 档 baseUrl 为空串，由用户在设置页填写。
  final String baseUrl;

  static ProviderPreset byCode(String code) {
    for (final p in ProviderPreset.values) {
      if (p.name == code) return p;
    }
    return ProviderPreset.custom;
  }
}
