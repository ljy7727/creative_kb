// 模块B 数据契约：FragmentOptimizeTask 的 JSON 输出解析/校验、aiMeta 与强度参数。
// 纯 Dart，不依赖 Flutter，便于单测（docs/02 B2）。
import 'dart:convert';

/// 灵感优化业务失败（中文 message 可直接展示给用户）。
class FragmentOptimizeException implements Exception {
  const FragmentOptimizeException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 模型输出不符合 JSON 契约时抛出；message 为中文，可拼回提示词重试或直接展示。
class FragmentContractException implements Exception {
  const FragmentContractException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 一条整理后的灵感条目（契约 items[i]）。
class FragmentOptimizeItem {
  const FragmentOptimizeItem({
    required this.title,
    required this.content,
    this.tags = const [],
    this.context,
  });

  final String title;
  final String content;
  final List<String> tags;
  final String? context;

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'tags': tags,
    if (context != null) 'context': context,
  };

  /// 严格校验的解析：字段缺失/类型不符抛 [FragmentContractException]。
  factory FragmentOptimizeItem.fromJson(Object? raw, {required String path}) {
    if (raw is! Map) {
      throw FragmentContractException('$path 必须是 JSON 对象');
    }
    final map = Map<String, dynamic>.from(raw);

    final title = map['title'];
    if (title is! String || title.trim().isEmpty) {
      throw FragmentContractException('$path.title 必须是非空字符串');
    }
    final content = map['content'];
    if (content is! String || content.trim().isEmpty) {
      throw FragmentContractException('$path.content 必须是非空字符串');
    }

    final tagsRaw = map['tags'];
    final tags = <String>[];
    if (tagsRaw != null) {
      if (tagsRaw is! List) {
        throw FragmentContractException('$path.tags 必须是字符串数组');
      }
      for (var i = 0; i < tagsRaw.length; i++) {
        final t = tagsRaw[i];
        if (t is! String) {
          throw FragmentContractException('$path.tags[$i] 必须是字符串');
        }
        tags.add(t);
      }
    }

    final context = map['context'];
    if (context != null && context is! String) {
      throw FragmentContractException('$path.context 必须是字符串');
    }

    return FragmentOptimizeItem(
      title: title.trim(),
      content: content,
      tags: tags,
      context: context as String?,
    );
  }

  /// 宽容解析 fragments.optimizedJson（损坏数据返回 null，不阻断 UI）。
  static FragmentOptimizeItem? tryDecode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return FragmentOptimizeItem.fromJson(
        jsonDecode(raw),
        path: 'optimizedJson',
      );
    } catch (_) {
      return null;
    }
  }
}

/// 剥离 ```json / ``` 围栏；部分模型会附加前后说明文字，截取首个 { 到末个 }。
String stripJsonFences(String raw) {
  var text = raw.trim();
  final fence = RegExp(r'^```[a-zA-Z]*\s*([\s\S]*?)\s*```$');
  final match = fence.firstMatch(text);
  if (match != null) {
    text = match.group(1)!.trim();
  }
  if (!text.startsWith('{')) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      text = text.substring(start, end + 1);
    }
  }
  return text;
}

/// 解析并校验模型输出（docs/01 第五节：结构化输出契约校验，语义同
/// core/llm StructuredOutput，本模块自带以保持可独立运行与测试）。
/// 不符合契约时抛 [FragmentContractException]。
List<FragmentOptimizeItem> parseOptimizeOutput(String raw) {
  Object? decoded;
  try {
    decoded = jsonDecode(stripJsonFences(raw));
  } on FormatException catch (e) {
    throw FragmentContractException('输出不是合法 JSON：${e.message}');
  }
  if (decoded is! Map) {
    throw const FragmentContractException('输出必须是 JSON 对象');
  }
  final map = Map<String, dynamic>.from(decoded);
  final itemsRaw = map['items'];
  if (itemsRaw is! List) {
    throw const FragmentContractException('缺少 items 数组');
  }
  if (itemsRaw.isEmpty) {
    throw const FragmentContractException('items 数组为空');
  }
  return [
    for (var i = 0; i < itemsRaw.length; i++)
      FragmentOptimizeItem.fromJson(itemsRaw[i], path: 'items[$i]'),
  ];
}

