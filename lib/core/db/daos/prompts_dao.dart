part of '../database.dart';

/// prompts 表 DAO。
@DriftAccessor(tables: [Prompts])
class PromptsDao extends DatabaseAccessor<AppDatabase> with _$PromptsDaoMixin {
  PromptsDao(super.db);

  Stream<List<Prompt>> watchAll() =>
      (select(prompts)..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
          .watch();

  Future<List<Prompt>> byType(PromptType type) =>
      (select(prompts)..where((t) => t.type.equalsValue(type))).get();

  Future<Prompt?> byId(int id) =>
      (select(prompts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Prompt>> search(String keyword) {
    final pattern = '%$keyword%';
    return (select(
      prompts,
    )..where((t) => t.title.like(pattern) | t.body.like(pattern))).get();
  }

  Future<int> add(PromptsCompanion entry) => into(prompts).insert(entry);

  Future<bool> updateRow(Prompt row) => update(prompts).replace(row);

  /// 定向优化落新版本后前移当前版本指针（docs/02 模块C）。
  Future<void> setCurrentVersion(int id, int versionId) =>
      (update(prompts)..where((t) => t.id.equals(id))).write(
        PromptsCompanion(currentVersionId: Value(versionId)),
      );

  Future<int> remove(int id) =>
      (delete(prompts)..where((t) => t.id.equals(id))).go();
}
