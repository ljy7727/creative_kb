import 'package:flutter/material.dart';

/// 路由常量表（docs/01：Navigator 简化版，onGenerateRoute + 常量表）。
/// 五个一级入口是 AppShell 内部 Tab，不占命名路由；命名路由只放二级页面。
/// 本表为定稿：既有路径与参数 key 后续模块不得改名，只允许追加新条目。
///
/// 页面构建接线在 app.dart（组合根；core 不反向依赖 features）。
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
  static const initialText = 'initialText';
}

/// 从 arguments Map 提取整型参数；缺失时抛 ArgumentError（路由接线约定）。
int intArg(RouteSettings settings, String key) {
  final args = settings.arguments;
  final value = args is Map ? args[key] : null;
  if (value is int) return value;
  throw ArgumentError('路由 ${settings.name} 缺少整型参数 $key');
}

/// 从 arguments Map 提取可空整型参数。
int? intArgOrNull(RouteSettings settings, String key) {
  final args = settings.arguments;
  final value = args is Map ? args[key] : null;
  return value is int ? value : null;
}

/// 从 arguments Map 提取可空字符串参数。
String? stringArgOrNull(RouteSettings settings, String key) {
  final args = settings.arguments;
  final value = args is Map ? args[key] : null;
  return value is String ? value : null;
}
