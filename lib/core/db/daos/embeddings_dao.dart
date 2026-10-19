part of '../database.dart';

/// embeddings 表 DAO：向量按 entryId 主键覆盖写入；检索由 core/search 全量拉取。
@DriftAccessor(tables: [Embeddings])
class EmbeddingsDao extends DatabaseAccessor<AppDatabase> with _$EmbeddingsDaoMixin {
  EmbeddingsDao(super.db);

  Future<EntryEmbedding?> byEntry(int entryId) =>
      (select(embeddings)..where((t) => t.entryId.equals(entryId))).getSingleOrNull();

  /// 同一模型下的全部向量（个人库规模暴力扫描，docs/00 D1）。
  Future<List<EntryEmbedding>> allForModel(String model) =>
      (select(embeddings)..where((t) => t.model.equals(model))).get();

  /// 覆盖写入（entryId 为主键）。
  Future<void> upsert({
    required int entryId,
    required String model,
    required int dim,
    required Uint8List vector,
  }) =>
      into(embeddings).insertOnConflictUpdate(EmbeddingsCompanion.insert(
        entryId: Value(entryId),
        model: model,
        dim: dim,
        vector: vector,
      ));

  Future<int> removeForEntry(int entryId) =>
      (delete(embeddings)..where((t) => t.entryId.equals(entryId))).go();
}
