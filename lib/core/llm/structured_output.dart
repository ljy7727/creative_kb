// 结构化输出（docs/01 第五节 / docs/02 A1）：
// 剥离 ```json 围栏 → jsonDecode → 按 Schema 校验必填与类型 → 失败拼错误重试 ≤2。
import 'dart:convert';

import 'intensity.dart';
import 'llm_client.dart';
import 'providers.dart';

// ---------------------------------------------------------------------------
// Schema 定义
// ---------------------------------------------------------------------------

/// 校验失败的错误项。path 形如 `$.items[0].title`；message 为中文描述。
class SchemaViolation {
  const SchemaViolation({required this.path, required this.message});

  final String path;
  final String message;

  @override
  String toString() => '$path: $message';
}

/// 轻量 JSON Schema：递归对象字段 + 数组元素 + 基础类型；未知字段不限制
/// （模型可能补输出额外说明字段，强约束反而易碎）。
class StructSchema {
  const StructSchema.object({
    required this.properties,
    this.required = const <String>{},
  }) : type = 'object',
       items = null;

  const StructSchema.array({required this.items})
    : type = 'array',
      properties = const <String, StructSchema>{},
      required = const <String>{};

  const StructSchema.string() : this._('string');
  const StructSchema.number() : this._('number');
  const StructSchema.integer() : this._('integer');
  const StructSchema.boolean() : this._('boolean');
  const StructSchema.any() : this._('any');

  const StructSchema._(this.type)
    : properties = const <String, StructSchema>{},
      required = const <String>{},
      items = null;

  final String type; // object|array|string|number|integer|boolean|any
  final Map<String, StructSchema> properties;
  final Set<String> required;
  final StructSchema? items;

  /// 供提示词展示的最小 JSON Schema 描述（系统提示词需附 Schema 说明）。
  Map<String, dynamic> toPromptJson() {
    switch (type) {
      case 'object':
        return <String, dynamic>{
          'type': 'object',
          'properties': {
            for (final e in properties.entries) e.key: e.value.toPromptJson(),
          },
          'required': required.toList(),
        };
      case 'array':
        return <String, dynamic>{
          'type': 'array',
          'items': items!.toPromptJson(),
        };
      default:
        return <String, dynamic>{'type': type};
    }
  }
}

/// 递归校验 [value] 是否满足 [schema]；返回全部错误（为空即通过）。
List<SchemaViolation> validateStruct(
  Object? value,
  StructSchema schema, {
  String path = r'$',
}) {
  final violations = <SchemaViolation>[];
  switch (schema.type) {
    case 'object':
      if (value is! Map<String, dynamic>) {
        violations.add(
          SchemaViolation(
            path: path,
            message: '应为 JSON 对象（object），实际为 ${_typeName(value)}',
          ),
        );
        return violations;
      }
      for (final key in schema.required) {
        if (!value.containsKey(key)) {
          violations.add(
            SchemaViolation(path: '$path.$key', message: '缺少必填字段'),
          );
        }
      }
      for (final entry in schema.properties.entries) {
        if (!value.containsKey(entry.key)) continue;
        violations.addAll(
          validateStruct(
            value[entry.key],
            entry.value,
            path: '$path.${entry.key}',
          ),
        );
      }
      return violations;
    case 'array':
      if (value is! List) {
        violations.add(
          SchemaViolation(
            path: path,
            message: '应为 JSON 数组（array），实际为 ${_typeName(value)}',
          ),
        );
        return violations;
      }
      final itemSchema = schema.items;
      if (itemSchema != null) {
        for (var i = 0; i < value.length; i++) {
          violations.addAll(
            validateStruct(value[i], itemSchema, path: '$path[$i]'),
          );
        }
      }
      return violations;
    case 'string':
      if (value is! String) {
        violations.add(
          SchemaViolation(path: path, message: '应为字符串，实际为 ${_typeName(value)}'),
        );
      }
      return violations;
    case 'number':
      if (value is! num) {
        violations.add(
          SchemaViolation(path: path, message: '应为数字，实际为 ${_typeName(value)}'),
        );
      }
      return violations;
    case 'integer':
      if (value is! num || value % 1 != 0) {
        violations.add(
          SchemaViolation(path: path, message: '应为整数，实际为 ${_typeName(value)}'),
        );
      }
      return violations;
    case 'boolean':
      if (value is! bool) {
        violations.add(
          SchemaViolation(path: path, message: '应为布尔值，实际为 ${_typeName(value)}'),
        );
      }
      return violations;
    default:
      return violations; // any 不校验
  }
}

String _typeName(Object? value) {
  if (value == null) return 'null';
  if (value is String) return '字符串';
  if (value is num) return '数字';
  if (value is bool) return '布尔值';
  if (value is List) return '数组';
  if (value is Map) return '对象';
  return value.runtimeType.toString();
}

// ---------------------------------------------------------------------------
// JSON 提取（剥离围栏与前后杂质）
// ---------------------------------------------------------------------------

class JsonExtraction {
  const JsonExtraction(this.value) : error = null;
  const JsonExtraction.failure(this.error) : value = null;

  final Object? value;
  final String? error;

  bool get ok => error == null;
}

