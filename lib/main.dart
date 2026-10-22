import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/db/database.dart';
import 'core/db/database_provider.dart';
import 'core/seed/app_data_dir.dart';
import 'core/seed/app_seeder.dart';
import 'features/books/services/default_book_seeder.dart';
import 'features/settings/services/backup_service.dart';

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

  // 上次会话若有「从备份导入」暂存的库文件（app.db.imported），开库前换入。
  try {
    final dir = await resolveAppDataDirectory();
    await BackupService.applyPendingImport(File(p.join(dir.path, 'app.db')));
  } catch (_) {
    // 数据目录不可用（异常环境）：照常启动，导入待下次。
  }

  // 初始化数据库并执行首启种子（schemas 落盘、intensity 预设、默认设置）。
  final db = AppDatabase.open();
  await AppSeeder(db).run();
  // 内置书籍（公众号导读 + 图解）——同 builtinKey 已存在时跳过。
  await DefaultBookSeeder.run(db);

  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const CreativeKbApp(),
    ),
  );
}
