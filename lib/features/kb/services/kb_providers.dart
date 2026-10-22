import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// ProviderException（watch 错误态 provider 的包装异常）在 misc 导出中。
import 'package:flutter_riverpod/misc.dart';
import 'package:path/path.dart' as p;

import '../../../core/db/app_setting_keys.dart';
import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/llm/deepseek_tools.dart';
import '../../../core/seed/app_data_dir.dart';
import '../../../core/search/hybrid_search.dart';
import '../../../core/tasks/task_runner_provider.dart';
import '../models/kb_schema.dart';
import 'kb_ai_gateway.dart';
import 'kb_ai_gateway_impl.dart';
import 'kb_embedding_config.dart';
import 'kb_entry_service.dart';
import 'kb_ingest_task.dart';
import 'kb_research_service.dart';
import 'kb_vector_task.dart';
import 'schema_registry.dart';

export 'kb_ai_gateway.dart'
    show
        KbAiGateway,
        KbAiCompletion,
        KbQuotaExceededException,
        KbAiNotConfiguredException;

/// 生产实现：core/llm 客户端 + SecureKeys（测试用假网关 override 覆盖）。
final kbAiGatewayProvider = Provider<KbAiGateway>((ref) {
  final db = ref.watch(kbDbProvider);
  if (db == null) throw StateError('数据库未初始化');
  return LlmClientKbAiGateway(db);
});

/// 是否已配置可用对话模型：任一厂商「有 Key 且有启用模型」。
/// 跟随 providers/models 表变化自动重算；未就绪按 false（AI 按钮置灰，docs/00 验收 2）。
final kbAiAvailableProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(kbDbProvider);
  if (db == null) return Stream.value(false);
  return db.providersDao.watchAll().asyncMap((_) => hasUsableChatModel(db));
});

/// kb 模块任务注册桥：watch 即把 kb_embed 处理器注册进全局 TaskRunner，
/// 避免全局队列把未注册类型标记失败（与 fragments 桥接同模式）。
/// 裸 ProviderScope（无数据库注入）时静默跳过。
final Provider<void> kbQueueBridgeProvider = Provider<void>((ref) {
  try {
    final runner = ref.watch(taskRunnerProvider);
    runner.registerHandler(KbVectorTaskService.taskType, (context) async {
      final entryId = (context.payload['entryId'] as num?)?.toInt();
      final model = context.payload['model'] as String? ?? '';
      if (entryId == null) return;
      await ref
          .read(kbVectorTaskServiceProvider)
          .processEntry(entryId: entryId, model: model);
    });
  } on ProviderException {
    // 数据库未注入（纯 UI 冒烟）：跳过任务注册。
  }
});

/// 安全读取全局数据库：main 未注入 override（纯 UI 冒烟等环境）时返回 null，
/// 页面据此渲染引导空态，而不是在构建期抛异常。
final kbDbProvider = Provider<AppDatabase?>((ref) {
  try {
    return ref.watch(appDatabaseProvider);
  } catch (_) {
    return null;
  }
});

/// Schema 目录（应用数据目录/creative_kb/schemas，docs/02 D1）。
/// 平台插件不可用时为 null（测试环境降级）。
final schemaDirProvider = FutureProvider<Directory?>((ref) async {
  try {
    final base = await resolveAppDataDirectory();
    return Directory(p.join(base.path, 'schemas'));
  } catch (_) {
    return null;
  }
});

/// Schema 注册表内容：每次读取都重读目录（热加载语义，docs/02 D1）。
/// 设置页编辑 JSON 后 `ref.invalidate(schemaRegistryProvider)` 即生效。
final schemaRegistryProvider = FutureProvider<List<KbSchema>>((ref) async {
  final dir = await ref.watch(schemaDirProvider.future);
  if (dir == null) return const <KbSchema>[];
  return SchemaRegistry(dir).load();
});

final kbEntriesStreamProvider = StreamProvider<List<KbEntry>>((ref) {
  final db = ref.watch(kbDbProvider);
  if (db == null) return const Stream.empty();
  return db.kbEntriesDao.watchAll();
});

final kbCategoriesStreamProvider = StreamProvider<List<KbCategory>>((ref) {
  final db = ref.watch(kbDbProvider);
  if (db == null) return const Stream.empty();
  return db.kbCategoriesDao.watchAll();
});

