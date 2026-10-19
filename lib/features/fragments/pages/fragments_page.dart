import 'package:flutter/material.dart';

import '../../../shared/placeholder_page.dart';

/// 模块1 灵感碎片——占位页（T4 实现录入/AI 优化/双版本对比）。
class FragmentsPage extends StatelessWidget {
  const FragmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      icon: Icons.lightbulb_outline,
      title: '灵感',
      message: '灵感碎片模块建设中：快捷录入、AI 优化整理、双版本对比、转提示词/资料条目。',
    );
  }
}
