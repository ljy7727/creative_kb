import 'package:flutter/material.dart';

import '../../../shared/placeholder_page.dart';

/// 设置——占位页（T7 实现厂商 Key/模型/强度/额度/Schema/更新/导入导出分组）。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      icon: Icons.settings_outlined,
      title: '设置',
      message: '设置模块建设中：厂商与 API Key、模型管理、思考强度、额度、Schema 注册表、更新与数据导入导出。',
    );
  }
}
