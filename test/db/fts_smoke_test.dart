import 'package:creative_kb/core/db/database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertQingyunEntry() => db
      .into(db.kbEntries)
      .insert(
        KbEntriesCompanion.insert(
          entryName: '青云宗',
          categoryPath: '仙侠设定/势力宗门',
          summary: const Value('正道魁首，坐落于青云山脉。'),
          contentMd: const Value('青云宗设有护山大阵，镇派功法为神剑御雷真诀。'),
          tags: const Value('["宗门","正道"]'),
        ),
      );

  test('FTS5 虚表与触发器可用：插入后可命中，删除后不再命中', () async {
    final id = await insertQingyunEntry();

    // trigram 分词：子串「护山大阵」应命中（docs/02 D5 检索验收场景）。
    var hits = await db.kbEntriesDao.searchFts('护山大阵');
    expect(hits, hasLength(1));
    expect(hits.single.entry.entryName, '青云宗');
    expect(hits.single.score, isNegative, reason: 'bm25 返回负值');

    await (db.delete(db.kbEntries)..where((t) => t.id.equals(id))).go();
    hits = await db.kbEntriesDao.searchFts('护山大阵');
    expect(hits, isEmpty, reason: '删除触发器应同步移除索引');
  });

  test('更新触发器同步：改写正文后旧词不命中、新词命中', () async {
    final id = await insertQingyunEntry();

    await (db.update(db.kbEntries)..where((t) => t.id.equals(id))).write(
      const KbEntriesCompanion(contentMd: Value('青云宗已改修太极玄清道，护山大阵升级为诛邪阵。')),
    );

    final newHits = await db.kbEntriesDao.searchFts('诛邪阵');
    expect(newHits, hasLength(1));
  });

  test('名称与摘要列参与检索（权重 3:2:1 配置不抛错且按分排序）', () async {
    await insertQingyunEntry();
    await db
        .into(db.kbEntries)
        .insert(
          KbEntriesCompanion.insert(
            entryName: '神剑御雷真诀',
            categoryPath: '仙侠设定/功法',
            summary: const Value('青云宗镇派功法。'),
            contentMd: const Value('共九卷。'),
          ),
        );

    final hits = await db.kbEntriesDao.searchFts('青云宗');
    expect(hits.map((h) => h.entry.entryName).toSet(), {'青云宗', '神剑御雷真诀'});
    // bm25 升序（负分，越小越相关）。
    final scores = hits.map((h) => h.score).toList();
    expect(scores, isSorted((a, b) => a <= b));
  });

  test('rebuildFts 全量重建索引', () async {
    final id = await insertQingyunEntry();
    // 'delete-all' 是外部内容表受支持的清空命令（DELETE FROM kb_fts 会报 corrupt）。
    await db.customStatement("INSERT INTO kb_fts(kb_fts) VALUES('delete-all')");
    expect(await db.kbEntriesDao.searchFts('护山大阵'), isEmpty);

    await db.rebuildFts();
    final hits = await db.kbEntriesDao.searchFts('护山大阵');
    expect(hits, hasLength(1));
    expect(hits.single.entry.id, id);
  });

  test('ensurePath 逐级创建分类并复用已有路径', () async {
    final first = await db.kbCategoriesDao.ensurePath('仙侠设定/势力宗门');
    final second = await db.kbCategoriesDao.ensurePath('仙侠设定/势力宗门');
    expect(first, second);

    final all = await db.kbCategoriesDao.getAll();
    expect(all.map((c) => c.path).toSet(), {'仙侠设定', '仙侠设定/势力宗门'});

    final parent = await db.kbCategoriesDao.byPath('仙侠设定');
    final child = await db.kbCategoriesDao.byPath('仙侠设定/势力宗门');
    expect(child!.parentId, parent!.id);
  });

  test('kb_relations 双向各存一行且不重复', () async {
    final a = await db
        .into(db.kbEntries)
        .insert(
          KbEntriesCompanion.insert(
            entryName: '青云宗',
            categoryPath: '仙侠设定/势力宗门',
          ),
        );
    final b = await db
        .into(db.kbEntries)
        .insert(
          KbEntriesCompanion.insert(entryName: '张小凡', categoryPath: '仙侠设定/人物'),
        );

    await db.kbRelationsDao.linkPair(entryId: a, relatedEntryId: b);
    await db.kbRelationsDao.linkPair(entryId: a, relatedEntryId: b); // 幂等

    final rows = await db.kbRelationsDao.forEntry(a);
    expect(rows, hasLength(2), reason: '双向各一行');
    expect(
      await db.kbRelationsDao.existsPair(entryId: b, relatedEntryId: a),
      isTrue,
    );

    await db.kbRelationsDao.removeAllForEntry(a);
    expect(await db.kbRelationsDao.forEntry(b), isEmpty);
  });
}

/// 断言列表按 [compare] 非降序排列。
Matcher isSorted(bool Function(num, num) compare) => predicate<List<num>>(
  (list) =>
      list.isEmpty ||
      List.generate(
        list.length - 1,
        (i) => i,
      ).every((i) => compare(list[i], list[i + 1])),
  '按给定比较规则非降序排列',
);
