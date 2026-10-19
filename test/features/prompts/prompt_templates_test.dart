import 'package:creative_kb/core/db/tables.dart';
import 'package:creative_kb/features/prompts/services/prompt_templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('内置骨架模板覆盖 novel/image/agent 三类（docs/02 模块C）', () {
    expect(PromptSkeletonTemplates.all.map((t) => t.type).toList(), [
      PromptType.novel,
      PromptType.image,
      PromptType.agent,
    ]);
    expect(PromptSkeletonTemplates.byType(PromptType.image).name, 'AI 绘画');
    expect(PromptSkeletonTemplates.byType(PromptType.agent).name, 'Agent 指令');
  });

  test('novel/agent 模板渲染为「角色设定/任务目标/约束/输出格式」四段式', () {
    for (final type in [PromptType.novel, PromptType.agent]) {
      final rendered = PromptSkeletonTemplates.byType(type).render();
      expect(rendered, contains('## 角色设定'));
      expect(rendered, contains('## 任务目标'));
      expect(rendered, contains('## 约束'));
      expect(rendered, contains('## 输出格式'));
      expect(rendered, isNot(contains('## 主体')));
    }
  });

  test('image 模板渲染为「主体/风格/构图/画质词」四段式', () {
    final rendered = PromptSkeletonTemplates.image.render();
    expect(rendered, contains('## 主体'));
    expect(rendered, contains('## 风格'));
    expect(rendered, contains('## 构图'));
    expect(rendered, contains('## 画质词'));
    expect(rendered, isNot(contains('## 角色设定')));
  });

  test('每段带填写指引，渲染结果可直接作为新建初稿正文', () {
    for (final template in PromptSkeletonTemplates.all) {
      final rendered = template.render();
      expect(rendered, contains('（'));
      for (final section in template.sections) {
        expect(rendered, contains('## ${section.title}'));
        expect(rendered, contains(section.hint));
      }
    }
  });
}
