// 数据库表结构定稿（docs/01 第三节）。后续任务禁止改动本文件。
// 约定：JSON 类字段（tags/extra/params/aiMeta/payload 等）存原始字符串，
// 序列化/反序列化由上层模块负责；受约束的文本列用 textEnum 存枚举名。
import 'package:drift/drift.dart';

/// fragments.source 取值。
enum FragmentSource { manual, ai }

/// fragments.status 取值。
enum FragmentStatus { raw, optimized, failed }

/// prompts.type 取值。
enum PromptType { novel, image, agent }

/// kb_entries.credibility 取值。
enum Credibility { high, mid, low }

/// task_queue.status 取值。
enum QueueTaskStatus { pending, running, success, failed, cancelled }

/// usage_log.status 取值。
enum UsageStatus { ok, error, blocked }

/// 厂商配置（API Key 不入库，仅存 secure storage 引用名 keyRef）。
@DataClassName('ProviderRow')
class Providers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get baseUrl => text()();
  TextColumn get keyRef => text().nullable()();
  TextColumn get presetCode => text()(); // deepseek|qwen|doubao|zhipu|custom
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 拉取到的模型列表。tags 为 JSON 数组字符串，取值
/// general|reasoning|long_context|embedding（docs/00 D4 启发式，可手动改）。
@DataClassName('ModelRow')
@TableIndex(name: 'idx_models_provider', columns: {#providerId})
class Models extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get providerId => integer().references(Providers, #id)();
  TextColumn get modelId => text()();
  TextColumn get displayName => text()();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {providerId, modelId},
  ];
}

/// 思考强度预设。builtin 四条：fast|standard|deep|custom（docs/02 A4）。
@DataClassName('IntensityPreset')
class IntensityPresets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get params => text().withDefault(const Constant('{}'))(); // JSON
  BoolColumn get isBuiltin => boolean().withDefault(const Constant(false))();
}

