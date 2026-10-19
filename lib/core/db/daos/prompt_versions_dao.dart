part of '../database.dart';

/// prompt_versions 表 DAO：版本历史与回滚（docs/02 模块C）。
@DriftAccessor(tables: [PromptVersions])
class PromptVersionsDao extends DatabaseAccessor<AppDatabase>
    with _$PromptVersionsDaoMixin {
  PromptVersionsDao(super.db);

  /// 某提示词的全部版本，新版本在前。
  Future<List<PromptVersion>> byPrompt(int promptId) =>
      (select(promptVersions)
            ..where((t) => t.promptId.equals(promptId))
            ..orderBy([(t) => OrderingTerm.desc(t.id)]))
          .get();

  Future<PromptVersion?> byId(int id) =>
      (select(promptVersions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> add(PromptVersionsCompanion entry) =>
      into(promptVersions).insert(entry);

  Future<int> removeByPrompt(int promptId) =>
      (delete(promptVersions)..where((t) => t.promptId.equals(promptId))).go();
}
