part of '../database.dart';

/// memos 表 DAO：按更新时间倒序；搜索走标题/正文 LIKE（数据量小，无需 FTS）。
@DriftAccessor(tables: [Memos])
class MemosDao extends DatabaseAccessor<AppDatabase> with _$MemosDaoMixin {
  MemosDao(super.db);

  Stream<List<MemoRow>> watchAll() => (select(
    memos,
  )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  Future<List<MemoRow>> getAll() => (select(
    memos,
  )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();

  Future<MemoRow?> byId(int id) =>
      (select(memos)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> add(MemosCompanion entry) => into(memos).insert(entry);

  Future<void> updateRow(MemoRow row) => update(memos).replace(row);

  Future<void> deleteById(int id) =>
      (delete(memos)..where((t) => t.id.equals(id))).go();
}
