// 内置书籍播种（v0.4）：首启/升级后把 assets 中的公众号导读导入为书籍。
// 已存在同 builtinKey 的书籍时跳过；资源缺失只记日志，不阻塞启动。
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/db/database.dart';

class DefaultBookSeeder {
  /// 随应用内置的书籍资源（book.json：builtinKey/title/author/kind/chapters）。
  static const assetPaths = <String>[
    'assets/books/gaoxingjiabi/book.json',
    'assets/books/vibe-vibe/book.json',
  ];

  /// 逐本播种；返回本次实际写入的书籍数。
  static Future<int> run(AppDatabase db) async {
    var seeded = 0;
    for (final asset in assetPaths) {
      if (await _seedOne(db, asset)) seeded += 1;
    }
    return seeded;
  }

  static Future<bool> _seedOne(AppDatabase db, String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) return false;
      final key = '${data['builtinKey'] ?? ''}';
      if (key.isEmpty) return false;
      if (await db.booksDao.byBuiltinKey(key) != null) return false;

      final chapters = data['chapters'];
      final now = DateTime.now();
      await db.transaction(() async {
        final bookId = await db.booksDao.add(
          BooksCompanion.insert(
            title: '${data['title'] ?? '未命名书籍'}',
            author: Value('${data['author'] ?? ''}'),
            kind: Value('${data['kind'] ?? 'builtin'}'),
            sourceUrl: Value('${data['sourceUrl'] ?? ''}'),
            builtinKey: Value(key),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        if (chapters is List) {
          for (var i = 0; i < chapters.length; i++) {
            final chapter = chapters[i];
            if (chapter is! Map) continue;
            await db.bookChaptersDao.add(
              BookChaptersCompanion.insert(
                bookId: bookId,
                chapterIndex: i,
                title: '${chapter['title'] ?? '第 ${i + 1} 章'}',
                content: Value('${chapter['content'] ?? ''}'),
                createdAt: Value(now),
              ),
            );
          }
        }
      });
      return true;
    } catch (error) {
      debugPrint('内置书籍播种失败（$assetPath）：$error');
      return false;
    }
  }
}
