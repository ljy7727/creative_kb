import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/crypto/secret_box.dart';
import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../services/memo_image_store.dart';

/// 备忘录图片存储。
final memoImageStoreProvider = Provider<MemoImageStore>(
  (ref) => MemoImageStore(),
);

/// 备忘录表访问（跟随应用数据库）。
final memosDaoProvider = Provider<MemosDao>(
  (ref) => ref.watch(appDatabaseProvider).memosDao,
);

/// 备忘录实时列表（更新时间倒序）。
final memosStreamProvider = StreamProvider<List<MemoRow>>(
  (ref) => ref.watch(memosDaoProvider).watchAll(),
);

/// 密码本加密服务（主密钥在系统安全存储）。
final secretBoxProvider = Provider<SecretBoxService>(
  (ref) => SecretBoxService(),
);
