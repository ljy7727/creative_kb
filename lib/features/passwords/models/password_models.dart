import 'dart:convert';

/// 密码本自定义字段：左侧名称（如 账号/密码/验证号），右侧值。
class PasswordField {
  const PasswordField({required this.label, required this.value});

  final String label;
  final String value;

  PasswordField copyWith({String? label, String? value}) =>
      PasswordField(label: label ?? this.label, value: value ?? this.value);

  Map<String, dynamic> toJson() => {'label': label, 'value': value};

  static PasswordField? tryParse(Object? raw) {
    if (raw is! Map) return null;
    return PasswordField(
      label: '${raw['label'] ?? ''}',
      value: '${raw['value'] ?? ''}',
    );
  }

  bool get isBlank => label.trim().isEmpty && value.trim().isEmpty;
}

/// 字段数组 ⇄ JSON（损坏/非法按空数组处理）。
List<PasswordField> decodeFieldsJson(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is List) {
      return [
        for (final item in decoded)
          ?PasswordField.tryParse(item),
      ];
    }
  } catch (_) {
    // 损坏按空处理。
  }
  return const [];
}

String encodeFieldsJson(List<PasswordField> fields) =>
    jsonEncode([for (final field in fields) field.toJson()]);