/// 从模型原始输出提取首个平衡的 JSON 值：
/// 1. 剥离 ```json / ``` 围栏；
/// 2. 忽略 JSON 前后的说明性文字，按括号配对截取首个 `{...}` 或 `[...]`；
/// 3. jsonDecode 失败返回 error。
JsonExtraction extractJson(String raw) {
  var text = raw.trim();
  if (text.startsWith('```')) {
    final firstNewline = text.indexOf('\n');
    if (firstNewline >= 0) text = text.substring(firstNewline + 1);
    final closing = text.lastIndexOf('```');
    if (closing >= 0) text = text.substring(0, closing);
    text = text.trim();
  }
  final start = _firstJsonStart(text);
  if (start < 0) {
    return const JsonExtraction.failure('输出中未找到 JSON 内容');
  }
  final end = _balancedEnd(text, start);
  if (end < 0) {
    return const JsonExtraction.failure('JSON 括号不配对，输出被截断');
  }
  final candidate = text.substring(start, end + 1);
  try {
    return JsonExtraction(jsonDecode(candidate));
  } on FormatException catch (e) {
    return JsonExtraction.failure('JSON 解析失败：${e.message}');
  }
}

int _firstJsonStart(String text) {
  final obj = text.indexOf('{');
  final arr = text.indexOf('[');
  if (obj < 0) return arr;
  if (arr < 0) return obj;
  return obj < arr ? obj : arr;
}

/// 从 [start]（必为 { 或 [）起扫描，返回与之配对的结束下标；未闭合返回 -1。
/// 字符串内的括号与转义不参与配对。
int _balancedEnd(String text, int start) {
  final open = text[start];
  final close = open == '{' ? '}' : ']';
  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var i = start; i < text.length; i++) {
    final ch = text[i];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (ch == '\\') {
        escaped = true;
      } else if (ch == '"') {
        inString = false;
      }
      continue;
    }
    if (ch == '"') {
      inString = true;
    } else if (ch == open) {
      depth++;
    } else if (ch == close) {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

// ---------------------------------------------------------------------------
// StructuredOutput 请求器
// ---------------------------------------------------------------------------

/// 结构化输出三态结果：成功 / 校验失败（重试耗尽）/ 传输异常（抛 LlmException）。
sealed class StructuredResult<T> {
  const StructuredResult();
}

class StructuredSuccess<T> extends StructuredResult<T> {
  const StructuredSuccess({
    required this.value,
    required this.rawText,
    required this.usage,
  });

  final T value;

  /// 模型原始输出（含围栏），排查用。
  final String rawText;
  final UsageInfo usage;
}

class StructuredFailure<T> extends StructuredResult<T> {
  const StructuredFailure({
    required this.violations,
    required this.attempts,
    this.rawText,
  });

  final List<SchemaViolation> violations;
  final String? rawText;

  /// 实际发起的请求次数（1 + 重试次数）。
  final int attempts;
}

/// 统一结构化输出口（docs/04 T4 约定接口名：`StructuredOutput.request<T>`）。
class StructuredOutput {
  StructuredOutput({required this.client, this.maxRetries = 2});

  /// 底层对话客户端（只读公开字段，命名参数 client 保持不变）。
  final LlmClient client;

  /// 校验失败自动重试上限（docs/01 第五节：≤2 次）。
  final int maxRetries;

  /// 发起一次结构化输出请求。
  ///
  /// [messages] 的系统提示词应已要求「只输出 JSON」；本方法负责剥离围栏、
  /// 校验与失败重试（把校验错误拼回消息）。网络/接口异常原样抛出类型化
  /// LlmException（计入任务级网络重试，与本校验重试相互独立）。
  ///
  /// [onDelta] 只在首次尝试时回调，重试修正不重复推送流式文本。
  Future<StructuredResult<T>> request<T>({
    required ProviderConfig provider,
    required String model,
    required List<ChatMessage> messages,
    required StructSchema schema,
    required T Function(Map<String, dynamic> json) decode,
    IntensityParams? intensity,
    void Function(String delta)? onDelta,
  }) async {
    final p = intensity?.toChatParams();
    var convo = List<ChatMessage>.of(messages);
    var attempt = 0;
    String? lastRaw;
    var violations = const <SchemaViolation>[];

    while (true) {
      final result = await client.chat(
        provider: provider,
        model: model,
        messages: convo,
        temperature: p?.temperature,
        topP: p?.topP,
        maxTokens: p?.maxTokens,
        extra: p?.extra,
        onDelta: attempt == 0 ? onDelta : null,
      );
      lastRaw = result.content;
      violations = _check(lastRaw, schema);
      if (violations.isEmpty) {
        // 校验已通过，decode 只做产物映射；防御性捕获映射异常按校验失败处理。
        try {
          final extracted = extractJson(lastRaw);
          final value = decode(extracted.value! as Map<String, dynamic>);
          return StructuredSuccess<T>(
            value: value,
            rawText: lastRaw,
            usage: result.usage,
          );
        } catch (e) {
          violations = [SchemaViolation(path: r'$', message: '结果映射失败：$e')];
        }
      }
      if (attempt >= maxRetries) {
        return StructuredFailure<T>(
          violations: violations,
          attempts: attempt + 1,
          rawText: lastRaw,
        );
      }
      final errorText = violations
          .map((v) => '- ${v.path}：${v.message}')
          .join('\n');
      convo = [
        ...convo,
        ChatMessage.assistant(lastRaw),
        ChatMessage.user(
          '你的输出未通过 JSON Schema 校验，错误如下：\n$errorText\n'
          '请修正后重新输出，只输出符合要求的 JSON 本体，'
          '不要包含任何解释文字或代码围栏。',
        ),
      ];
      attempt++;
    }
  }

  /// 提取 + 校验；返回空列表表示通过。
  List<SchemaViolation> _check(String raw, StructSchema schema) {
    final extraction = extractJson(raw);
    if (!extraction.ok) {
      return [SchemaViolation(path: r'$', message: extraction.error!)];
    }
    if (extraction.value is! Map<String, dynamic>) {
      return [const SchemaViolation(path: r'$', message: '顶层应为 JSON 对象')];
    }
    return validateStruct(extraction.value, schema);
  }
}
