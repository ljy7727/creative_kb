// 备忘录 DAO 单测：增删改查与更新时间倒序。
import 'package:creative_kb/core/db/database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.inMemory());
  tearDown(() => db.close());

  test('新增/读取/更新/删除', () async {
    final now = DateTime.now();
    final id = await db.memosDao.add(
      MemosCompanion.insert(
        title: const Value('标题'),
        content: const Value('内容第一行\n第二行'),
        images: const Value('["C:/x/a.png"]'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    final row = await db.memosDao.byId(id);
    expect(row, isNotNull);
    expect(row!.title, '标题');
    expect(row.content, contains('第二行'));
    expect(row.images, contains('a.png'));

    await db.memosDao.updateRow(
      row.copyWith(title: '新标题', updatedAt: now.add(const Duration(minutes: 1))),
    );
    expect((await db.memosDao.byId(id))!.title, '新标题');
    await db.memosDao.deleteById(id);
    expect(await db.memosDao.byId(id), isNull);
  });

  test('watchAll 按更新时间倒序', () async {
    final base = DateTime(2026, 1, 1);
    for (var i = 0; i < 3; i++) {
      await db.memosDao.add(
        MemosCompanion.insert(
          title: Value('m$i'),
          createdAt: Value(base),
          updatedAt: Value(base.add(Duration(minutes: i))),
        ),
      );
    }
    final rows = await db.memosDao.getAll();
    expect(rows.map((r) => r.title), ['m2', 'm1', 'm0']);
  });
}
