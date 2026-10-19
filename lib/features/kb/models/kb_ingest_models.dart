import 'dart:convert';

/// 入库任务（docs/02 D2）AI 输出契约的数据模型与解析校验。
/// 契约：`{"cleaned":str,"proposedCategory":str,"proposedSchemaId":str,
///        "entries":[{"entryName":str,...通用字段+扩展字段,
///                    "relatedEntries":[str](D3 关联建议)}]}`

/// 单条解析后的候选条目（尚未入库）。
class KbIngestEntry {
  const KbIngestEntry({
    required this.entryName,
    this.categoryPath,
    this.summary = '',
    this.contentMd = '',
    this.tags = const <String>[],
    this.related = const <String>[],
    this.credibility,
    this.extra = const <String, Object?>{},
  });

  final String entryName;

  /// 逐条目可选分类（契约未定义；缺省回落 proposedCategory）。
  final String? categoryPath;
  final String summary;
  final String contentMd;
  final List<String> tags;

  /// D3 关联建议：只允许引用库内确定存在的名称。
  final List<String> related;
  final String? credibility;
  final Map<String, Object?> extra;
}

class KbIngestResult {
  const KbIngestResult({
    required this.cleaned,
    required this.proposedCategory,
    required this.proposedSchemaId,
    required this.entries,
  });

  final String cleaned;
  final String proposedCategory;
  final String proposedSchemaId;
  final List<KbIngestEntry> entries;
}

/// 解析/校验失败（重试时把 [issues] 拼回提示词；耗尽后原样展示给用户）。
class KbIngestValidationException implements Exception {
  const KbIngestValidationException(this.issues);

  final List<String> issues;

  String get message => '输出不符合入库契约：${issues.join('；')}';

  @override
  String toString() => message;
}

abstract final class KbIngestParser {
  /// 输出 JSON 的已知条目级 key；其余键归入扩展字段 extra。
  static const _knownEntryKeys = <String>[
    'entryName',
    'category',
    'categoryPath',
    'summary',
    'contentMd',
    'tags',
    'relatedEntries',
    'related',
    'credibility',
  ];

  /// 剥离 ```json 围栏 → jsonDecode → 按契约校验（docs/01 第五节）。
  /// 任何问题抛 [KbIngestValidationException]。
  static KbIngestResult parse(String raw) {
    final issues = <String>[];
    Object? decoded;
    try {
      decoded = _decodeJson(raw);
    } on FormatException {
      throw const KbIngestValidationException(['输出不是合法 JSON']);
    }
    if (decoded is! Map<String, dynamic>) {
      throw const KbIngestValidationException(['顶层必须是 JSON 对象']);
    }

    final cleaned = _asString(decoded['cleaned']) ?? '';
    if (cleaned.isEmpty) issues.add('缺少 cleaned（清洗后正文）');
    var proposedCategory = _asString(decoded['proposedCategory']) ?? '';
    if (proposedCategory.isEmpty) proposedCategory = '未分类';
    var proposedSchemaId = _asString(decoded['proposedSchemaId']) ?? '';
    if (proposedSchemaId.isEmpty) proposedSchemaId = 'general';

    final entriesRaw = decoded['entries'];
    if (entriesRaw is! List || entriesRaw.isEmpty) {
      issues.add('entries 必须是非空数组');
      throw KbIngestValidationException(issues);
    }

    final entries = <KbIngestEntry>[];
    for (var i = 0; i < entriesRaw.length; i++) {
      final item = entriesRaw[i];
      if (item is! Map<String, dynamic>) {
        issues.add('entries[$i] 必须是对象');
        continue;
      }
      final name = _asString(item['entryName']) ?? '';
      if (name.isEmpty) {
        issues.add('entries[$i] 缺少 entryName');
        continue;
      }
      var category =
          _asString(item['categoryPath']) ?? _asString(item['category']);
      final extra = <String, Object?>{};
      item.forEach((key, value) {
        if (!_knownEntryKeys.contains(key)) extra[key] = value;
      });
      final tags = _asStringList(item['tags']);
      final related = _asStringList(item['relatedEntries'] ?? item['related']);
      entries.add(
        KbIngestEntry(
          entryName: name,
          categoryPath: (category == null || category.isEmpty)
              ? null
              : category,
          summary: _asString(item['summary']) ?? '',
          contentMd: _asString(item['contentMd']) ?? '',
          tags: tags,
          related: related,
          credibility: _normalizeCredibility(item['credibility']),
          extra: extra,
        ),
      );
    }
    if (issues.isNotEmpty) throw KbIngestValidationException(issues);
    return KbIngestResult(
      cleaned: cleaned,
      proposedCategory: proposedCategory,
      proposedSchemaId: proposedSchemaId,
      entries: entries,
    );
  }

  /// 剥离 ```json 围栏；失败时兜底截取首个 { 到最后一个 } 再试。
  static Object? _decodeJson(String raw) {
    var text = raw.trim();
    final fence = RegExp(r'^```[a-zA-Z]*\s*([\s\S]*?)\s*```$').firstMatch(text);
    if (fence != null) text = fence.group(1)!.trim();
    try {
      return jsonDecode(text);
    } on FormatException {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start >= 0 && end > start) {
        return jsonDecode(text.substring(start, end + 1));
      }
      rethrow;
    }
  }

  static String? _asString(Object? value) =>
      value == null ? null : (value is String ? value : '$value');

  static List<String> _asStringList(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item != null) '$item',
    ];
  }

  static String? _normalizeCredibility(Object? value) {
    final text = _asString(value)?.trim().toLowerCase();
    if (text == 'high' || text == 'mid' || text == 'low') return text;
    return null;
  }
}
