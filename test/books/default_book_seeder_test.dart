// 内置书籍播种测试：幂等（标记跳过重复加载）、尊重用户删除、废弃书清理。
import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/features/books/services/default_book_seeder.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  setUp(() {
    db = AppDatabase.inMemory();
    addTearDown(db.close);
  });

  test('首次播种全部内置书；二次 run 跳过且数量不变', () async {
    final seeded = await DefaultBookSeeder.run(db);
    expect(seeded, DefaultBookSeeder.assetPaths.length);
    final afterFirst = await db.booksDao.getAll();
    expect(afterFirst.length, DefaultBookSeeder.assetPaths.length);

    final marker = await db.appSettingsDao.get('builtin_books_seeded');
    expect(marker, DefaultBookSeeder.assetPaths.join(','));

    // 二次 run：标记命中，不再读资源/写库。
    final seededAgain = await DefaultBookSeeder.run(db);
    expect(seededAgain, 0);
    final afterSecond = await db.booksDao.getAll();
    expect(afterSecond.length, afterFirst.length);
  });

  test('用户删除内置书后 run 不复活', () async {
    await DefaultBookSeeder.run(db);
    final books = await db.booksDao.getAll();
    final victim = books.firstWhere((b) => b.builtinKey.isNotEmpty);
    await db.booksDao.deleteCascade(victim.id);

    final seeded = await DefaultBookSeeder.run(db);
    expect(seeded, 0);
    expect(await db.booksDao.byId(victim.id), isNull);
  });

  test('清理废弃内置书', () async {
    final now = DateTime.now();
    await db.booksDao.add(
      BooksCompanion.insert(
        title: '旧书',
        builtinKey: const Value('github-datawhalechina-vibe-vibe'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await DefaultBookSeeder.run(db);
    expect(
      await db.booksDao.byBuiltinKey('github-datawhalechina-vibe-vibe'),
      isNull,
    );
  });
}
