part of '../database.dart';

/// kb_categories 表 DAO。path 以 "/" 分隔层级，入库向导可自动逐级建类。
@DriftAccessor(tables: [KbCategories])
class KbCategoriesDao extends DatabaseAccessor<AppDatabase> with _$KbCategoriesDaoMixin {
  KbCategoriesDao(super.db);

  Stream<List<KbCategory>> watchAll() =>
      (select(kbCategories)..orderBy([(t) => OrderingTerm.asc(t.path)])).watch();

  Future<List<KbCategory>> getAll() => select(kbCategories).get();

  Future<KbCategory?> byId(int id) =>
      (select(kbCategories)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<KbCategory?> byPath(String path) =>
      (select(kbCategories)..where((t) => t.path.equals(path))).getSingleOrNull();

  Future<List<KbCategory>> childrenOf(int parentId) => (select(kbCategories)
            ..where((t) => t.parentId.equals(parentId))
            ..orderBy([(t) => OrderingTerm.asc(t.path)]))
          .get();

  /// 确保分类路径存在，逐级创建（缺失的父级一并补齐）；返回最末级 id。
  Future<int> ensurePath(String path) async {
    final segments = path.split('/');
    var parentId = -1;
    var current = '';
    for (final segment in segments) {
      final seg = segment.trim();
      if (seg.isEmpty) continue;
      current = current.isEmpty ? seg : '$current/$seg';
      final existing = await byPath(current);
      if (existing != null) {
        parentId = existing.id;
        continue;
      }
      parentId = await into(kbCategories).insert(KbCategoriesCompanion.insert(
        path: current,
        parentId: Value(parentId < 0 ? null : parentId),
      ));
    }
    return parentId;
  }

  Future<int> remove(int id) =>
      (delete(kbCategories)..where((t) => t.id.equals(id))).go();
}
