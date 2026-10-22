// 书籍服务单测：创建带章节、追加/编辑/删除章节、删除书籍级联。
import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/features/books/services/book_import_service.dart';
import 'package:creative_kb/features/books/services/book_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late BookService service;

  setUp(() {
    db = AppDatabase.inMemory();
    service = BookService(db);
  });

  tearDown(() => db.close());

  test('创建带章节：章序从 0 递增', () async {
    final id = await service.createBook(
      title: '自建书',
      author: '作者',
      chapters: const [
        ImportedChapter(title: '第一章', content: '内容一'),
        ImportedChapter(title: '第二章', content: '内容二'),
      ],
    );
    final book = await db.booksDao.byId(id);
    expect(book!.title, '自建书');
    expect(book.kind, 'self');
    final chapters = await db.bookChaptersDao.byBook(id);
    expect(chapters.map((c) => c.chapterIndex), [0, 1]);
    expect(chapters.map((c) => c.title), ['第一章', '第二章']);
  });

  test('追加章节：索引接续；编辑与删除章节', () async {
    final id = await service.createBook(title: '书');
    final first = await service.addChapter(
      id,
      title: 'A',
      content: 'a',
    );
    await service.addChapter(id, title: 'B', content: 'b');
    var chapters = await db.bookChaptersDao.byBook(id);
    expect(chapters.map((c) => c.chapterIndex), [0, 1]);

    await service.updateChapter(first, title: 'A2', content: 'a2');
    chapters = await db.bookChaptersDao.byBook(id);
    expect(chapters.first.title, 'A2');

    await service.deleteChapter(first);
    chapters = await db.bookChaptersDao.byBook(id);
    expect(chapters.single.title, 'B');
  });

  test('修改书籍信息与级联删除', () async {
    final id = await service.createBook(
      title: '旧名',
      chapters: const [ImportedChapter(title: '章', content: 'x')],
    );
    await service.updateMeta(id, title: '新名', author: '某人');
    final book = await db.booksDao.byId(id);
    expect(book!.title, '新名');
    expect(book.author, '某人');

    await service.deleteBook(id);
    expect(await db.booksDao.byId(id), isNull);
    expect(await db.bookChaptersDao.byBook(id), isEmpty);
  });

  test('导入书籍 kind 与来源 URL 保存', () async {
    final id = await service.createBook(
      title: '导入书',
      kind: 'imported',
      sourceUrl: 'https://example.com/a',
      chapters: const [ImportedChapter(title: '全文', content: '内容')],
    );
    final book = await db.booksDao.byId(id);
    expect(book!.kind, 'imported');
    expect(book.sourceUrl, 'https://example.com/a');
  });
}
