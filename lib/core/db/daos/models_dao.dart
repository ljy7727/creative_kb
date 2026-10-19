part of '../database.dart';

/// models 表 DAO：模型列表按厂商维护，(providerId, modelId) 唯一。
@DriftAccessor(tables: [Models])
class ModelsDao extends DatabaseAccessor<AppDatabase> with _$ModelsDaoMixin {
  ModelsDao(super.db);

  Stream<List<ModelRow>> watchByProvider(int providerId) =>
      (select(models)..where((t) => t.providerId.equals(providerId))).watch();

  Future<List<ModelRow>> byProvider(int providerId) =>
      (select(models)..where((t) => t.providerId.equals(providerId))).get();

  /// 各用途下拉框默认只展示启用中的模型（docs/02 A3）。
  Future<List<ModelRow>> activeByProvider(int providerId) => (select(models)
            ..where((t) => t.providerId.equals(providerId) & t.isActive.equals(true)))
          .get();

  Future<ModelRow?> byProviderAndModelId(int providerId, String modelId) =>
      (select(models)
            ..where((t) => t.providerId.equals(providerId) & t.modelId.equals(modelId)))
          .getSingleOrNull();

  /// 拉取模型入库：存在则更新名称，不存在则插入（保留用户已改的 tags/isActive）。
  Future<int> upsertModelId({
    required int providerId,
    required String modelId,
    required String displayName,
  }) async {
    final existing = await byProviderAndModelId(providerId, modelId);
    if (existing != null) {
      if (existing.displayName == displayName) return existing.id;
      await (update(models)..where((t) => t.id.equals(existing.id))).write(
        ModelsCompanion(displayName: Value(displayName), updatedAt: Value(DateTime.now())),
      );
      return existing.id;
    }
    return into(models).insert(ModelsCompanion.insert(
      providerId: providerId,
      modelId: modelId,
      displayName: displayName,
    ));
  }

  /// 用户手动改标签（docs/02 A3：isActive 保持、tags 覆盖）。
  Future<void> updateTags(int id, String tagsJson) =>
      (update(models)..where((t) => t.id.equals(id))).write(
        ModelsCompanion(tags: Value(tagsJson), updatedAt: Value(DateTime.now())),
      );

  Future<void> setActive(int id, bool active) =>
      (update(models)..where((t) => t.id.equals(id))).write(
        ModelsCompanion(isActive: Value(active), updatedAt: Value(DateTime.now())),
      );

  Future<int> removeByProvider(int providerId) =>
      (delete(models)..where((t) => t.providerId.equals(providerId))).go();
}
