import 'package:flutter/material.dart';

import '../../../shared/placeholder_page.dart';

/// 用量统计——占位页（T3 实现今日/累计 token、模块饼图、模型柱状、明细表）。
class UsagePage extends StatelessWidget {
  const UsagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      icon: Icons.insights_outlined,
      title: '用量',
      message: '用量统计模块建设中：今日/累计 token、按模块与模型的图表、最近明细与费用参考。',
    );
  }
}
