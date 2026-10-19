// 设置页 providers：安全读库 + 厂商/模型/设置项/更新/备份服务。
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/db/app_setting_keys.dart';
import '../../../core/db/database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/llm/llm_client.dart';
import '../../../core/llm/model_catalog.dart';
import '../../../core/seed/app_data_dir.dart';
import '../../../core/storage/secure_keys.dart';
import '../../../core/update/update_checker.dart';
import '../services/backup_service.dart';

/// 安全读取全局数据库：main 未注入 override（纯 UI 冒烟等环境）时返回 null，
/// 设置页据此渲染引导空态而不是在构建期抛异常。
final settingsDbProvider = Provider<AppDatabase?>((ref) {
  try {
    return ref.watch(appDatabaseProvider);
  } catch (_) {
    return null;
  }
});

/// API Key 安全存储（测试可注入内存 KeyStore 覆盖）。
final secureKeysProvider = Provider<SecureKeys>((ref) => SecureKeys());

/// LLM 客户端（拉取模型用；测试可注入假客户端）。
final llmClientProvider = Provider<LlmClient>((ref) => OpenAiCompatLlmClient());

/// 厂商列表流（设置页「厂商与 Key」分组）。
final providersStreamProvider = StreamProvider<List<ProviderRow>>((ref) {
  final db = ref.watch(settingsDbProvider);
  if (db == null) return const Stream.empty();
  return db.providersDao.watchAll();
});

/// 某厂商的模型流。
final modelsByProviderProvider = StreamProvider.family<List<ModelRow>, int>((
  ref,
  providerId,
) {
  final db = ref.watch(settingsDbProvider);
  if (db == null) return const Stream.empty();
  return db.modelsDao.watchByProvider(providerId);
});

/// 默认思考强度 code（app_settings，缺省 standard）。
final defaultIntensityProvider = StreamProvider<String>((ref) {
  final db = ref.watch(settingsDbProvider);
  if (db == null) return Stream.value('standard');
  return db.appSettingsDao
      .watch(AppSettingKeys.defaultIntensity)
      .map((value) => (value == null || value.isEmpty) ? 'standard' : value);
});

/// 思考强度预设流。
final intensityPresetsSettingsProvider = StreamProvider<List<IntensityPreset>>((
  ref,
) {
  final db = ref.watch(settingsDbProvider);
  if (db == null) return const Stream.empty();
  return db.intensityPresetsDao.watchAll();
});

/// 模型目录服务（拉取模型入库；无数据库时读取抛 StateError）。
final modelCatalogProvider = Provider<ModelCatalog>((ref) {
  final db = ref.watch(settingsDbProvider);
  if (db == null) throw StateError('数据库未初始化');
  return ModelCatalog(ref.watch(llmClientProvider), db);
});

/// 数据目录（creative_kb/）；平台插件不可用（测试）时为 null。
final appDataDirProvider = FutureProvider<Directory?>((ref) async {
  try {
    return await resolveAppDataDirectory();
  } catch (_) {
    return null;
  }
});

/// 备份服务；数据目录不可用时为 null（导出/导入按钮提示不可用）。
final backupServiceProvider = FutureProvider<BackupService?>((ref) async {
  final dir = await ref.watch(appDataDirProvider.future);
  final db = ref.watch(settingsDbProvider);
  if (dir == null || db == null) return null;
  return BackupService(
    dbFile: File(p.join(dir.path, 'app.db')),
    schemasDir: Directory(p.join(dir.path, 'schemas')),
    exportsDir: Directory(p.join(dir.path, 'exports')),
    snapshotDb: (target) async {
      // VACUUM INTO 生成一致性快照（sqlite ≥3.27）；路径内单引号转义。
      final escaped = target.path.replaceAll("'", "''");
      await db.customStatement("VACUUM INTO '$escaped'");
    },
  );
});

/// 更新检查仓库（owner/repo 字符串，占位 yourname/creative_kb）。
final updateRepoSettingProvider = StreamProvider<String>((ref) {
  final db = ref.watch(settingsDbProvider);
  if (db == null) return Stream.value('yourname/creative_kb');
  return db.appSettingsDao
      .watch(AppSettingKeys.updateRepo)
      .map(
        (value) =>
            (value == null || value.isEmpty) ? 'yourname/creative_kb' : value,
      );
});

/// 启动时自动检查开关（默认开，docs/02 A6）。
final updateAutoCheckProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(settingsDbProvider);
  if (db == null) return Stream.value(false);
  return db.appSettingsDao
      .watch(AppSettingKeys.updateAutoCheck)
      .map((value) => value != 'false');
});

/// 更新检查器实例。
final updateCheckerProvider = Provider<UpdateChecker>((ref) => UpdateChecker());

/// 当前应用版本（pubspec version，package_info 读取；测试环境回落 0.0.0）。
final appVersionProvider = FutureProvider<String>(
  (ref) => resolveCurrentVersion(),
);

/// 拆分 owner/repo 设置值为两部分；非法值返回 null。
({String owner, String repo})? parseUpdateRepo(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final slash = trimmed.indexOf('/');
  if (slash <= 0 || slash == trimmed.length - 1) return null;
  return (
    owner: trimmed.substring(0, slash),
    repo: trimmed.substring(slash + 1),
  );
}

/// 启动自动检查结果（AppShell 消费后弹对话框；null = 无新版/未开启/未配置）。
final startupUpdateProvider = FutureProvider<UpdateCheckResult?>((ref) async {
  final db = ref.watch(settingsDbProvider);
  if (db == null) return null;
  final autoCheck = await db.appSettingsDao.get(AppSettingKeys.updateAutoCheck);
  if (autoCheck == 'false') return null;
  final repoRaw = await db.appSettingsDao.get(AppSettingKeys.updateRepo) ?? '';
  final repo = parseUpdateRepo(repoRaw);
  if (repo == null) return null;
  final result = await ref
      .read(updateCheckerProvider)
      .check(
        owner: repo.owner,
        repo: repo.repo,
        currentVersion: await resolveCurrentVersion(),
      );
  return result.hasUpdate ? result : null;
});
