import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router.dart';
import 'features/kb/pages/kb_entry_detail_page.dart';
import 'features/kb/pages/kb_ingest_wizard_page.dart';
import 'features/kb/pages/kb_search_page.dart';
import 'features/fragments/pages/fragment_detail_page.dart';
import 'features/prompts/pages/prompt_detail_page.dart';
import 'features/prompts/pages/prompt_generate_page.dart';
import 'features/prompts/pages/prompt_optimize_page.dart';
import 'features/shell/app_shell.dart';
import 'shared/theme.dart';

/// 应用根：Material 3 主题（深青色系 seed）+ 中文本地化 + 响应式导航壳。
class CreativeKbApp extends StatelessWidget {
  const CreativeKbApp({super.key});

  /// 品牌种子色（v0.7 视觉系统见 shared/theme.dart）。
  static const seedColor = AppTheme.seed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '创作知识库',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh')],
      locale: const Locale('zh'),
      onGenerateRoute: onGenerateRoute,
      home: const AppShell(),
    );
  }
}

/// 命名路由 → 真实页面接线（docs/04 T7 路由全连通）。
/// 参数约定见 [RouteArgs]；参数不合法走 [ArgumentError]（开发期即暴露）。
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case RoutePaths.fragmentDetail:
      return _materialRoute(
        settings,
        FragmentDetailPage.fromSettings(settings),
      );
    case RoutePaths.promptDetail:
      return _materialRoute(
        settings,
        PromptDetailPage.fromRouteSettings(settings),
      );
    case RoutePaths.promptGenerate:
      return _materialRoute(
        settings,
        PromptGeneratePage.fromRouteSettings(settings),
      );
    case RoutePaths.promptOptimize:
      return _materialRoute(
        settings,
        PromptOptimizePage.fromRouteSettings(settings),
      );
    case RoutePaths.kbEntryDetail:
      return _materialRoute(
        settings,
        KbEntryDetailPage(entryId: intArg(settings, RouteArgs.entryId)),
      );
    case RoutePaths.kbIngest:
      return _materialRoute(
        settings,
        KbIngestWizardPage(
          fragmentId: intArgOrNull(settings, RouteArgs.fragmentId),
          initialText: stringArgOrNull(settings, RouteArgs.initialText),
        ),
      );
    case RoutePaths.kbSearch:
      return _materialRoute(settings, const KbSearchPage());
  }
  return null;
}

MaterialPageRoute<void> _materialRoute(RouteSettings settings, Widget page) =>
    MaterialPageRoute<void>(settings: settings, builder: (_) => page);
