import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/database.dart';

/// 入库/编辑的输入载体（UI 层与向导共用）。
class KbEntryInput {
  const KbEntryInput({
    required this.entryName,
    required this.categoryPath,
    this.tags = const <String>[],
    this.summary = '',
    this.contentMd = '',
    this.extra = const <String, Object?>{},
    this.related = const <String>[],
    this.source,
    this.credibility,
  });

  final String entryName;
  final String categoryPath;
  final List<String> tags;
  final String summary;
  final String contentMd;
  final Map<String, Object?> extra;

  /// 关联条目名（docs/02 D2：与库内/本批名称精确匹配建双向关系，未匹配保留展示「待创建」）。
  final List<String> related;
  final String? source;
  final Credibility? credibility;
}

class KbEntrySaveReport {
  const KbEntrySaveReport({
    required this.entryIds,
    required this.pendingRelated,
  });

  final List<int> entryIds;

  /// 未能匹配的关联：「条目名 → 待创建名」。
  final List<String> pendingRelated;
}

/// 条目写服务：入库 + 关联 + 删除连带清理（docs/02 D2/D4）。
/// FTS 由 tables.dart 的触发器同步，无需手动维护。
class KbEntryService {
  KbEntryService(this._db);

  final AppDatabase _db;

  /// 批量入库：逐级自动建分类；related 与「本批 + 库内」名称精确匹配建
  /// kb_relations 双向行；未匹配名称保留在 related JSON，并在报告返回。
  Future<KbEntrySaveReport> createEntries(List<KbEntryInput> inputs) async {
    final idsByName = <String, int>{};
    final pending = <String>[];
    final ids = <int>[];
    await _db.transaction(() async {
      for (final input in inputs) {
        final category = input.categoryPath.trim().isEmpty
            ? '未分类'
            : input.categoryPath.trim();
        await _db.kbCategoriesDao.ensurePath(category);
        final id = await _db.kbEntriesDao.add(
          KbEntriesCompanion.insert(
            entryName: input.entryName.trim(),
            categoryPath: category,
            tags: Value(jsonEncode(input.tags)),
            summary: Value(input.summary),
            contentMd: Value(input.contentMd),
            extra: Value(jsonEncode(input.extra)),
            related: Value(jsonEncode(input.related)),
            source: input.source == null
                ? const Value.absent()
                : Value(input.source),
            credibility: Value(input.credibility),
          ),
        );
        idsByName[input.entryName.trim()] = id;
        ids.add(id);
      }
      for (final input in inputs) {
        final id = idsByName[input.entryName.trim()]!;
        for (final name in input.related) {
          final otherId =
              idsByName[name] ?? (await _db.kbEntriesDao.byName(name))?.id;
          if (otherId == null || otherId == id) {
            if (otherId == null) {
              pending.add('${input.entryName.trim()} → $name');
            }
            continue;
          }
          await _db.kbRelationsDao.linkPair(
            entryId: id,
            relatedEntryId: otherId,
          );
        }
      }
    });
    return KbEntrySaveReport(entryIds: ids, pendingRelated: pending);
  }

  /// 编辑保存：覆盖行 + 按新 related 重建双向关联（原有关联先清再建）。
  /// 返回未能匹配的关联名。FTS 由更新触发器同步。
  Future<List<String>> updateEntry(
    KbEntry row, {
    required List<String> related,
  }) async {
    final pending = <String>[];
    await _db.transaction(() async {
      await _db.kbCategoriesDao.ensurePath(row.categoryPath);
      await _db.kbEntriesDao.updateRow(
        row.copyWith(related: jsonEncode(related), updatedAt: DateTime.now()),
      );
      await _db.kbRelationsDao.removeAllForEntry(row.id);
      for (final name in related) {
        final other = await _db.kbEntriesDao.byName(name);
        if (other == null || other.id == row.id) {
          if (other == null) pending.add(name);
          continue;
        }
        await _db.kbRelationsDao.linkPair(
          entryId: row.id,
          relatedEntryId: other.id,
        );
      }
    });
    return pending;
  }

  /// 删除条目：连带清理 relations 与 embeddings（docs/02 D4）；FTS 由删除触发器同步。
  Future<void> deleteEntry(int entryId) {
    return _db.transaction(() async {
      await _db.kbRelationsDao.removeAllForEntry(entryId);
      await _db.embeddingsDao.removeForEntry(entryId);
      await _db.kbEntriesDao.remove(entryId);
    });
  }

  /// 双向关联的对面条目列表（正向 + 反向合并去重）。
  Future<List<KbEntry>> relatedEntriesOf(int entryId) async {
    final rows = await _db.kbRelationsDao.forEntry(entryId);
    final otherIds = rows
        .map((r) => r.entryId == entryId ? r.relatedEntryId : r.entryId)
        .toSet();
    final result = <KbEntry>[];
    for (final id in otherIds) {
      final entry = await _db.kbEntriesDao.byId(id);
      if (entry != null) result.add(entry);
    }
    result.sort((a, b) => a.entryName.compareTo(b.entryName));
    return result;
  }

  /// related JSON 中尚未建立关系行的名称（「待创建」）。
  Future<List<String>> pendingRelatedNames(KbEntry entry) async {
    final linked = (await relatedEntriesOf(entry.id))
        .map((e) => e.entryName)
        .toSet();
    return decodeStringList(entry.related)
        .where((name) => name.trim().isNotEmpty && !linked.contains(name))
        .toSet()
        .toList();
  }
}

/// 解析 JSON 字符串数组字段（tags/related 等约定存原始 JSON 字符串）。
List<String> decodeStringList(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return [
        for (final item in decoded)
          if (item != null) '$item',
      ];
    }
  } catch (_) {
    // 损坏数据按空处理。
  }
  return const [];
}

/// 解析 JSON 对象字段（extra）。
Map<String, Object?> decodeJsonObject(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {
    // 损坏数据按空处理。
  }
  return <String, Object?>{};
}
