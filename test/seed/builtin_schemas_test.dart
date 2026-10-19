import 'dart:convert';

import 'package:creative_kb/core/seed/builtin_schemas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('内置 Schema（docs/02 D1）', () {
    const allowedTypes = {'enum', 'text', 'markdown', 'number'};
    final decoded = {
      for (final (:id, :json) in BuiltinSchemas.all)
        id: jsonDecode(json) as Map<String, dynamic>,
    };

    test('共 4 套：通用/历史官职/仙侠宝物/宗门势力，id 唯一', () {
      expect(BuiltinSchemas.all, hasLength(4));
      expect(decoded.keys.toSet(),
          {'general', 'official', 'treasure', 'sect'});
    });

    test('每套 JSON 可解析且结构合法', () {
      for (final record in BuiltinSchemas.all) {
        final id = record.id;
        final schema = decoded[id]!;
        expect(schema['id'], id, reason: '$id 顶层 id 与文件名不一致');
        expect((schema['name'] as String).isNotEmpty, isTrue, reason: '$id 缺 name');
        expect(schema['matchKeywords'], isA<List<dynamic>>(), reason: '$id matchKeywords 应为数组');
        expect(schema['baseSchema'], 'general', reason: '$id baseSchema 应沿用通用');

        final fields = schema['fields'] as List<dynamic>;
        final keys = <String>{};
        for (final field in fields) {
          expect(field, isA<Map<String, dynamic>>(), reason: '$id 字段应为对象');
          final f = field as Map<String, dynamic>;
          expect((f['key'] as String).isNotEmpty, isTrue, reason: '$id 字段缺 key');
          expect((f['label'] as String).isNotEmpty, isTrue, reason: '$id 字段缺 label');
          expect(allowedTypes.contains(f['type']), isTrue,
              reason: '$id 字段 ${f['key']} type 非法: ${f['type']}');
          expect(f['required'], isA<bool>(), reason: '$id 字段 ${f['key']} required 应为布尔');
          keys.add(f['key'] as String);
        }
        expect(keys.length, fields.length, reason: '$id 字段 key 重复');
      }
    });

    test('历史官职 Schema 含 朝代/品级/职权/上下级', () {
      final labels = (decoded['official']!['fields'] as List<dynamic>)
          .map((f) => (f as Map<String, dynamic>)['label'])
          .toList();
      expect(labels, containsAll(['朝代', '品级', '职权', '上下级']));
    });

    test('仙侠宝物 Schema 含 品级/材质/功效/炼制方式/稀有度', () {
      final labels = (decoded['treasure']!['fields'] as List<dynamic>)
          .map((f) => (f as Map<String, dynamic>)['label'])
          .toList();
      expect(labels, containsAll(['品级', '材质', '功效', '炼制方式', '稀有度']));
    });

    test('宗门势力 Schema 含 层级/驻地/传承功法/核心人物/敌对势力', () {
      final labels = (decoded['sect']!['fields'] as List<dynamic>)
          .map((f) => (f as Map<String, dynamic>)['label'])
          .toList();
      expect(labels, containsAll(['层级', '驻地', '传承功法', '核心人物', '敌对势力']));
    });
  });
}
