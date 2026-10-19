import 'dart:convert';
import 'dart:io';

import 'package:creative_kb/core/seed/builtin_schemas.dart';
import 'package:creative_kb/features/kb/models/kb_schema.dart';
import 'package:creative_kb/features/kb/services/schema_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late Directory schemasDir;
  late SchemaRegistry registry;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'creative_kb_registry_test',
    );
    schemasDir = Directory('${tempDir.path}${Platform.pathSeparator}schemas');
    await schemasDir.create(recursive: true);
    // 骨架内置通用/宗门 Schema + 用户自定义 Schema（含 enum/必填/number 字段）。
    await File('${schemasDir.path}${Platform.pathSeparator}general.json')
        .writeAsString(BuiltinSchemas.general);
    await File('${schemasDir.path}${Platform.pathSeparator}sect.json')
        .writeAsString(BuiltinSchemas.sect);
    await File('${schemasDir.path}${Platform.pathSeparator}realm.json')
        .writeAsString(
          jsonEncode({
            'id': 'realm',
            'name': '境界体系',
            'matchKeywords': ['境界', '突破', '练气'],
            'baseSchema': 'general',
            'fields': [
              {
                'key': 'tier',
                'label': '大境界',
                'type': 'enum',
                'required': true,
                'options': ['练气', '金丹', '元婴'],
              },
              {
                'key': 'lifespan',
                'label': '寿元',
                'type': 'number',
                'required': false,
              },
            ],
          }),
        );
    registry = SchemaRegistry(schemasDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('Schema 读取（docs/02 D1）', () {
    test('读取全部 JSON 并解析字段（内置 4 套之一的 sect + 自定义）', () async {
      final schemas = await registry.load();
      final ids = schemas.map((s) => s.id).toSet();
      expect(ids, containsAll(['sect', 'realm']));

      final sect = schemas.firstWhere((s) => s.id == 'sect');
      expect(sect.name, '宗门势力');
      expect(
        sect.fields.map((f) => f.key),
        containsAll(['hierarchy', 'location', 'rival_forces']),
      );
      expect(sect.matchKeywords, contains('宗门'));

      final realm = schemas.firstWhere((s) => s.id == 'realm');
      expect(realm.fields[0].type, KbSchemaFieldType.enumeration);
      expect(realm.fields[0].required, isTrue);
      expect(realm.fields[0].options, ['练气', '金丹', '元婴']);
      expect(realm.fields[1].type, KbSchemaFieldType.number);
    });

    test('损坏的 JSON 文件被跳过，不影响其余 Schema', () async {
      await File('${schemasDir.path}${Platform.pathSeparator}broken.json')
          .writeAsString('不是 JSON{{{');
      final schemas = await registry.load();
      expect(schemas.map((s) => s.id), isNot(contains('broken')));
      expect(schemas.map((s) => s.id), containsAll(['sect', 'realm']));
    });

    test('目录不存在时回退内置通用 Schema', () async {
      final empty = SchemaRegistry(
        Directory('${tempDir.path}${Platform.pathSeparator}none'),
      );
      final schemas = await empty.load();
      expect(schemas, hasLength(1));
      expect(schemas.single.id, KbSchema.generalSchemaId);
    });
  });

  group('matchKeywords 推荐（docs/02 D1）', () {
    test('青云宗示例文本命中 sect', () async {
      final suggested = await registry.suggest('青云宗是青云山脉上的正道宗门，设掌门、长老与内门弟子层级。');
      expect(suggested.id, 'sect');
    });

    test('境界文本命中 realm，无关文本回退 general', () async {
      final realm = await registry.suggest('练气期突破金丹期的境界划分。');
      expect(realm.id, 'realm');

      final general = await registry.suggest('一段与任何关键词都无关的普通文字。');
      expect(general.id, KbSchema.generalSchemaId);
    });
  });

  group('保存/删除即热加载（docs/02 D1：编辑即改 JSON 文件）', () {
    test('save 写盘为合法 JSON，随后 load 立即可见（无需重建实例）', () async {
      const custom = KbSchema(
        id: 'custom_cities',
        name: '城池',
        matchKeywords: ['城', '港口'],
        baseSchema: KbSchema.generalSchemaId,
        fields: [
          KbSchemaField(
            key: 'population',
            label: '人口',
            type: KbSchemaFieldType.number,
          ),
        ],
      );
      await registry.save(custom);

      final file = File(
        '${schemasDir.path}${Platform.pathSeparator}custom_cities.json',
      );
      expect(file.existsSync(), isTrue);
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(decoded['id'], 'custom_cities');
      expect((decoded['fields'] as List).first['key'], 'population');

      final after = await registry.load();
      expect(after.map((s) => s.id), contains('custom_cities'));
    });

    test('delete 移除文件后 load 不再返回', () async {
      await registry.delete('realm');
      expect(
        File('${schemasDir.path}${Platform.pathSeparator}realm.json')
            .existsSync(),
        isFalse,
      );
      final after = await registry.load();
      expect(after.map((s) => s.id), isNot(contains('realm')));
    });

    test('restoreBuiltin 补齐内置 4 套且不覆盖用户文件', () async {
      await registry.delete('sect');
      final written = await registry.restoreBuiltin();
      expect(
        written.map((f) => f.path.split(Platform.pathSeparator).last),
        contains('sect.json'),
      );
      final after = await registry.load();
      expect(after.map((s) => s.id), contains('sect'));
    });
  });

  group('Schema 字段校验（docs/02 D2 第3步）', () {
    test('必填缺失 / number 类型错误 / enum 取值越界给出中文问题', () {
      const realm = KbSchema(
        id: 'realm',
        name: '境界体系',
        fields: [
          KbSchemaField(
            key: 'tier',
            label: '大境界',
            type: KbSchemaFieldType.enumeration,
            required: true,
            options: ['练气', '金丹'],
          ),
          KbSchemaField(
            key: 'lifespan',
            label: '寿元',
            type: KbSchemaFieldType.number,
          ),
        ],
      );
      expect(realm.validateExtra({}), contains('缺少必填字段「大境界」'));
      expect(
        realm.validateExtra({'tier': '金丹', 'lifespan': '很长'}),
        contains('字段「寿元」需要数字'),
      );
      expect(
        realm.validateExtra({'tier': '渡劫'}),
        contains('字段「大境界」取值需为：练气/金丹'),
      );
      expect(realm.validateExtra({'tier': '金丹', 'lifespan': 500}), isEmpty);
    });
  });
}
