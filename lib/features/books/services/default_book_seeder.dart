// 内置书籍播种（v0.4）：首启/升级后把 assets 中的公众号导读导入为书籍。
// 已存在同 builtinKey 的书籍时跳过；资源缺失只记日志，不阻塞启动。
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/db/database.dart';

class DefaultBookSeeder {
  static const assetPath = 'assets/books/gaoxingjiabi/book.json';

  /// 返回 true 表示本次实际写入（新装或升级后的首次运行）。
  static Future<bool> run(AppDatabase db) async {
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
            kind: const Value('builtin'),
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
      debugPrint('内置书籍播种失败：$error');
      return false;
    }
  }
}
