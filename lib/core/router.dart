import 'package:flutter/material.dart';

import '../shared/placeholder_page.dart';

/// 路由常量表（docs/01：Navigator 简化版，onGenerateRoute + 常量表）。
/// 五个一级入口是 AppShell 内部 Tab，不占命名路由；命名路由只放二级页面。
/// 本表为定稿：既有路径与参数 key 后续模块不得改名，只允许追加新条目。
abstract final class RoutePaths {
  static const home = '/';

  // 模块1 灵感碎片
  static const fragmentDetail = '/fragments/detail';

  // 模块2 提示词库
  static const promptDetail = '/prompts/detail';
  static const promptGenerate = '/prompts/generate'; // 从碎片转提示词草稿
  static const promptOptimize = '/prompts/optimize';

  // 模块3 资料库
  static const kbEntryDetail = '/kb/entry';
  static const kbIngest = '/kb/ingest'; // 五步入库向导（可从碎片预填）
  static const kbSearch = '/kb/search';
}

/// 路由参数 key 常量（arguments 用 `Map<String, Object?>`，取值走这里的 key）。
abstract final class RouteArgs {
  static const fragmentId = 'fragmentId';
  static const fragmentIds = 'fragmentIds';
  static const promptId = 'promptId';
  static const entryId = 'entryId';
}

/// 已登记但尚未实现的页面的标题。
const _routeTitles = <String, String>{
  RoutePaths.fragmentDetail: '灵感详情',
  RoutePaths.promptDetail: '提示词详情',
  RoutePaths.promptGenerate: '从碎片生成提示词',
  RoutePaths.promptOptimize: '定向优化提示词',
  RoutePaths.kbEntryDetail: '条目详情',
  RoutePaths.kbIngest: '资料入库向导',
  RoutePaths.kbSearch: '资料检索',
};

/// onGenerateRoute：已登记未实现的页面统一给占位页（避免黑屏），
/// 未登记路由返回 null 交给 onUnknownRoute。
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  final title = _routeTitles[settings.name];
  if (title == null) return null;
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const PlaceholderPage(
        icon: Icons.construction,
        title: '页面建设中',
        message: '该页面由后续功能模块实现。',
      ),
    ),
  );
}
