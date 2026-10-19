import '../models/prompt_models.dart';

/// {{变量}} 标注与填充（docs/02 模块C「变量提取」）。
/// 语法：{{变量名}}，变量名内不含花括号与换行；未填值的变量保留原标注。

final RegExp _variablePattern = RegExp(r'\{\{\s*([^{}\n]+?)\s*\}\}');

/// 提取正文中已标注的变量名：去重且保持首次出现顺序。
List<String> extractVariableNames(String body) {
  final names = <String>[];
  for (final match in _variablePattern.allMatches(body)) {
    final name = match.group(1)!;
    if (!names.contains(name)) names.add(name);
  }
  return names;
}

/// 用 [values] 填充变量；没有对应值的变量保留 {{}} 标注，便于继续编辑。
String fillVariables(String body, Map<String, String> values) {
  return body.replaceAllMapped(_variablePattern, (match) {
    final name = match.group(1)!;
    final value = values[name];
    if (value == null || value.isEmpty) return match.group(0)!;
    return value;
  });
}

/// 列出尚未填值的变量名。
List<String> missingVariables(String body, Map<String, String> values) => [
  for (final name in extractVariableNames(body))
    if (values[name] == null || values[name]!.isEmpty) name,
];

/// 把变量名在正文中的裸出现包成 {{变量名}}；已有的 {{}} 区间原样保留。
String annotateVariables(String body, Iterable<String> names) {
  final cleanNames = [
    for (final name in names)
      if (name.trim().isNotEmpty) name.trim(),
  ];
  if (cleanNames.isEmpty) return body;

  final buffer = StringBuffer();
  var last = 0;
  for (final match in _variablePattern.allMatches(body)) {
    _annotatePlain(buffer, body.substring(last, match.start), cleanNames);
    buffer.write(match.group(0));
    last = match.end;
  }
  _annotatePlain(buffer, body.substring(last), cleanNames);
  return buffer.toString();
}

void _annotatePlain(StringBuffer out, String chunk, List<String> names) {
  var text = chunk;
  for (final name in names) {
    if (name.isEmpty || text.isEmpty) continue;
    final builder = StringBuffer();
    var from = 0;
    while (true) {
      final index = text.indexOf(name, from);
      if (index < 0) {
        builder.write(text.substring(from));
        break;
      }
      builder.write(text.substring(from, index));
      builder.write('{{$name}}');
      from = index + name.length;
    }
    text = builder.toString();
  }
  out.write(text);
}

/// 合并 DB 变量表与正文实际标注：正文为准补缺（详情页变量面板的数据来源）。
List<PromptVariable> resolveVariables({
  required String variablesJson,
  required String body,
}) {
  final stored = PromptVariable.decode(variablesJson);
  final extra = [
    for (final name in extractVariableNames(body))
      if (!stored.any((variable) => variable.name == name))
        PromptVariable(name: name, desc: ''),
  ];
  return [...stored, ...extra];
}