/// fragments.aiMeta 的 JSON 结构。
/// 约定 key：provider/model/preset/inputTokens/outputTokens/ts，
/// 派生拆分行附加 originId（指向原始 fragmentId），失败记录 error。
class FragmentAiMeta {
  const FragmentAiMeta({
    required this.providerName,
    required this.model,
    required this.presetCode,
    this.inputTokens = 0,
    this.outputTokens = 0,
    required this.ts,
    this.originId,
    this.retries = 0,
    this.error,
  });

  final String providerName;
  final String model;
  final String presetCode;
  final int inputTokens;
  final int outputTokens;
  final DateTime ts;

  /// 拆分派生行指向的原始 fragmentId；原始行为 null。
  final int? originId;
  final int retries;
  final String? error;

  Map<String, dynamic> toJson() => {
    'provider': providerName,
    'model': model,
    'preset': presetCode,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'ts': ts.toIso8601String(),
    if (originId != null) 'originId': originId,
    if (retries > 0) 'retries': retries,
    if (error != null) 'error': error,
  };

  String encode() => jsonEncode(toJson());

  /// 宽容解析：不合法返回 null（历史/损坏数据不阻断 UI）。
  static FragmentAiMeta? tryDecode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      return FragmentAiMeta(
        providerName: map['provider'] is String
            ? map['provider'] as String
            : '',
        model: map['model'] is String ? map['model'] as String : '',
        presetCode: map['preset'] is String ? map['preset'] as String : '',
        inputTokens: (map['inputTokens'] as num?)?.toInt() ?? 0,
        outputTokens: (map['outputTokens'] as num?)?.toInt() ?? 0,
        ts: DateTime.tryParse(map['ts'] as String? ?? '') ?? DateTime.now(),
        originId: (map['originId'] as num?)?.toInt(),
        retries: (map['retries'] as num?)?.toInt() ?? 0,
        error: map['error'] is String ? map['error'] as String : null,
      );
    } catch (_) {
      return null;
    }
  }
}

/// 强度预设参数（intensity_presets.params 的 key 与 LlmClient 对齐，docs/02 A4）。
class OptimizeParams {
  const OptimizeParams({
    this.temperature,
    this.maxTokens,
    this.extra = const {},
  });

  final double? temperature;
  final int? maxTokens;
  final Map<String, dynamic> extra;

  static OptimizeParams fromPresetJson(String paramsJson) {
    if (paramsJson.trim().isEmpty) return const OptimizeParams();
    try {
      final decoded = jsonDecode(paramsJson);
      if (decoded is! Map) return const OptimizeParams();
      final map = Map<String, dynamic>.from(decoded);
      return OptimizeParams(
        temperature: (map['temperature'] as num?)?.toDouble(),
        maxTokens: (map['maxTokens'] as num?)?.toInt(),
        extra: map['extra'] is Map
            ? Map<String, dynamic>.from(map['extra'] as Map)
            : const {},
      );
    } catch (_) {
      return const OptimizeParams();
    }
  }

  /// 单次额度上限以 max_tokens 封顶（docs/02 A5）。
  OptimizeParams cappedMaxTokens(int cap) {
    if (cap <= 0 || maxTokens == null || maxTokens! <= cap) return this;
    return OptimizeParams(
      temperature: temperature,
      maxTokens: cap,
      extra: extra,
    );
  }
}

/// 解析 fragments.tags（JSON 数组字符串）；损坏数据返回空列表。
List<String> decodeTags(String tagsJson) {
  try {
    final decoded = jsonDecode(tagsJson);
    if (decoded is! List) return const [];
    return [
      for (final t in decoded)
        if (t is String && t.trim().isNotEmpty) t,
    ];
  } catch (_) {
    return const [];
  }
}

String encodeTags(List<String> tags) => jsonEncode([
  for (final t in tags)
    if (t.trim().isNotEmpty) t.trim(),
]);

/// 合并用户手输标签与 AI 标签：用户标签在前，去重保序。
List<String> mergeTags(List<String> userTags, List<String> aiTags) {
  final result = <String>[];
  for (final tag in [...userTags, ...aiTags]) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !result.contains(trimmed)) result.add(trimmed);
  }
  return result;
}
