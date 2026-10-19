import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

/// 全局数据库实例。main 中完成初始化与首启 seed 后用
/// `appDatabaseProvider.overrideWithValue(db)` 注入；widget 树内只读。
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider 必须在 main 中 override'),
);
