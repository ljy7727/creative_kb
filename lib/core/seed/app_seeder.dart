import 'dart:io';

import 'package:path/path.dart' as p;

import '../db/app_setting_keys.dart';
import '../db/database.dart';
import 'app_data_dir.dart';
import 'builtin_schemas.dart';
import 'intensity_seed.dart';

/// 首启种子：内置 Schema 落盘 schemas/ + intensity 4 预设 + 默认设置。
/// 幂等：重复执行不覆盖用户已有内容。
class AppSeeder {
  AppSeeder(this.db, {Future<Directory> Function()? appDirResolver})
      : _appDirResolver = appDirResolver ?? resolveAppDataDirectory;

  final AppDatabase db;
  final Future<Directory> Function() _appDirResolver;

  Future<void> run() async {
    final dir = await _appDirResolver();
    await writeBuiltinSchemas(Directory(p.join(dir.path, 'schemas')));
    await seedIntensityPresets();
    await seedDefaultSettings();
  }

  /// 内置强度预设入库（只补缺，不覆盖用户修改）。
  Future<void> seedIntensityPresets() async {
    for (final (:code, :name, :paramsJson) in IntensitySeed.all()) {
      await db.intensityPresetsDao
          .insertIfAbsent(code: code, name: name, paramsJson: paramsJson, isBuiltin: true);
    }
  }

  /// 默认设置项（docs/02 A5/D2/A6；update.repo 为占位，待用户配置）。
  Future<void> seedDefaultSettings() async {
    await _setIfAbsent(AppSettingKeys.singleTaskMaxTokens, '8192');
    await _setIfAbsent(AppSettingKeys.dailyMaxTokens, '2000000');
    await _setIfAbsent(AppSettingKeys.defaultIntensity, 'standard');
    await _setIfAbsent(AppSettingKeys.quickIngest, 'false');
    await _setIfAbsent(AppSettingKeys.updateRepo, 'yourname/creative_kb');
    await _setIfAbsent(AppSettingKeys.updateAutoCheck, 'true');
  }

  Future<void> _setIfAbsent(String key, String value) async {
    if (await db.appSettingsDao.get(key) == null) {
      await db.appSettingsDao.set(key, value);
    }
  }
}

/// 将内置 Schema 写入 [schemasDir]（文件名 = `<id>`.json）。
/// 已存在的同名文件不覆盖（用户可能已编辑）；返回本次实际写入的文件。
Future<List<File>> writeBuiltinSchemas(Directory schemasDir) async {
  await schemasDir.create(recursive: true);
  final written = <File>[];
  for (final (:id, :json) in BuiltinSchemas.all) {
    final file = File(p.join(schemasDir.path, '$id.json'));
    if (file.existsSync()) continue;
    await file.writeAsString(json, flush: true);
    written.add(file);
  }
  return written;
}
