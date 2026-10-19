import 'package:flutter/material.dart';

import '../../../shared/placeholder_page.dart';

/// 模块3 创作资料库——占位页（T6 实现分类树/入库向导/条目详情/混合检索）。
class KbPage extends StatelessWidget {
  const KbPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      icon: Icons.menu_book_outlined,
      title: '资料库',
      message: '创作资料库模块建设中：分类树、五步入库向导、条目详情与关键词+语义混合检索。',
    );
  }
}
