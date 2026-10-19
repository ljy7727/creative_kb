import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router.dart';
import 'features/shell/app_shell.dart';

/// 应用根：Material 3 主题（深青色系 seed）+ 中文本地化 + 响应式导航壳。
class CreativeKbApp extends StatelessWidget {
  const CreativeKbApp({super.key});

  /// 深青色系种子色（docs/04 T1）。
  static const seedColor = Color(0xFF00695C);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '创作知识库',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
        useMaterial3: true,
      ),
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
