part of '../database.dart';

/// fragments 表 DAO。
@DriftAccessor(tables: [Fragments])
class FragmentsDao extends DatabaseAccessor<AppDatabase> with _$FragmentsDaoMixin {
  FragmentsDao(super.db);

  /// 列表按时间倒序（docs/02 B2）。
  Stream<List<Fragment>> watchAll() =>
      (select(fragments)..orderBy([(t) => OrderingTerm.desc(t.createdAt), (t) => OrderingTerm.desc(t.id)]))
          .watch();

  Future<List<Fragment>> getAll() => select(fragments).get();

  Future<Fragment?> byId(int id) =>
      (select(fragments)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 简易关键词检索：LIKE 命中标题或原文（docs/02 B2，量小不做 FTS）。
  Future<List<Fragment>> search(String keyword) {
    final pattern = '%$keyword%';
    return (select(fragments)
          ..where((t) => t.rawText.like(pattern) | t.title.like(pattern))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<int> add(FragmentsCompanion entry) => into(fragments).insert(entry);

  Future<bool> updateRow(Fragment row) => update(fragments).replace(row);

  /// AI 优化完成后回写双版本字段。
  Future<void> applyOptimization({
    required int id,
    required String title,
    required String optimizedJson,
    required String tagsJson,
    required String aiMetaJson,
  }) =>
      (update(fragments)..where((t) => t.id.equals(id))).write(FragmentsCompanion(
        title: Value(title),
        optimizedJson: Value(optimizedJson),
        tags: Value(tagsJson),
        aiMeta: Value(aiMetaJson),
        status: const Value(FragmentStatus.optimized),
        updatedAt: Value(DateTime.now()),
      ));

  /// 优化失败置 failed（保留 rawText 供重试）。
  Future<void> markFailed(int id, String aiMetaJson) =>
      (update(fragments)..where((t) => t.id.equals(id))).write(FragmentsCompanion(
        aiMeta: Value(aiMetaJson),
        status: const Value(FragmentStatus.failed),
        updatedAt: Value(DateTime.now()),
      ));

  Future<int> remove(int id) =>
      (delete(fragments)..where((t) => t.id.equals(id))).go();
}
