import '../../../core/db/tables.dart';

/// 单段模板：段标题 + 该段的填写指引（占位说明）。
class PromptTemplateSection {
  const PromptTemplateSection(this.title, this.hint);

  final String title;
  final String hint;
}

/// 三类骨架模板（docs/02 模块C）：novel/agent 为「角色设定/任务目标/约束/输出格式」
/// 四段式；image 为「主体/风格/构图/画质词」四段式。
class PromptSkeletonTemplate {
  const PromptSkeletonTemplate({
    required this.type,
    required this.name,
    required this.description,
    required this.sections,
  });

  final PromptType type;
  final String name;
  final String description;
  final List<PromptTemplateSection> sections;

  /// 渲染为可直接编辑保存的初稿正文（Markdown 二级标题分段）。
  String render() =>
      [for (final section in sections) '## ${section.title}\n${section.hint}']
          .join('\n\n');
}

abstract final class PromptSkeletonTemplates {
  static const novel = PromptSkeletonTemplate(
    type: PromptType.novel,
    name: '小说写作',
    description: '面向章节/场景写作：角色设定、任务目标、约束、输出格式。',
    sections: [
      PromptTemplateSection('角色设定', '（写作者扮演的身份与专长，如：资深仙侠网文作者，擅长铺陈伏笔）'),
      PromptTemplateSection('任务目标', '（写什么：题材、视角、篇幅、情节要点与情感基调）'),
      PromptTemplateSection('约束', '（硬性限制：禁写内容、文风要求、必须保留或回避的设定）'),
      PromptTemplateSection('输出格式', '（交付形式：直接输出正文、是否分场景小标题、字数区间等）'),
    ],
  );

  static const image = PromptSkeletonTemplate(
    type: PromptType.image,
    name: 'AI 绘画',
    description: '面向文生图提示词：主体、风格、构图、画质词。',
    sections: [
      PromptTemplateSection('主体', '（画面主体：人物/场景/物件的外观、动作、服饰等关键细节）'),
      PromptTemplateSection('风格', '（画风与媒介：如水墨、赛博朋克、厚涂、写实摄影、吉卜力风）'),
      PromptTemplateSection('构图', '（视角与布局：景别、机位、光线、色调、留白）'),
      PromptTemplateSection('画质词', '（质量强化词：如 8k、细节丰富、大师作品；按目标模型增删）'),
    ],
  );

  static const agent = PromptSkeletonTemplate(
    type: PromptType.agent,
    name: 'Agent 指令',
    description: '面向 Agent/系统提示词：角色设定、任务目标、约束、输出格式。',
    sections: [
      PromptTemplateSection('角色设定', '（Agent 的身份、能力范围与语气）'),
      PromptTemplateSection('任务目标', '（输入是什么、处理步骤、期望达成的结果）'),
      PromptTemplateSection('约束', '（必须遵守的规则：不编造事实、失败时的报告方式、安全边界）'),
      PromptTemplateSection('输出格式', '（输出契约：纯文本或 JSON，字段含义与示例）'),
    ],
  );

  static const List<PromptSkeletonTemplate> all = [novel, image, agent];

  static PromptSkeletonTemplate byType(PromptType type) =>
      all.firstWhere((template) => template.type == type);
}
