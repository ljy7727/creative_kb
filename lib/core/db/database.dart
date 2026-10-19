// 数据库定义。DAO 以 part 形式并入本库（drift_dev 只识别同库内的 DAO），
// 生成产物 database.g.dart 含全部表 row 类与 _$XxxDaoMixin。
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

// 统一出口：import database.dart 即可拿到全部表模型与枚举
// （FragmentSource/FragmentStatus/PromptType/Credibility/QueueTaskStatus/UsageStatus 等），
// 供各 feature 模块按 drift 惯例引用。
export 'tables.dart';

part 'database.g.dart';
part 'daos/app_settings_dao.dart';
part 'daos/embeddings_dao.dart';
part 'daos/fragments_dao.dart';
part 'daos/intensity_presets_dao.dart';
part 'daos/kb_categories_dao.dart';
part 'daos/kb_entries_dao.dart';
part 'daos/kb_relations_dao.dart';
part 'daos/models_dao.dart';
part 'daos/prompt_versions_dao.dart';
part 'daos/prompts_dao.dart';
part 'daos/providers_dao.dart';
part 'daos/task_queue_dao.dart';
part 'daos/usage_log_dao.dart';

/// 全库数据库定义（docs/01 第三节全部表 + kb_fts FTS5 虚表）。
@DriftDatabase(
  tables: [
    Providers,
    Models,
    IntensityPresets,
    Fragments,
    Prompts,
    PromptVersions,
    KbCategories,
    KbEntries,
    KbRelations,
    Embeddings,
    UsageLogs,
    TaskQueue,
    AppSettings,
  ],
  daos: [
    ProvidersDao,
    ModelsDao,
    IntensityPresetsDao,
    FragmentsDao,
    PromptsDao,
    PromptVersionsDao,
    KbCategoriesDao,
    KbEntriesDao,
    KbRelationsDao,
    EmbeddingsDao,
    UsageLogDao,
    TaskQueueDao,
    AppSettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// 生产入口：数据库文件位于 应用支持目录/creative_kb/app.db（docs/03 数据目录布局）。
  AppDatabase.open() : super(_openDefault());

  /// 测试专用：内存库 + 查询流同步关闭。
  /// drift 默认在最后一个监听者取消后等一帧事件循环再关流（Timer.run），
  /// 在 widget 测试的 fake async 里该 Timer 会存活到测试结束并触发
  /// 「A Timer is still pending」断言，因此测试一律用本构造。
  AppDatabase.inMemory()
    : super(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createFtsObjects();
    },
    onUpgrade: (m, from, to) async {
      // v1 无历史版本。后续版本在此按 from→to 增量迁移；
      // 涉及 kb_entries 结构变更时需重建 kb_fts（见 rebuildFts）。
    },
  );

  Future<void> _createFtsObjects() async {
    await customStatement(KbFts.createTableSql);
    for (final sql in KbFts.createTriggerSqls) {
      await customStatement(sql);
    }
  }

  /// 全量重建 FTS 索引（导入备份/批量修复后调用）。
  /// 外部内容虚表不支持 DELETE，官方方式是 'rebuild' 命令：
  /// 丢弃现有索引并从内容表 kb_entries 重新索引。
  Future<void> rebuildFts() async {
    await customStatement("INSERT INTO kb_fts(kb_fts) VALUES('rebuild')");
  }

  static QueryExecutor _openDefault() => driftDatabase(
    name: 'creative_kb_app',
    native: const DriftNativeOptions(databasePath: _defaultDatabasePath),
  );

  static Future<String> _defaultDatabasePath() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'creative_kb'));
    await dir.create(recursive: true);
    return p.join(dir.path, 'app.db');
  }
}
