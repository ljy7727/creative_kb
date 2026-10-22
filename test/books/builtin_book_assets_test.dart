// 内置书籍资源完整性测试：book.json 可解析、字段齐全、章节非空。
import 'dart:convert';

import 'package:creative_kb/features/books/services/default_book_seeder.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('全部内置 book.json 可解析且章节非空', () async {
    expect(DefaultBookSeeder.assetPaths, isNotEmpty);
    for (final asset in DefaultBookSeeder.assetPaths) {
      final raw = await rootBundle.loadString(asset);
      final data = jsonDecode(raw);
      expect(data, isA<Map<String, dynamic>>(), reason: asset);
      final map = data as Map<String, dynamic>;
      expect('${map['builtinKey'] ?? ''}', isNotEmpty, reason: asset);
      expect('${map['title'] ?? ''}', isNotEmpty, reason: asset);
      final chapters = map['chapters'];
      expect(chapters, isA<List>(), reason: asset);
      expect((chapters as List).length, greaterThanOrEqualTo(1), reason: asset);
      for (final chapter in chapters) {
        expect(chapter, isA<Map>(), reason: asset);
        expect('${(chapter as Map)['title'] ?? ''}', isNotEmpty, reason: asset);
        expect('${chapter['content'] ?? ''}', isNotEmpty, reason: asset);
      }
    }
  });

  test('Vibe Coding 教程：章节数量与来源信息', () async {
    final raw = await rootBundle.loadString(
      'assets/books/vibe-vibe/book.json',
    );
    final data = jsonDecode(raw) as Map<String, dynamic>;
    expect(data['title'], contains('Vibe Coding'));
    expect(data['author'], 'Datawhale');
    expect(data['sourceUrl'], contains('datawhalechina/vibe-vibe'));
    expect((data['chapters'] as List).length, greaterThanOrEqualTo(20));
  });
}
