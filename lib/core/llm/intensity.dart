// 思考强度预设（docs/02 A4）：intensity_presets.params JSON 的类型化封装。
// 预设种子与落盘由 core/seed（T1）负责，本文件只做参数消费：解析 → chat 参数。
import 'dart:convert';

/// 内置预设 code（intensity_presets.code，docs/02 A4）。
abstract final class IntensityCodes {
  static const fast = 'fast';
  static const standard = 'standard';
  static const deep = 'deep';
  static const custom = 'custom';

  static const all = <String>[fast, standard, deep, custom];
}

/// 强度参数。JSON 形如：
/// `{"temperature":0.7,"topP":0.9,"maxTokens":4096,"extra":{...}}`。
class IntensityParams {
  const IntensityParams({
    this.temperature,
    this.topP,
    this.maxTokens,
    this.extra = const {},
  });

  factory IntensityParams.fromJson(Map<String, dynamic> json) =>
      IntensityParams(
        temperature: (json['temperature'] as num?)?.toDouble(),
        topP: (json['topP'] as num?)?.toDouble(),
        maxTokens: (json['maxTokens'] as num?)?.toInt(),
        extra: json['extra'] is Map
            ? Map<String, dynamic>.from(json['extra'] as Map)
            : const {},
      );

  /// 解析 intensity_presets.params；空串/非法 JSON/顶层非对象按默认（不设限）。
  factory IntensityParams.fromJsonString(String paramsJson) {
    if (paramsJson.trim().isEmpty) return const IntensityParams();
    try {
      final decoded = jsonDecode(paramsJson);
      if (decoded is Map<String, dynamic>) {
        return IntensityParams.fromJson(decoded);
      }
    } on FormatException {
      // 非法参数回落默认值，不阻断任务
    }
    return const IntensityParams();
  }

  final double? temperature;
  final double? topP;
  final int? maxTokens;

  /// 附加参数：deep 档的 stepByStep/vendorReasoning 为内部语义键（见
  /// [_internalKeys]）；其余键视为厂商自定义请求体参数，调用时透传。
  final Map<String, dynamic> extra;

  bool get requestsStepByStep => extra['stepByStep'] == true;

  Map<String, dynamic> toJson() => {
    if (temperature != null) 'temperature': temperature,
    if (topP != null) 'topP': topP,
    if (maxTokens != null) 'maxTokens': maxTokens,
    if (extra.isNotEmpty) 'extra': extra,
  };

  String toJsonString() => jsonEncode(toJson());

  /// 映射为 LlmClient.chat 参数。[maxTokensCap] 为「单次上限」设置
  /// （docs/02 A5 封顶），与预设 maxTokens 取较小值。
  ChatParams toChatParams({int? maxTokensCap}) {
    final bodyExtra = <String, dynamic>{
      for (final entry in extra.entries)
        if (!_internalKeys.contains(entry.key)) entry.key: entry.value,
    };
    final presetMax = maxTokens;
    int? effectiveMax;
    if (presetMax != null && maxTokensCap != null) {
      effectiveMax = presetMax < maxTokensCap ? presetMax : maxTokensCap;
    } else {
      effectiveMax = presetMax ?? maxTokensCap;
    }
    return ChatParams(
      temperature: temperature,
      topP: topP,
      maxTokens: effectiveMax,
      extra: bodyExtra.isEmpty ? null : bodyExtra,
    );
  }

  /// 内部语义键：不进请求体。stepByStep 由提示词层表达；vendorReasoning
  /// （auto）仅作展示，DeepSeek reasoner 换模由模型推荐逻辑处理（docs/02 A4）。
  static const _internalKeys = <String>{'stepByStep', 'vendorReasoning'};
}

/// chat() 调用参数包（intensity → LlmClient 的映射结果）。
class ChatParams {
  const ChatParams({this.temperature, this.topP, this.maxTokens, this.extra});

  final double? temperature;
  final double? topP;
  final int? maxTokens;
  final Map<String, dynamic>? extra;
}
