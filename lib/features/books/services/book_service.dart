// 书籍增删改（v0.4）：自建/导入/内置统一走这里。
import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import 'book_import_service.dart';

class BookService {
  BookService(this._db);

  final AppDatabase _db;

  /// 创建书籍（可一次带章节）。kind: self | imported | builtin。
  Future<int> createBook({
    required String title,
    String author = '',
    String kind = 'self',
    String sourceUrl = '',
    List<ImportedChapter> chapters = const [],
  }) async {
    final now = DateTime.now();
    final bookId = await _db.booksDao.add(
      BooksCompanion.insert(
        title: title.trim().isEmpty ? '未命名书籍' : title.trim(),
        author: Value(author.trim()),
        kind: Value(kind),
        sourceUrl: Value(sourceUrl),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    for (var i = 0; i < chapters.length; i++) {
      await _db.bookChaptersDao.add(
        BookChaptersCompanion.insert(
          bookId: bookId,
          chapterIndex: i,
          title: chapters[i].title.trim().isEmpty
              ? '第 ${i + 1} 章'
              : chapters[i].title.trim(),
          content: Value(chapters[i].content),
          createdAt: Value(now),
        ),
      );
    }
    return bookId;
  }

  Future<void> updateMeta(
    int bookId, {
    required String title,
    required String author,
  }) async {
    final row = await _db.booksDao.byId(bookId);
    if (row == null) throw StateError('书籍不存在');
    await _db.booksDao.updateRow(
      row.copyWith(
        title: title.trim().isEmpty ? row.title : title.trim(),
        author: author.trim(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<int> addChapter(
    int bookId, {
    required String title,
    required String content,
  }) async {
    final index = await _db.bookChaptersDao.nextIndex(bookId);
    final id = await _db.bookChaptersDao.add(
      BookChaptersCompanion.insert(
        bookId: bookId,
        chapterIndex: index,
        title: title.trim().isEmpty ? '第 ${index + 1} 章' : title.trim(),
        content: Value(content),
        createdAt: Value(DateTime.now()),
      ),
    );
    await _touch(bookId);
    return id;
  }

  Future<void> updateChapter(
    int chapterId, {
    required String title,
    required String content,
  }) async {
    final row = await _db.bookChaptersDao.byId(chapterId);
    if (row == null) throw StateError('章节不存在');
    await _db.bookChaptersDao.updateRow(
      row.copyWith(
        title: title.trim().isEmpty ? row.title : title.trim(),
        content: content,
      ),
    );
    await _touch(row.bookId);
  }

  Future<void> deleteChapter(int chapterId) async {
    final row = await _db.bookChaptersDao.byId(chapterId);
    if (row == null) return;
    await _db.bookChaptersDao.deleteById(chapterId);
    await _touch(row.bookId);
  }

  Future<void> deleteBook(int bookId) => _db.booksDao.deleteCascade(bookId);

  Future<void> _touch(int bookId) async {
    final row = await _db.booksDao.byId(bookId);
    if (row == null) return;
    await _db.booksDao.updateRow(row.copyWith(updatedAt: DateTime.now()));
  }
}
