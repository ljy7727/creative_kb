import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/db/database.dart';
import 'core/db/database_provider.dart';
import 'core/seed/app_seeder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows 桌面窗口：默认 1200×800，最小 900×600（docs/01）。
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(900, 600),
      center: true,
      title: '创作知识库',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // 初始化数据库并执行首启种子（schemas 落盘、intensity 预设、默认设置）。
  final db = AppDatabase.open();
  await AppSeeder(db).run();

  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const CreativeKbApp(),
    ),
  );
}
