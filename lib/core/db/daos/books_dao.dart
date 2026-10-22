part of '../database.dart';

/// books 表 DAO。
@DriftAccessor(tables: [Books, BookChapters])
class BooksDao extends DatabaseAccessor<AppDatabase> with _$BooksDaoMixin {
  BooksDao(super.db);

  Stream<List<BookRow>> watchAll() => (select(
    books,
  )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  Future<List<BookRow>> getAll() => (select(
    books,
  )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();

  Future<BookRow?> byId(int id) =>
      (select(books)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<BookRow?> byBuiltinKey(String key) => key.isEmpty
      ? Future.value(null)
      : (select(books)..where((t) => t.builtinKey.equals(key)))
            .getSingleOrNull();

  Future<int> add(BooksCompanion entry) => into(books).insert(entry);

  Future<void> updateRow(BookRow row) => update(books).replace(row);

  /// 删除书籍并连带删除全部章节。
  Future<void> deleteCascade(int id) => transaction(() async {
    await (delete(bookChapters)..where((t) => t.bookId.equals(id))).go();
    await (delete(books)..where((t) => t.id.equals(id))).go();
  });
}
