part of '../database.dart';

/// book_chapters 表 DAO：按 chapterIndex 升序。
@DriftAccessor(tables: [BookChapters])
class BookChaptersDao extends DatabaseAccessor<AppDatabase>
    with _$BookChaptersDaoMixin {
  BookChaptersDao(super.db);

  Future<List<BookChapterRow>> byBook(int bookId) =>
      (select(bookChapters)
            ..where((t) => t.bookId.equals(bookId))
            ..orderBy([(t) => OrderingTerm.asc(t.chapterIndex)]))
          .get();

  Stream<List<BookChapterRow>> watchByBook(int bookId) =>
      (select(bookChapters)
            ..where((t) => t.bookId.equals(bookId))
            ..orderBy([(t) => OrderingTerm.asc(t.chapterIndex)]))
          .watch();

  Future<BookChapterRow?> byId(int id) =>
      (select(bookChapters)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> add(BookChaptersCompanion entry) =>
      into(bookChapters).insert(entry);

  Future<void> updateRow(BookChapterRow row) =>
      update(bookChapters).replace(row);

  Future<void> deleteById(int id) =>
      (delete(bookChapters)..where((t) => t.id.equals(id))).go();

  Future<void> deleteByBook(int bookId) =>
      (delete(bookChapters)..where((t) => t.bookId.equals(bookId))).go();

  /// 追加章节时取下一个下标。
  Future<int> nextIndex(int bookId) async {
    final rows = await (select(
      bookChapters,
    )..where((t) => t.bookId.equals(bookId))).get();
    if (rows.isEmpty) return 0;
    return rows.map((r) => r.chapterIndex).reduce((a, b) => a > b ? a : b) + 1;
  }
}