/// 各分类条目计数（分类树角标，docs/02 D4）：直接由条目流推导，天然同步。
final kbCategoryCountsProvider = Provider<Map<String, int>>((ref) {
  final entries = ref.watch(kbEntriesStreamProvider).value ?? const <KbEntry>[];
  final counts = <String, int>{};
  for (final entry in entries) {
    counts[entry.categoryPath] = (counts[entry.categoryPath] ?? 0) + 1;
  }
  return counts;
});

/// 极速入库模式开关（设置页维护，默认关，docs/02 D2）。
final quickIngestProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(kbDbProvider);
  if (db == null) return Stream.value(false);
  return db.appSettingsDao
      .watch(AppSettingKeys.quickIngest)
      .map((value) => value == 'true');
});

final intensityPresetsStreamProvider = StreamProvider<List<IntensityPreset>>((
  ref,
) {
  final db = ref.watch(kbDbProvider);
  if (db == null) return const Stream.empty();
  return db.intensityPresetsDao.watchAll();
});

/// 嵌入模型配置；null = 未配置（检索降级纯 FTS，docs/00 D7）。
final embeddingConfigProvider = FutureProvider<KbEmbeddingConfig?>((ref) async {
  final db = ref.watch(kbDbProvider);
  if (db == null) return null;
  return KbEmbeddingConfigResolver.resolve(db);
});

final kbEntryServiceProvider = Provider<KbEntryService>((ref) {
  final db = ref.watch(kbDbProvider);
  if (db == null) throw StateError('数据库未初始化');
  return KbEntryService(db);
});

final hybridSearchServiceProvider = Provider<HybridSearchService>((ref) {
  final db = ref.watch(kbDbProvider);
  if (db == null) throw StateError('数据库未初始化');
  return HybridSearchService(db);
});

final Provider<KbVectorTaskService> kbVectorTaskServiceProvider =
    Provider<KbVectorTaskService>((ref) {
      // 注意：不要在这里 watch kbQueueBridgeProvider —— 处理器闭包运行时
      // 需经 bridge 的 ref 回读本 provider，riverpod 3 会判定为循环依赖。
      // 处理器注册由各调用点显式 ref.read(kbQueueBridgeProvider) 触发。
      final db = ref.watch(kbDbProvider);
      if (db == null) throw StateError('数据库未初始化');
      final gateway = (ref.watch(kbAiAvailableProvider).value ?? false)
          ? ref.watch(kbAiGatewayProvider)
          : null;
      return KbVectorTaskService(db, gateway: gateway);
    });

/// 入库 AI 任务（仅在 kbAiAvailableProvider 为 true 时读取）。
final kbIngestTaskProvider = Provider<KbIngestTask>((ref) {
  final db = ref.watch(kbDbProvider);
  if (db == null) throw StateError('数据库未初始化');
  if (!(ref.watch(kbAiAvailableProvider).value ?? false)) {
    throw StateError('未配置可用 AI 模型');
  }
  final gateway = ref.watch(kbAiGatewayProvider);
  return KbIngestTask(
    db,
    gateway: gateway,
    loadSchemas: () async {
      final dir = await ref.read(schemaDirProvider.future);
      if (dir == null) return <KbSchema>[KbSchema.fallbackGeneral()];
      return SchemaRegistry(dir).load();
    },
  );
});

/// DeepSeek Search/Fetch 客户端（资料库 AI 搜集专用；测试可 override 注入假实现）。
final deepSeekToolsProvider = Provider<DeepSeekToolsClient>(
  (ref) => DeepSeekToolsClient(),
);

/// AI 搜集服务：DeepSeek 搜索/抓取 + KbIngestTask 结构化。
final kbResearchServiceProvider = Provider<KbResearchService>((ref) {
  final db = ref.watch(kbDbProvider);
  if (db == null) throw StateError('数据库未初始化');
  if (!(ref.watch(kbAiAvailableProvider).value ?? false)) {
    throw StateError('未配置可用 AI 模型');
  }
  return KbResearchService(
    db,
    tools: ref.watch(deepSeekToolsProvider),
    ingest: ref.watch(kbIngestTaskProvider),
  );
});
