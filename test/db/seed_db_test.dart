import 'dart:io';

import 'package:creative_kb/core/db/app_setting_keys.dart';
import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/core/seed/app_seeder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<Directory> tempAppDir() async {
    final dir = await Directory.systemTemp.createTemp('creative_kb_db_seed');
    addTearDown(() => dir.delete(recursive: true));
    return dir;
  }

  test('AppSeeder.run 落盘 schema 文件并写入 intensity 4 预设，幂等', () async {
    final appDir = await tempAppDir();
    final seeder = AppSeeder(db, appDirResolver: () async => appDir);

    await seeder.run();
    final presets = await db.intensityPresetsDao.getAll();
    expect(presets, hasLength(4));
    expect(presets.map((p) => p.code).toSet(), {
      'fast',
      'standard',
      'deep',
      'custom',
    });
    expect(presets.every((p) => p.isBuiltin), isTrue);
    expect(Directory('${appDir.path}/schemas').listSync(), hasLength(4));

    // 幂等：再次执行不重复写入。
    await seeder.run();
    expect(await db.intensityPresetsDao.getAll(), hasLength(4));
    expect(Directory('${appDir.path}/schemas').listSync(), hasLength(4));
  });

  test('AppSeeder.run 写入默认设置项', () async {
    await AppSeeder(db, appDirResolver: () async => (await tempAppDir())).run();

    expect(
      await db.appSettingsDao.get(AppSettingKeys.defaultIntensity),
      'standard',
    );
    expect(await db.appSettingsDao.get(AppSettingKeys.quickIngest), 'false');
    expect(
      await db.appSettingsDao.get(AppSettingKeys.updateRepo),
      'ljy7727/creative_kb',
    );
    expect(
      int.parse(
        await db.appSettingsDao.get(AppSettingKeys.singleTaskMaxTokens) ?? '0',
      ),
      greaterThan(0),
    );
    expect(
      int.parse(
        await db.appSettingsDao.get(AppSettingKeys.dailyMaxTokens) ?? '0',
      ),
      greaterThan(0),
    );
  });

  test('insertIfAbsent 不覆盖已有预设；updateParams 可改参数', () async {
    await db.intensityPresetsDao.insertIfAbsent(
      code: 'standard',
      name: '标准',
      paramsJson: '{"temperature":0.7,"maxTokens":4096}',
      isBuiltin: true,
    );
    await db.intensityPresetsDao.insertIfAbsent(
      code: 'standard',
      name: '另存一份',
      paramsJson: '{}',
      isBuiltin: true,
    );
    final presets = await db.intensityPresetsDao.getAll();
    expect(presets, hasLength(1));
    expect(presets.single.name, '标准');

    await db.intensityPresetsDao.updateParams(
      'standard',
      '{"temperature":0.9}',
    );
    expect(
      (await db.intensityPresetsDao.byCode('standard'))!.params,
      '{"temperature":0.9}',
    );
  });
}
