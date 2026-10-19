import 'package:drift/drift.dart';

import '../db/database.dart';
import 'vector_index.dart';

/// FTS 权重（docs/02 D4）：score = 0.6 * FTS归一 + 0.6 * 余弦相似度。
const double kKbFtsWeight = 0.6;
const double kKbVectorWeight = 0.6;

/// kb_fts 使用 trigram 分词（tables.dart 约定）：≥3 字符才能 MATCH，
/// 短词由检索层回退 LIKE（本文件职责）。
class FtsQueryPlan {
  const FtsQueryPlan({this.matchQuery, this.likeTokens = const <String>[]});

  /// FTS5 MATCH 表达式；无长词时为 null（走 LIKE 路径）。
  final String? matchQuery;

  /// 短词：在 FTS 命中结果上做包含性后过滤；无长词时用于全表 LIKE 扫描。
  final List<String> likeTokens;

  bool get isEmpty => matchQuery == null && likeTokens.isEmpty;
}

abstract final class KbFtsQueryBuilder {
  /// 按空白分词；≥3 个 Unicode 字符的词进 MATCH（AND 语义，双引号转义），
  /// 其余进 LIKE 后过滤词表。
  static FtsQueryPlan build(String query) {
    final tokens = query
        .split(RegExp(r'\s+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    final matchTokens = <String>[];
    final likeTokens = <String>[];
    for (final token in tokens) {
      (token.runes.length >= 3 ? matchTokens : likeTokens).add(token);
    }
    final matchQuery = matchTokens.isEmpty
        ? null
        : matchTokens.map((t) => '"${t.replaceAll('"', '""')}"').join(' ');
    return FtsQueryPlan(matchQuery: matchQuery, likeTokens: likeTokens);
  }
}

/// 语义检索侧配置：嵌入模型名 + 查询向量化执行器（由调用方接 KbAiGateway）。
class HybridEmbedding {
  const HybridEmbedding({required this.model, required this.embed});

  final String model;
  final Future<List<double>> Function(String text) embed;
}

class HybridSearchHit {
  const HybridSearchHit({
    required this.entry,
    required this.ftsScore,
    required this.vectorScore,
    required this.score,
  });

  final KbEntry entry;

  /// FTS 归一分（min-max 归一到 [0,1]，未命中为 0）。
  final double ftsScore;

  /// 与查询向量的余弦相似度（未参与语义检索为 0）。
  final double vectorScore;

  /// 综合分：0.6 * ftsScore + 0.6 * vectorScore。
  final double score;
}

class HybridSearchResult {
  const HybridSearchResult({
    required this.hits,
    required this.semanticUsed,
    this.notice,
  });

  final List<HybridSearchHit> hits;

  /// true = 本次检索参与了语义（余弦）排序。
  final bool semanticUsed;

  /// 降级/失败提示（UI 直接展示）。
  final String? notice;
}

/// 关键词 + 语义混合检索（docs/02 D4）。
/// 未配置嵌入模型或向量化失败时自动降级为纯 FTS，并给出提示（docs/00 D7）。
class HybridSearchService {
  HybridSearchService(this._db);

  final AppDatabase _db;

  Future<HybridSearchResult> search(
    String query, {
    HybridEmbedding? semantic,
    int limit = 30,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const HybridSearchResult(hits: [], semanticUsed: false);
    }

    // 1) 关键词侧：FTS（长词 AND）+ 短词 LIKE 过滤 / 纯 LIKE 扫描。
    final plan = KbFtsQueryBuilder.build(trimmed);
    final ftsRaw = <int, double>{};
    var candidates = <KbEntry>[];
    if (plan.matchQuery != null) {
      final scored = await _matchFts(plan.matchQuery!, limit: limit);
      ftsRaw.addEntries([for (final e in scored) MapEntry(e.$1.id, e.$2)]);
      candidates = [for (final e in scored) e.$1];
    } else if (plan.likeTokens.isNotEmpty) {
      candidates = await _likeScan(plan.likeTokens, limit: limit);
      for (final entry in candidates) {
        ftsRaw[entry.id] = -1.0; // 均匀占位分：归一后全为 1
      }
    }
    // 短词后过滤（长词命中里再按短词包含筛选）。
    if (plan.matchQuery != null && plan.likeTokens.isNotEmpty) {
      final kept = candidates
          .where(
            (e) => plan.likeTokens.every(
              (t) =>
                  e.entryName.contains(t) ||
                  e.summary.contains(t) ||
                  e.contentMd.contains(t),
            ),
          )
          .toList();
      final keptIds = kept.map((e) => e.id).toSet();
      ftsRaw.removeWhere((id, _) => !keptIds.contains(id));
      candidates = kept;
    }

    // 2) 语义侧：查询向量化后与库内向量余弦（未配置/失败降级）。
    final cosine = <int, double>{};
    var semanticUsed = false;
    String? notice;
    if (semantic == null) {
      notice = '未配置嵌入模型，当前为纯关键词检索；可在设置中配置嵌入模型后开启语义检索';
    } else {
      try {
        final queryVector = await semantic.embed(trimmed);
        if (queryVector.isNotEmpty) {
          final rows = await _db.embeddingsDao.allForModel(semantic.model);
          final vectors = <int, List<double>>{
            for (final row in rows)
              row.entryId: VectorCodec.decodeFloat32Le(
                row.vector,
                dim: row.dim,
              ),
          };
          for (final entry in vectors.keys) {
            cosine[entry] = cosineSimilarity(queryVector, vectors[entry]!);
          }
          semanticUsed = true;
        }
      } catch (_) {
        semanticUsed = false;
        notice = '语义检索失败，已降级为关键词检索';
      }
    }

    // 3) 合并排序：0.6 * FTS归一 + 0.6 * cos。
    final entries = <int, KbEntry>{for (final e in candidates) e.id: e};
    final missingIds = cosine.keys
        .where((id) => !entries.containsKey(id))
        .toList();
    if (missingIds.isNotEmpty) {
      final rows = await (_db.select(
        _db.kbEntries,
      )..where((t) => t.id.isIn(missingIds))).get();
      entries.addEntries([for (final e in rows) MapEntry(e.id, e)]);
    }
    final hits = mergeScores(
      ftsRaw: ftsRaw,
      cosine: cosine,
      entries: entries,
    ).take(limit).toList();
    return HybridSearchResult(
      hits: hits,
      semanticUsed: semanticUsed,
      notice: notice,
    );
  }

  /// bm25 加权检索，返回 (条目, bm25 原始负分)，按相关性升序。
  Future<List<(KbEntry, double)>> _matchFts(
    String matchQuery, {
    required int limit,
  }) async {
    final rows = await _db
        .customSelect(
          'SELECT e.id AS e_id, ${KbFts.bm25Weighted} AS score '
          'FROM kb_fts JOIN kb_entries AS e ON e.id = kb_fts.rowid '
          'WHERE kb_fts MATCH ? ORDER BY score LIMIT ?',
          variables: [Variable.withString(matchQuery), Variable.withInt(limit)],
          readsFrom: {_db.kbEntries},
        )
        .get();
    final result = <(KbEntry, double)>[];
    for (final row in rows) {
      final id = row.read<int>('e_id');
      final score = row.data['score'];
      final entry = await _db.kbEntriesDao.byId(id);
      if (entry != null && score is num) {
        result.add((entry, score.toDouble()));
      }
    }
    return result;
  }

  /// 短词全表 LIKE 扫描（trigram 无法 MATCH <3 字符查询时的回退）。
  Future<List<KbEntry>> _likeScan(
    List<String> tokens, {
    required int limit,
  }) async {
    Expression<bool> conditions(KbEntries t) {
      Expression<bool> single(String token) =>
          t.entryName.like('%$token%') |
          t.summary.like('%$token%') |
          t.contentMd.like('%$token%');
      Expression<bool>? combined;
      for (final token in tokens) {
        combined = combined == null ? single(token) : combined & single(token);
      }
      return combined!;
    }

    return (_db.select(_db.kbEntries)
          ..where(conditions)
          ..limit(limit))
        .get();
  }

  /// 纯函数合并：FTS min-max 归一 + 余弦，score = 0.6*fts归一 + 0.6*cos（docs/02 D4）。
  /// 便于对已知输入做手算断言。
  static List<HybridSearchHit> mergeScores({
    required Map<int, double> ftsRaw,
    required Map<int, double> cosine,
    required Map<int, KbEntry> entries,
  }) {
    final ftsNorm = _minMaxNormalize(ftsRaw);
    final ids = <int>{
      ...ftsNorm.keys,
      ...cosine.keys,
    }.where(entries.containsKey);
    final hits = <HybridSearchHit>[];
    for (final id in ids) {
      final fts = ftsNorm[id] ?? 0;
      final cos = cosine[id] ?? 0;
      hits.add(
        HybridSearchHit(
          entry: entries[id]!,
          ftsScore: fts,
          vectorScore: cos,
          score: kKbFtsWeight * fts + kKbVectorWeight * cos,
        ),
      );
    }
    hits.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final byFts = b.ftsScore.compareTo(a.ftsScore);
      if (byFts != 0) return byFts;
      return a.entry.entryName.compareTo(b.entry.entryName);
    });
    return hits;
  }

  /// bm25 为负值、越小越相关：min-max 归一后最相关 = 1；全相等（如 LIKE 扫描）= 全 1。
  static Map<int, double> _minMaxNormalize(Map<int, double> raw) {
    if (raw.isEmpty) return const {};
    var min = 0.0, max = 0.0;
    var first = true;
    for (final v in raw.values) {
      if (first) {
        min = max = v;
        first = false;
      } else {
        if (v < min) min = v;
        if (v > max) max = v;
      }
    }
    if (max == min) return {for (final id in raw.keys) id: 1.0};
    return {for (final e in raw.entries) e.key: (max - e.value) / (max - min)};
  }
}
