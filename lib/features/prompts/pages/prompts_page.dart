import 'package:flutter/material.dart';

import '../../../shared/placeholder_page.dart';

/// 模块2 提示词库——占位页（T5 实现三类模板/3 风格生成/定向优化/变量提取）。
class PromptsPage extends StatelessWidget {
  const PromptsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      icon: Icons.auto_awesome,
      title: '提示词',
      message: '提示词库模块建设中：小说/绘画/Agent 三类模板、风格生成、版本管理与回滚。',
    );
  }
}
