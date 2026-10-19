import 'dart:convert';

import '../../../core/db/tables.dart';

/// 提示词类型中文标签（docs/02 模块C：novel/image/agent）。
extension PromptTypeX on PromptType {
  String get label => switch (this) {
    PromptType.novel => '小说写作',
    PromptType.image => 'AI 绘画',
    PromptType.agent => 'Agent 指令',
  };
}

/// 「从碎片生成」的 3 个风格档（docs/02 模块C）。
enum PromptStyle { concise, detailed, creative }

extension PromptStyleX on PromptStyle {
  /// JSON 契约中的风格名：精简|详细|创意。
  String get label => switch (this) {
    PromptStyle.concise => '精简',
    PromptStyle.detailed => '详细',
    PromptStyle.creative => '创意',
  };
}

/// 按契约风格名解析；未知风格返回 null。
PromptStyle? promptStyleFromLabel(String label) {
  for (final style in PromptStyle.values) {
    if (style.label == label) return style;
  }
  return null;
}

/// 「定向优化」的 4 个方向（docs/02 模块C）。
enum OptimizeDirection { condense, expand, adaptModel, restyle }

extension OptimizeDirectionX on OptimizeDirection {
  String get label => switch (this) {
    OptimizeDirection.condense => '精简压缩',
    OptimizeDirection.expand => '扩写丰富',
    OptimizeDirection.adaptModel => '适配特定模型',
    OptimizeDirection.restyle => '风格转换',
  };

  /// 「适配特定模型」需附带目标模型名。
  bool get needsTargetModel => this == OptimizeDirection.adaptModel;

  /// 「风格转换」需附带目标风格描述。
  bool get needsTargetStyle => this == OptimizeDirection.restyle;
}

/// prompts.variables 列的元素结构，存储格式为 JSON 数组 [{name,desc}]。
class PromptVariable {
  const PromptVariable({required this.name, required this.desc});

  final String name;
  final String desc;

  Map<String, dynamic> toJson() => {'name': name, 'desc': desc};

  factory PromptVariable.fromJson(Map<String, dynamic> json) => PromptVariable(
    name: (json['name'] ?? '').toString(),
    desc: (json['desc'] ?? '').toString(),
  );

  /// 全量序列化为 prompts.variables 存储格式。
  static String encode(List<PromptVariable> variables) =>
      jsonEncode([for (final variable in variables) variable.toJson()]);

  /// 容错解析：非法 JSON 一律视为无变量（列内容由上层写入，需防历史脏数据）。
  static List<PromptVariable> decode(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>) PromptVariable.fromJson(item),
      ];
    } on FormatException {
      return const [];
    }
  }
}

/// 「从碎片生成」的单个风格版本。
class StyleDraft {
  const StyleDraft({required this.style, required this.body});

  final PromptStyle style;
  final String body;
}

/// 「定向优化」结果。
class OptimizeResult {
  const OptimizeResult({required this.body, this.note});

  final String body;
  final String? note;
}

/// 「变量提取」结果：变量表 + 本地标注 {{变量}} 后的正文。
class VariablesExtractResult {
  const VariablesExtractResult({
    required this.variables,
    required this.annotatedBody,
  });

  final List<PromptVariable> variables;
  final String annotatedBody;
}
