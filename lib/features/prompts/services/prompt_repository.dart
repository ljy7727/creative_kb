import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../models/prompt_models.dart';

/// 模块C 数据访问封装：prompts 与 prompt_versions 的一致性维护（首版本、
/// 指针前移、回滚、级联删除）都在本类完成，页面不得绕过它直写两表。
class PromptRepository {
  PromptRepository(this._db);

  final AppDatabase _db;

  PromptsDao get _prompts => _db.promptsDao;
  PromptVersionsDao get _versions => _db.promptVersionsDao;

  Stream<List<Prompt>> watchAll() => _prompts.watchAll();

  Future<Prompt?> byId(int promptId) => _prompts.byId(promptId);

  /// 详情页单条流；删除后发出 null。
  Stream<Prompt?> watchById(int promptId) => (_db.select(
    _db.prompts,
  )..where((t) => t.id.equals(promptId))).watchSingleOrNull();

  /// 版本历史，新版本在前。
  Stream<List<PromptVersion>> watchVersions(int promptId) =>
      (_db.select(_db.promptVersions)
            ..where((t) => t.promptId.equals(promptId))
            ..orderBy([(t) => OrderingTerm.desc(t.id)]))
          .watch();

  /// 列表流：类型 / 分类 / 关键词（LIKE title|body，骨架 DAO 的检索方式）联动。
  /// drift 的 where() 只允许调用一次，条件在此先合并为单个表达式。
  Stream<List<Prompt>> watchFiltered({
    PromptType? type,
    String? category,
    String keyword = '',
  }) {
    final table = _db.prompts;
    Expression<bool>? condition;
    if (type != null) condition = table.type.equalsValue(type);
    if (category != null && category.isNotEmpty) {
      final categoryCondition = table.category.equals(category);
      condition = condition == null
          ? categoryCondition
          : condition & categoryCondition;
    }
    final trimmed = keyword.trim();
    if (trimmed.isNotEmpty) {
      final pattern = '%$trimmed%';
      final keywordCondition =
          table.title.like(pattern) | table.body.like(pattern);
      condition = condition == null
          ? keywordCondition
          : condition & keywordCondition;
    }

    final query = _db.select(table);
    // condition 非 effectively final，需快照后才能在闭包内享受非空提升。
    final Expression<bool>? filter = condition;
    if (filter != null) query.where((t) => filter);
    query.orderBy([
      (t) => OrderingTerm.desc(t.createdAt),
      (t) => OrderingTerm.desc(t.id),
    ]);
    return query.watch();
  }

  /// 已用分类去重列表（空串与 null 视为「未分类」，不进筛选 chips）。
  Stream<List<String>> watchCategories() {
    final query = _db.selectOnly(_db.prompts)
      ..addColumns([_db.prompts.category])
      ..where(_db.prompts.category.isNotNull())
      ..groupBy([_db.prompts.category]);
    return query.watch().map((rows) {
      return [
        for (final row in rows)
          if (row.read(_db.prompts.category)?.isNotEmpty ?? false)
            row.read(_db.prompts.category)!,
      ]..sort();
    });
  }

  /// 新建条目并写入首版本，currentVersionId 指向首版本。返回条目 id。
  Future<int> create({
    required String title,
    required PromptType type,
    required String body,
    String? category,
    List<PromptVariable> variables = const [],
  }) {
    return _db.transaction(() async {
      final promptId = await _prompts.add(
        PromptsCompanion.insert(
          title: title,
          type: type,
          body: body,
          variables: Value(PromptVariable.encode(variables)),
          category: Value(category),
        ),
      );
      final versionId = await _versions.add(
        PromptVersionsCompanion.insert(
          promptId: promptId,
          body: body,
          note: const Value('初始版本'),
        ),
      );
      await _prompts.setCurrentVersion(promptId, versionId);
      return promptId;
    });
  }

  /// 保存新版本（定向优化/手动编辑/变量标注）：prompts.body 同步、指针前移；
  /// [variables] 传 null 表示不修改变量表。
  Future<void> saveNewVersion({
    required int promptId,
    required String body,
    String? note,
    List<PromptVariable>? variables,
  }) {
    return _db.transaction(() async {
      final versionId = await _versions.add(
        PromptVersionsCompanion.insert(
          promptId: promptId,
          body: body,
          note: Value(note),
        ),
      );
      await _prompts.setCurrentVersion(promptId, versionId);
      await (_db.update(
        _db.prompts,
      )..where((t) => t.id.equals(promptId))).write(
        PromptsCompanion(
          body: Value(body),
          variables: variables == null
              ? const Value.absent()
              : Value(PromptVariable.encode(variables)),
        ),
      );
    });
  }

  /// 回滚到指定历史版本：目标内容落为新版本（保留完整历史链）并前移指针。
  Future<void> rollbackToVersion({
    required int promptId,
    required int versionId,
  }) async {
    final version = await _versions.byId(versionId);
    if (version == null || version.promptId != promptId) {
      throw StateError('版本不存在：#$versionId');
    }
    await saveNewVersion(
      promptId: promptId,
      body: version.body,
      note: '回滚自版本 #${version.id}',
    );
  }

  /// 更新元信息；传 null 表示不修改，category 传空串表示清空分类。
  Future<void> updateMeta({
    required int promptId,
    String? title,
    String? category,
    List<PromptVariable>? variables,
  }) {
    return (_db.update(_db.prompts)..where((t) => t.id.equals(promptId))).write(
      PromptsCompanion(
        title: title == null ? const Value.absent() : Value(title),
        category: category == null ? const Value.absent() : Value(category),
        variables: variables == null
            ? const Value.absent()
            : Value(PromptVariable.encode(variables)),
      ),
    );
  }

  /// 删除条目并连带删除全部版本。
  Future<void> remove(int promptId) {
    return _db.transaction(() async {
      await _versions.removeByPrompt(promptId);
      await _prompts.remove(promptId);
    });
  }
}