/// 灵感碎片：rawText 原始版本 + optimizedJson AI 版本双存储。
@DataClassName('Fragment')
@TableIndex(name: 'idx_fragments_created', columns: {#createdAt})
class Fragments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rawText => text()();
  TextColumn get optimizedJson => text().nullable()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // JSON
  TextColumn get source => textEnum<FragmentSource>()();
  TextColumn get aiMeta => text().nullable()(); // JSON: model,preset,tokens,ts
  TextColumn get status =>
      textEnum<FragmentStatus>().clientDefault(() => FragmentStatus.raw.name)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 提示词条目。currentVersionId 应用层维护（避免与 prompt_versions 循环外键）。
@DataClassName('Prompt')
class Prompts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get type => textEnum<PromptType>()();
  TextColumn get body => text()();
  TextColumn get variables =>
      text().withDefault(const Constant('[]'))(); // JSON: [{name,desc}]
  TextColumn get category => text().nullable()();
  IntColumn get currentVersionId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 提示词版本历史。
@DataClassName('PromptVersion')
class PromptVersions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get promptId => integer().references(Prompts, #id)();
  TextColumn get body => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 资料库分类：path 形如 "仙侠设定/势力宗门"，全局唯一，parentId 冗余加速树查询。
@DataClassName('KbCategory')
class KbCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text().unique()();
  IntColumn get parentId =>
      integer().nullable().references(KbCategories, #id)();
}

/// 资料条目。extra 为分类扩展字段 JSON；related 为关联条目名 JSON 数组。
@DataClassName('KbEntry')
@TableIndex(name: 'idx_kb_entries_category', columns: {#categoryPath})
class KbEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entryName => text()();
  TextColumn get categoryPath => text()();
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // JSON
  TextColumn get summary => text().withDefault(const Constant(''))();
  TextColumn get contentMd => text().withDefault(const Constant(''))();
  TextColumn get extra => text().withDefault(const Constant('{}'))(); // JSON
  TextColumn get related =>
      text().withDefault(const Constant('[]'))(); // JSON: [entryName]
  TextColumn get source => text().nullable()();
  TextColumn get credibility =>
      textEnum<Credibility>().nullable()(); // high|mid|low
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 双向关联：每方向各存一行（docs/01 第三节）。
/// @ReferenceName 区分 kb_entries 上两条反向引用生成的字段，消除 name clash 告警。
@DataClassName('KbRelation')
@TableIndex(name: 'idx_kb_relations_entry', columns: {#entryId})
@TableIndex(name: 'idx_kb_relations_related', columns: {#relatedEntryId})
class KbRelations extends Table {
  IntColumn get id => integer().autoIncrement()();

  @ReferenceName('relationsAsEntry')
  IntColumn get entryId => integer().references(KbEntries, #id)();

  @ReferenceName('relationsAsRelated')
  IntColumn get relatedEntryId => integer().references(KbEntries, #id)();
}

/// 条目向量：float32 小端序列化进 BLOB；检索在 Dart 内存做余弦相似度（docs/00 D1）。
@DataClassName('EntryEmbedding')
class Embeddings extends Table {
  IntColumn get entryId => integer().references(KbEntries, #id)();
  TextColumn get model => text()();
  IntColumn get dim => integer()();
  BlobColumn get vector => blob()();

  @override
  Set<Column> get primaryKey => {entryId};
}

/// token 记账。costEstimate 为参考估值，查不到价格表时为 NULL（docs/00 D5）。
@DataClassName('UsageLogEntry')
@TableIndex(name: 'idx_usage_log_ts', columns: {#ts})
class UsageLogs extends Table {
  @override
  String get tableName => 'usage_log';

  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get ts => dateTime().withDefault(currentDateAndTime)();
  TextColumn get module => text()();
  TextColumn get taskType => text()();
  TextColumn get providerName => text()();
  TextColumn get model => text()();
  TextColumn get presetCode => text().nullable()();
  IntColumn get inputTokens => integer().withDefault(const Constant(0))();
  IntColumn get outputTokens => integer().withDefault(const Constant(0))();
  RealColumn get costEstimate => real().nullable()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  TextColumn get status => textEnum<UsageStatus>()();
  TextColumn get error => text().nullable()();
}

/// 异步任务队列持久化。module/taskType 与 usage_log 对应（docs/02 A5）。
@DataClassName('TaskQueueItem')
class TaskQueue extends Table {
  @override
  String get tableName => 'task_queue';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get module => text()();
  TextColumn get taskType => text()();
  TextColumn get payload => text()(); // JSON
  TextColumn get status => textEnum<QueueTaskStatus>().clientDefault(
    () => QueueTaskStatus.pending.name,
  )();
  TextColumn get result => text().nullable()();
  TextColumn get error => text().nullable()();
  IntColumn get retries => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
}

/// 键值设置：额度上限/默认强度/极速入库开关/更新仓库等（key 常量见 app_setting_keys.dart）。
@DataClassName('AppSetting')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// kb_fts：FTS5 外部内容虚表，索引 kb_entries 的 entry_name/summary/content_md，
/// rowid 对应 kb_entries.id。采用 trigram 分词以支持中文子串检索（默认 unicode61
/// 会把连续中文整段当作一个 token，无法按词命中）；三字符以下查询无法用 MATCH 命中，
/// 需要短词检索时由检索层回退 LIKE（core/search 职责）。
/// drift 不声明虚表：以下 DDL 与同步触发器由 database.dart 建库时执行。
abstract final class KbFts {
  static const tableName = 'kb_fts';

  static const createTableSql =
      'CREATE VIRTUAL TABLE IF NOT EXISTS kb_fts USING fts5('
      'entry_name, summary, content_md, '
      "content='kb_entries', content_rowid='id', tokenize='trigram')";

  /// 外部内容表的删除必须用 'delete' 命令形式并回填旧值。
  static const createTriggerSqls = <String>[
    'CREATE TRIGGER IF NOT EXISTS kb_entries_fts_insert AFTER INSERT ON kb_entries BEGIN'
        ' INSERT INTO kb_fts(rowid, entry_name, summary, content_md)'
        ' VALUES (new.id, new.entry_name, new.summary, new.content_md);'
        ' END',
    'CREATE TRIGGER IF NOT EXISTS kb_entries_fts_delete AFTER DELETE ON kb_entries BEGIN'
        ' INSERT INTO kb_fts(kb_fts, rowid, entry_name, summary, content_md)'
        " VALUES ('delete', old.id, old.entry_name, old.summary, old.content_md);"
        ' END',
    'CREATE TRIGGER IF NOT EXISTS kb_entries_fts_update AFTER UPDATE ON kb_entries BEGIN'
        ' INSERT INTO kb_fts(kb_fts, rowid, entry_name, summary, content_md)'
        " VALUES ('delete', old.id, old.entry_name, old.summary, old.content_md);"
        ' INSERT INTO kb_fts(rowid, entry_name, summary, content_md)'
        ' VALUES (new.id, new.entry_name, new.summary, new.content_md);'
        ' END',
  ];

  /// 检索权重：name 3 : summary 2 : content 1（docs/02 D4）。
  /// bm25 返回负值，越小越相关。
  static const bm25Weighted = 'bm25(kb_fts, 3.0, 2.0, 1.0)';
}

/// 备忘录：文本 + 图片。图片文件存放于应用数据目录（memos/），本表只存路径 JSON。
@DataClassName('MemoRow')
class Memos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get images => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 密码本条目：名称明文（列表展示），自定义字段（label/value 数组）与备注
/// 用 AES-GCM 加密后存 base64 密文；主密钥在系统安全存储（core/crypto）。
@DataClassName('PasswordEntryRow')
class PasswordEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get fieldsEnc => text()();
  TextColumn get noteEnc => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 书籍（v0.4）：自建 self / 导入 imported / 内置 builtin。
/// builtinKey 标记随应用内置的书籍（如公众号导读），避免重复导入。
@DataClassName('BookRow')
class Books extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get author => text().withDefault(const Constant(''))();
  TextColumn get kind => text().withDefault(const Constant('self'))();
  TextColumn get sourceUrl => text().withDefault(const Constant(''))();
  TextColumn get builtinKey => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 书籍章节：chapterIndex 从 0 递增；content 为 Markdown
/// （支持 `assets/...` 图片路径与 http(s) 图片链接）。
@DataClassName('BookChapterRow')
@TableIndex(name: 'idx_book_chapters_book', columns: {#bookId})
class BookChapters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer()();
  IntColumn get chapterIndex => integer()();
  TextColumn get title => text()();
  TextColumn get content => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}


