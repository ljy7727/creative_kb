import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../../memos/providers/memos_providers.dart' show secretBoxProvider;
import '../services/password_service.dart';

/// 密码本服务（加密主密钥来自 secretBoxProvider，见 core/crypto）。
final passwordServiceProvider = Provider<PasswordService>(
  (ref) => PasswordService(
    ref.watch(appDatabaseProvider),
    ref.watch(secretBoxProvider),
  ),
);

/// 密码本列表（按更新时间倒序）。
final passwordEntriesStreamProvider = StreamProvider<List<PasswordEntryRow>>(
  (ref) => ref.watch(passwordServiceProvider).watchAll(),
);
