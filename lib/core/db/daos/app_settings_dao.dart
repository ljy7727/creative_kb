part of '../database.dart';

/// app_settings 表 DAO：键值读写，值均为字符串。
@DriftAccessor(tables: [AppSettings])
class AppSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$AppSettingsDaoMixin {
  AppSettingsDao(super.db);

  Future<String?> get(String key) async {
    final row = await (select(
      appSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// 覆盖写入（upsert）。
  Future<void> set(String key, String value) =>
      into(appSettings)
          .insertOnConflictUpdate(AppSetting(key: key, value: value));

  Stream<String?> watch(String key) {
    final query = select(appSettings)..where((t) => t.key.equals(key));
    return query.watchSingleOrNull().map((row) => row?.value);
  }

  Future<Map<String, String>> getAll() async {
    final rows = await select(appSettings).get();
    return {for (final row in rows) row.key: row.value};
  }
}
