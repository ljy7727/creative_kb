part of '../database.dart';

/// kb_relations 表 DAO：双向链接，每方向各存一行（docs/01 第三节）。
@DriftAccessor(tables: [KbRelations])
class KbRelationsDao extends DatabaseAccessor<AppDatabase>
    with _$KbRelationsDaoMixin {
  KbRelationsDao(super.db);

  /// 与某条目相关的全部关系行（正向 + 反向）。
  Future<List<KbRelation>> forEntry(int entryId) =>
      (select(kbRelations)..where(
            (t) => t.entryId.equals(entryId) | t.relatedEntryId.equals(entryId),
          ))
          .get();

  Future<bool> existsPair({
    required int entryId,
    required int relatedEntryId,
  }) async {
    final found =
        await (select(kbRelations)..where(
              (t) =>
                  t.entryId.equals(entryId) &
                  t.relatedEntryId.equals(relatedEntryId),
            ))
            .getSingleOrNull();
    return found != null;
  }

  /// 建立双向关联，已存在则跳过。
  Future<void> linkPair({
    required int entryId,
    required int relatedEntryId,
  }) async {
    if (entryId == relatedEntryId) return;
    if (await existsPair(entryId: entryId, relatedEntryId: relatedEntryId)) {
      return;
    }
    await batch((b) {
      b.insertAll(kbRelations, [
        KbRelationsCompanion.insert(
          entryId: entryId,
          relatedEntryId: relatedEntryId,
        ),
        KbRelationsCompanion.insert(
          entryId: relatedEntryId,
          relatedEntryId: entryId,
        ),
      ]);
    });
  }

  /// 删除条目时清理其全部关系行。
  Future<int> removeAllForEntry(int entryId) =>
      (delete(kbRelations)..where(
            (t) => t.entryId.equals(entryId) | t.relatedEntryId.equals(entryId),
          ))
          .go();
}
