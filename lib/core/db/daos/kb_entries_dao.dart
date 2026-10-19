part of '../database.dart';

/// FTS 命中结果：条目 + bm25 原始分（负值，越小越相关）。
class FtsSearchHit {
  const FtsSearchHit({required this.entry, required this.score});

  final KbEntry entry;
  final double score;
}

/// kb_entries 表 DAO（含 FTS 加权检索）。
@DriftAccessor(tables: [KbEntries])
class KbEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$KbEntriesDaoMixin {
  KbEntriesDao(super.db);

  Stream<List<KbEntry>> watchAll() =>
      (select(kbEntries)..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
          .watch();

  Future<List<KbEntry>> getAll() => select(kbEntries).get();

  Future<KbEntry?> byId(int id) =>
      (select(kbEntries)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<KbEntry?> byName(String entryName) => (select(
    kbEntries,
  )..where((t) => t.entryName.equals(entryName))).getSingleOrNull();

  /// 某分类（不含子级）下的条目。
  Future<List<KbEntry>> byCategory(String categoryPath) => (select(
    kbEntries,
  )..where((t) => t.categoryPath.equals(categoryPath))).get();

  /// 某分类及其子分类下的条目（path 前缀匹配）。
  Future<List<KbEntry>> byCategorySubtree(String categoryPath) =>
      (select(kbEntries)..where(
            (t) =>
                t.categoryPath.equals(categoryPath) |
                t.categoryPath.like('$categoryPath/%'),
          ))
          .get();

  /// 各分类条目计数（分类树节点角标，docs/02 D4）。
  Future<Map<String, int>> countByCategory() async {
    final count = kbEntries.id.count();
    final query = selectOnly(kbEntries)
      ..addColumns([kbEntries.categoryPath, count])
      ..groupBy([kbEntries.categoryPath]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.read<String>(kbEntries.categoryPath)!: row.read<int>(count) ?? 0,
    };
  }

  /// FTS 加权检索：name 3 : summary 2 : content 1，bm25 升序（docs/02 D4）。
  /// [query] 为 FTS5 MATCH 语法（trigram 分词，建议 ≥3 字符）。
  Future<List<FtsSearchHit>> searchFts(String query, {int limit = 50}) async {
    final rows = await customSelect(
      'SELECT e.id AS e_id, ${KbFts.bm25Weighted} AS score '
      'FROM kb_fts JOIN kb_entries AS e ON e.id = kb_fts.rowid '
      'WHERE kb_fts MATCH ? '
      'ORDER BY score LIMIT ?',
      variables: [Variable.withString(query), Variable.withInt(limit)],
      readsFrom: {kbEntries},
    ).get();
    if (rows.isEmpty) return const [];
    final scores = <int, double>{};
    for (final row in rows) {
      final score = row.data['score'];
      if (score is num) scores[row.read<int>('e_id')] = score.toDouble();
    }
    final entries = await (select(
      kbEntries,
    )..where((t) => t.id.isIn(scores.keys))).get();
    final byId = {for (final e in entries) e.id: e};
    return [
      for (final id in scores.keys)
        if (byId[id] != null)
          FtsSearchHit(entry: byId[id]!, score: scores[id]!),
    ];
  }

  Future<int> add(KbEntriesCompanion entry) => into(kbEntries).insert(entry);

  Future<bool> updateRow(KbEntry row) => update(kbEntries).replace(row);

  /// 删除条目；关联与向量由调用方（或事务）联动清理，FTS 由触发器同步。
  Future<int> remove(int id) =>
      (delete(kbEntries)..where((t) => t.id.equals(id))).go();
}
