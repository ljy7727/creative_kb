part of '../database.dart';

/// password_entries 表 DAO：按更新时间倒序；字段内容加解密由上层服务负责。
@DriftAccessor(tables: [PasswordEntries])
class PasswordEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$PasswordEntriesDaoMixin {
  PasswordEntriesDao(super.db);

  Stream<List<PasswordEntryRow>> watchAll() => (select(
    passwordEntries,
  )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  Future<List<PasswordEntryRow>> getAll() => (select(
    passwordEntries,
  )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();

  Future<PasswordEntryRow?> byId(int id) =>
      (select(passwordEntries)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> add(PasswordEntriesCompanion entry) =>
      into(passwordEntries).insert(entry);

  Future<void> updateRow(PasswordEntryRow row) =>
      update(passwordEntries).replace(row);

  Future<void> deleteById(int id) =>
      (delete(passwordEntries)..where((t) => t.id.equals(id))).go();
}
