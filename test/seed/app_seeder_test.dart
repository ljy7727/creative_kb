import 'dart:convert';
import 'dart:io';

import 'package:creative_kb/core/seed/app_seeder.dart';
import 'package:creative_kb/core/seed/builtin_schemas.dart';
import 'package:creative_kb/core/seed/intensity_seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('creative_kb_seed_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('内置 Schema 首启落盘（docs/00 D6 / docs/02 D1）', () {
    test('写入 schemas/ 下 4 个 <id>.json，内容均为合法 JSON', () async {
      final schemasDir = Directory('${tempDir.path}${Platform.pathSeparator}schemas');
      final written = await writeBuiltinSchemas(schemasDir);

      expect(schemasDir.existsSync(), isTrue);
      expect(written, hasLength(BuiltinSchemas.all.length));
      for (final (:id, :json) in BuiltinSchemas.all) {
        final file = File('${schemasDir.path}${Platform.pathSeparator}$id.json');
        expect(file.existsSync(), isTrue, reason: '$id.json 未落盘');
        final decoded = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        expect(decoded['id'], id);
        expect(file.readAsStringSync(), json);
      }
    });

    test('重复执行不覆盖用户已编辑的 Schema 文件', () async {
      final schemasDir = Directory('${tempDir.path}${Platform.pathSeparator}schemas');
      await writeBuiltinSchemas(schemasDir);

      final sectFile = File('${schemasDir.path}${Platform.pathSeparator}sect.json');
      await sectFile.writeAsString('{"id":"sect","name":"我的宗门设定"}');

      final writtenAgain = await writeBuiltinSchemas(schemasDir);
      expect(writtenAgain, isEmpty, reason: '二次执行不应再写任何文件');
      expect(await sectFile.readAsString(), contains('我的宗门设定'));
    });
  });

  group('intensity 4 预设种子（docs/02 A4）', () {
    test('code 集合为 fast/standard/deep/custom 且 params 为合法 JSON', () {
      final presets = IntensitySeed.all();
      expect(presets.map((p) => p.code).toSet(), {'fast', 'standard', 'deep', 'custom'});
      expect(presets.map((p) => p.name), containsAll(['极速', '标准', '深度', '自定义']));
      for (final preset in presets) {
        final params = jsonDecode(preset.paramsJson) as Map<String, dynamic>;
        if (preset.code != 'custom') {
          expect(params.containsKey('temperature'), isTrue, reason: '${preset.code} 缺 temperature');
          expect(params.containsKey('maxTokens'), isTrue, reason: '${preset.code} 缺 maxTokens');
        }
      }
    });
  });
}
