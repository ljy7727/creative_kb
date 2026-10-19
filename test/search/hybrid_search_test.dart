import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/core/search/hybrid_search.dart';
import 'package:creative_kb/core/search/vector_index.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late HybridSearchService service;

  setUp(() async {
    db = AppDatabase.inMemory();
    service = HybridSearchService(db);

    await db.kbEntriesDao.add(
      KbEntriesCompanion.insert(
        entryName: '青云宗',
        categoryPath: '仙侠设定/势力宗门',
        summary: const Value('正道魁首，坐落于青云山脉的宗门。'),
        contentMd: const Value('青云宗设有护山大阵，镇派功法为神剑御雷真诀。'),
      ),
    );
    await db.kbEntriesDao.add(
      KbEntriesCompanion.insert(
        entryName: '户部尚书',
        categoryPath: '历史设定/中央官职',
        summary: const Value('唐朝三省六部之一的长官。'),
        contentMd: const Value('尚书省下辖六部，户部掌天下土地与赋税，正三品。'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('KbFtsQueryBuilder（trigram ≥3 字符约定）', () {
    test('长词进 MATCH 并做双引号转义，短词进 LIKE 后过滤', () {
      final plan = KbFtsQueryBuilder.build('宗门 护山"阵');
      expect(plan.matchQuery, '"护山""阵"');
      expect(plan.likeTokens, ['宗门']);

      final likeOnly = KbFtsQueryBuilder.build('尚书');
      expect(likeOnly.matchQuery, isNull);
      expect(likeOnly.likeTokens, ['尚书']);
    });

    test('空串计划为空', () {
      expect(KbFtsQueryBuilder.build('   ').isEmpty, isTrue);
    });
  });

  group('HybridSearchService（内存库）', () {
    test('纯 FTS：青云宗示例「护山大阵」命中，单命中归一为 1，给出降级提示', () async {
      final result = await service.search('护山大阵');
      expect(result.hits, hasLength(1));
      expect(result.hits.single.entry.entryName, '青云宗');
      expect(result.semanticUsed, isFalse);
      expect(result.notice, contains('未配置嵌入模型'));
      expect(result.hits.single.ftsScore, closeTo(1.0, 1e-9));
      // score = 0.6 * fts归一 + 0.6 * cos（无语义侧为 0）。
      expect(result.hits.single.score, closeTo(0.6, 1e-9));
    });

    test('短词回退 LIKE：两字词「宗门」「尚书」分别命中', () async {
      final zongmen = await service.search('宗门');
      expect(zongmen.hits.map((h) => h.entry.entryName), contains('青云宗'));

      final shangshu = await service.search('尚书');
      expect(shangshu.hits.map((h) => h.entry.entryName), contains('户部尚书'));
    });

    test('多词查询「宗门 护山大阵」= 长词 FTS + 短词后过滤，只留同时满足者', () async {
      final result = await service.search('宗门 护山大阵');
      final names = result.hits.map((h) => h.entry.entryName).toSet();
      expect(names, contains('青云宗'));
      expect(names, isNot(contains('户部尚书')), reason: '不含「宗门」应被短词后过滤');
    });

    test('空查询返回空结果', () async {
      final result = await service.search('   ');
      expect(result.hits, isEmpty);
      expect(result.semanticUsed, isFalse);
    });

    test('降级路径：查询向量化抛异常时仍返回 FTS 结果并提示降级', () async {
      final result = await service.search(
        '护山大阵',
        semantic: HybridEmbedding(
          model: 'test-embed',
          embed: (text) async {
            throw Exception('embed service down');
          },
        ),
      );
      expect(result.hits, hasLength(1));
      expect(result.hits.single.entry.entryName, '青云宗');
      expect(result.semanticUsed, isFalse);
      expect(result.notice, contains('降级'));
    });

    test('混合排序：score = 0.6*fts归一 + 0.6*cos，纯向量命中也进入结果', () async {
      final lingjian = await db.kbEntriesDao.add(
        KbEntriesCompanion.insert(
          entryName: '灵剑',
          categoryPath: '仙侠设定/仙侠宝物',
          contentMd: const Value('灵剑飞剑，剑意凌厉。'),
        ),
      );
      final miji = await db.kbEntriesDao.add(
        KbEntriesCompanion.insert(
          entryName: '秘籍',
          categoryPath: '仙侠设定/功法',
          contentMd: const Value('上古秘籍，记载功法。'),
        ),
      );
      await db.embeddingsDao.upsert(
        entryId: lingjian,
        model: 'test-embed',
        dim: 2,
        vector: VectorCodec.encodeFloat32Le(const [1, 0]),
      );
      await db.embeddingsDao.upsert(
        entryId: miji,
        model: 'test-embed',
        dim: 2,
        vector: VectorCodec.encodeFloat32Le(const [0, 1]),
      );

      final result = await service.search(
        '灵剑飞剑',
        semantic: HybridEmbedding(
          model: 'test-embed',
          embed: (text) async => const [1, 0],
        ),
      );
      expect(result.semanticUsed, isTrue);
      expect(result.notice, isNull, reason: '语义可用时不应提示降级');

      final byName = {for (final hit in result.hits) hit.entry.entryName: hit};
      final lingjianHit = byName['灵剑']!;
      final mijiHit = byName['秘籍']!;
      // 灵剑：fts归一=1，cos=1 → 0.6 + 0.6 = 1.2；秘籍：fts=0，cos=0 → 0。
      expect(lingjianHit.score, closeTo(1.2, 1e-9));
      expect(mijiHit.score, closeTo(0.0, 1e-9));
      expect(result.hits.first.entry.entryName, '灵剑');
    });
  });

  group('mergeScores 纯函数（手算断言）', () {
    test('min-max 归一 + 0.6/0.6 合成，按分排序', () {
      final e1 = _entry(1, '甲');
      final e2 = _entry(2, '乙');
      final e3 = _entry(3, '丙');
      // bm25 负分、越负越相关（FTS5 语义）：乙 -6 → 归一 1；甲 -2 → 归一 0；丙仅语义命中。
      final hits = HybridSearchService.mergeScores(
        ftsRaw: {1: -2.0, 2: -6.0},
        cosine: {1: 0.5, 3: 0.9},
        entries: {1: e1, 2: e2, 3: e3},
      );
      expect(hits, hasLength(3));
      final scores = {for (final hit in hits) hit.entry.entryName: hit.score};
      // 甲：0.6*0 + 0.6*0.5 = 0.3；乙：0.6*1 = 0.6；丙：0.6*0.9 = 0.54。
      expect(scores['甲'], closeTo(0.3, 1e-9));
      expect(scores['乙'], closeTo(0.6, 1e-9));
      expect(scores['丙'], closeTo(0.54, 1e-9));
      expect(hits.map((h) => h.entry.entryName).toList(), ['乙', '丙', '甲']);
    });

    test('全相等分（LIKE 扫描占位）归一后全为 1', () {
      final hits = HybridSearchService.mergeScores(
        ftsRaw: {1: -1.0, 2: -1.0},
        cosine: const {},
        entries: {1: _entry(1, '甲'), 2: _entry(2, '乙')},
      );
      expect(hits.every((h) => h.ftsScore == 1.0), isTrue);
      expect(hits.every((h) => (h.score - 0.6).abs() < 1e-9), isTrue);
    });
  });
}

KbEntry _entry(int id, String name) {
  final now = DateTime(2026, 1, 1);
  return KbEntry(
    id: id,
    entryName: name,
    categoryPath: '测试',
    tags: '[]',
    summary: '',
    contentMd: '',
    extra: '{}',
    related: '[]',
    createdAt: now,
    updatedAt: now,
  );
}
