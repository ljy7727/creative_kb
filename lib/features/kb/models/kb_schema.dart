import 'dart:convert';

/// 分类 Schema（docs/02 D1）：JSON 文件存于应用数据目录 schemas/，
/// 应用不硬编码，用户可编辑/新增（保存即热加载）。
///
/// JSON 结构：
/// `{id, name, matchKeywords[], baseSchema, fields:[{key,label,type,required,options?}]}`，
/// type 取值 enum|text|markdown|number；baseSchema=general 表示沿用通用基础字段
/// （名称/标签/概述/正文 Markdown/可信度）。
class KbSchemaField {
  const KbSchemaField({
    required this.key,
    required this.label,
    this.type = KbSchemaFieldType.text,
    this.required = false,
    this.options = const <String>[],
  });

  factory KbSchemaField.fromJson(Map<String, dynamic> json) {
    final key = (json['key'] as String?)?.trim() ?? '';
    return KbSchemaField(
      key: key,
      label: (json['label'] as String?)?.trim().isNotEmpty == true
          ? (json['label'] as String).trim()
          : key,
      type: KbSchemaFieldType.fromName((json['type'] as String?) ?? 'text'),
      required: json['required'] == true,
      options: [
        for (final option in (json['options'] as List<dynamic>? ?? const []))
          '$option',
      ],
    );
  }

  final String key;
  final String label;
  final KbSchemaFieldType type;
  final bool required;
  final List<String> options;

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'type': type.jsonName,
    if (required) 'required': true,
    if (options.isNotEmpty) 'options': options,
  };
}

/// 字段类型（docs/02 D1）。JSON 名 enum 与 Dart 关键字冲突，枚举值用 enumeration。
enum KbSchemaFieldType {
  text('text'),
  markdown('markdown'),
  number('number'),
  enumeration('enum');

  const KbSchemaFieldType(this.jsonName);

  final String jsonName;

  static KbSchemaFieldType fromName(String name) {
    for (final value in values) {
      if (value.jsonName == name) return value;
    }
    return KbSchemaFieldType.text;
  }
}

class KbSchemaFormatException implements Exception {
  const KbSchemaFormatException(this.message);

  final String message;

  @override
  String toString() => 'Schema 格式错误：$message';
}

class KbSchema {
  const KbSchema({
    required this.id,
    required this.name,
    this.matchKeywords = const <String>[],
    this.baseSchema,
    this.fields = const <KbSchemaField>[],
  });

  static const generalSchemaId = 'general';

  factory KbSchema.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    if (id.isEmpty) {
      throw const KbSchemaFormatException('缺少 id');
    }
    return KbSchema(
      id: id,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : id,
      matchKeywords: [
        for (final keyword
            in (json['matchKeywords'] as List<dynamic>? ?? const []))
          '$keyword',
      ],
      baseSchema: json['baseSchema'] as String?,
      fields: [
        for (final field in (json['fields'] as List<dynamic>? ?? const []))
          if (field is Map<String, dynamic>) KbSchemaField.fromJson(field),
      ],
    );
  }

  factory KbSchema.fallbackGeneral() => const KbSchema(
    id: generalSchemaId,
    name: '通用',
    baseSchema: generalSchemaId,
  );

  final String id;
  final String name;
  final List<String> matchKeywords;

  /// 沿用的基础 Schema id（v1 只有 general，结构预留）。
  final String? baseSchema;
  final List<KbSchemaField> fields;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'matchKeywords': matchKeywords,
    'baseSchema': baseSchema ?? generalSchemaId,
    'fields': [for (final field in fields) field.toJson()],
  };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// 提示词摘要：一行描述字段清单（docs/02 D2 系统提示词用）。
  String promptDigest() {
    if (fields.isEmpty) return '- $id（$name）：无扩展字段';
    final fieldsDesc = fields
        .map(
          (f) =>
              '${f.label}[${f.key}](${f.type.jsonName}${f.required ? ',必填' : ''})',
        )
        .join('、');
    return '- $id（$name）：$fieldsDesc';
  }

  KbSchemaField? fieldByKey(String key) {
    for (final field in fields) {
      if (field.key == key) return field;
    }
    return null;
  }

  /// 校验扩展字段取值（docs/02 D2 第3步）。返回中文问题列表，空列表 = 通过。
  List<String> validateExtra(Map<String, Object?> extra) {
    final issues = <String>[];
    for (final field in fields) {
      final value = extra[field.key];
      final missing =
          value == null || (value is String && value.trim().isEmpty);
      if (field.required && missing) {
        issues.add('缺少必填字段「${field.label}」');
        continue;
      }
      if (missing) continue;
      switch (field.type) {
        case KbSchemaFieldType.number:
          if (value is! num &&
              (value is! String || num.tryParse(value) == null)) {
            issues.add('字段「${field.label}」需要数字');
          }
          break;
        case KbSchemaFieldType.enumeration:
          if (field.options.isNotEmpty && !field.options.contains('$value')) {
            issues.add('字段「${field.label}」取值需为：${field.options.join('/')}');
          }
          break;
        case KbSchemaFieldType.text:
        case KbSchemaFieldType.markdown:
          if (value is Map || value is List) {
            issues.add('字段「${field.label}」需要文本');
          }
          break;
      }
    }
    return issues;
  }
}

/// matchKeywords 命中计数推荐 Schema（docs/02 D1：按关键词匹配自动建议）。
/// 无命中回退 general（注册表为空时返回兜底通用 Schema）。
KbSchema suggestSchemaFor(List<KbSchema> schemas, String text) {
  final lower = text.toLowerCase();
  KbSchema? best;
  var bestCount = 0;
  for (final schema in schemas) {
    var count = 0;
    for (final keyword in schema.matchKeywords) {
      if (keyword.isNotEmpty && lower.contains(keyword.toLowerCase())) count++;
    }
    if (count > bestCount) {
      best = schema;
      bestCount = count;
    }
  }
  if (best != null) return best;
  for (final schema in schemas) {
    if (schema.id == KbSchema.generalSchemaId) return schema;
  }
  if (schemas.isNotEmpty) return schemas.first;
  return KbSchema.fallbackGeneral();
}

KbSchema? schemaById(List<KbSchema> schemas, String id) {
  for (final schema in schemas) {
    if (schema.id == id) return schema;
  }
  return null;
}
