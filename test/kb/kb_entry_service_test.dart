import 'dart:convert';

import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/core/search/vector_index.dart';
import 'package:creative_kb/features/kb/services/kb_entry_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late KbEntryService service;

  setUp(() async {
    db = AppDatabase.inMemory();
    service = KbEntryService(db);
  });

  tearDown(() async {
    await db.close();
  });

  KbEntryInput input(
    String name, {
    String category = '仙侠设定/势力宗门',
    List<String> related = const [],
    String content = '',
  }) {
    return KbEntryInput(
      entryName: name,
      categoryPath: category,
      summary: '$name 的概述',
      contentMd: content.isEmpty ? '$name 的正文内容。' : content,
      tags: ['测试'],
      related: related,
      source: 'manual',
      credibility: Credibility.mid,
    );
  }

  test('批量入库：分类逐级自动创建，related 精确匹配建双向关联，未匹配留「待创建」', () async {
    await db.kbEntriesDao.add(
      KbEntriesCompanion.insert(entryName: '张小凡', categoryPath: '仙侠设定/人物'),
    );

    final report = await service.createEntries([
      input('青云宗', related: ['张小凡', '碧瑶']),
    ]);

    expect(report.entryIds, hasLength(1));
    final qingyun = (await db.kbEntriesDao.byName('青云宗'))!;

    // 分类树：父子两级都落库（docs/01 kb_categories）。
    expect(await db.kbCategoriesDao.byPath('仙侠设定'), isNotNull);
    expect(await db.kbCategoriesDao.byPath('仙侠设定/势力宗门'), isNotNull);

    // 双向关联各一行（docs/01 kb_relations）。
    final relations = await db.kbRelationsDao.forEntry(qingyun.id);
    expect(relations, hasLength(2));
    final zhang = (await db.kbEntriesDao.byName('张小凡'))!;
    expect(
      await db.kbRelationsDao.existsPair(
        entryId: zhang.id,
        relatedEntryId: qingyun.id,
      ),
      isTrue,
      reason: '反向也应有关系行',
    );

    // 未匹配名保留在 related JSON，并在报告中给出「待创建」。
    final relatedNames = jsonDecode(qingyun.related) as List;
    expect(relatedNames, contains('碧瑶'));
    expect(report.pendingRelated, contains('青云宗 → 碧瑶'));

    // 自身引用不建立关系行。
    await service.createEntries([
      input('自指条目', related: ['自指条目']),
    ]);
    final selfEntry = (await db.kbEntriesDao.byName('自指条目'))!;
    expect(await db.kbRelationsDao.forEntry(selfEntry.id), isEmpty);
  });

  test('同批条目互相关联：先全部落库再建边，不产生待创建', () async {
    final report = await service.createEntries([
      input('青云宗', related: ['龙首峰']),
      input('龙首峰', category: '仙侠设定/地名'),
    ]);
    expect(report.pendingRelated, isEmpty);

    final qingyun = (await db.kbEntriesDao.byName('青云宗'))!;
    final relations = await db.kbRelationsDao.forEntry(qingyun.id);
    expect(relations, hasLength(2));
    expect(
      (await service.relatedEntriesOf(qingyun.id)).map((e) => e.entryName),
      contains('龙首峰'),
    );
  });

  test('删除条目连带清理 relations / embeddings / FTS（docs/02 D4）', () async {
    final report = await service.createEntries([
      input('青云宗', content: '护山大阵笼罩山门。', related: ['张小凡']),
      input('张小凡', category: '仙侠设定/人物'),
    ]);
    final qingyunId = report.entryIds.first;
    await db.embeddingsDao.upsert(
      entryId: qingyunId,
      model: 'test-embed',
      dim: 2,
      vector: VectorCodec.encodeFloat32Le(const [1, 0]),
    );

    expect((await service.relatedEntriesOf(qingyunId)), hasLength(1));
    expect(await db.kbEntriesDao.searchFts('护山大阵'), hasLength(1));

    await service.deleteEntry(qingyunId);

    expect(await db.kbEntriesDao.byId(qingyunId), isNull);
    expect(await db.kbRelationsDao.forEntry(qingyunId), isEmpty);
    expect(await db.embeddingsDao.byEntry(qingyunId), isNull);
    expect(
      await db.kbEntriesDao.searchFts('护山大阵'),
      isEmpty,
      reason: 'FTS 由删除触发器同步',
    );

    final zhang = (await db.kbEntriesDao.byName('张小凡'))!;
    expect(
      await service.relatedEntriesOf(zhang.id),
      isEmpty,
      reason: '对侧关联一并清理',
    );
  });

  test('编辑保存：按新 related 重建关联，正文改动后 FTS 同步', () async {
    await service.createEntries([
      input('青云宗', content: '旧阵法早已废弃。'),
      input('张小凡', category: '仙侠设定/人物'),
      input('碧瑶', category: '仙侠设定/人物'),
    ]);
    final qingyun = (await db.kbEntriesDao.byName('青云宗'))!;

    final pending1 = await service.updateEntry(
      qingyun.copyWith(contentMd: '诛仙剑阵重现人间。'),
      related: ['张小凡', '碧瑶'],
    );
    expect(pending1, isEmpty);
    var relations = await db.kbRelationsDao.forEntry(qingyun.id);
    expect(relations, hasLength(4), reason: '两组双向关联');
    expect(await db.kbEntriesDao.searchFts('诛仙剑阵'), hasLength(1));
    expect(await db.kbEntriesDao.searchFts('旧阵法早已废弃'), isEmpty);

    final pending2 = await service.updateEntry(
      (await db.kbEntriesDao.byName('青云宗'))!,
      related: ['碧瑶'],
    );
    expect(pending2, isEmpty);
    relations = await db.kbRelationsDao.forEntry(qingyun.id);
    expect(relations, hasLength(2), reason: '与张小凡的关联被重建移除');
    final zhang = (await db.kbEntriesDao.byName('张小凡'))!;
    expect(await db.kbRelationsDao.forEntry(zhang.id), isEmpty);
  });

  test('pendingRelatedNames：related JSON 中未建边的名称（含对端已删除的情况）', () async {
    await service.createEntries([
      input('青云宗', related: ['碧瑶']),
    ]);
    final qingyun = (await db.kbEntriesDao.byName('青云宗'))!;
    expect(await service.pendingRelatedNames(qingyun), ['碧瑶']);

    // 碧瑶入库后自动变为已关联（通过再建边）。
    await service.createEntries([input('碧瑶', category: '仙侠设定/人物')]);
    await db.kbRelationsDao.linkPair(
      entryId: qingyun.id,
      relatedEntryId: (await db.kbEntriesDao.byName('碧瑶'))!.id,
    );
    expect(await service.pendingRelatedNames(qingyun), isEmpty);
  });

  test('allEntryNames 只返回条目名列（入库提示词用，大库不整表读大字段）', () async {
    await service.createEntries([input('张小凡'), input('碧瑶')]);
    final names = await db.kbEntriesDao.allEntryNames();
    expect(names.toSet(), {'张小凡', '碧瑶'});
  });
}
