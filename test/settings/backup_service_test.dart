// 备份服务单测：导出包含备忘录图片（memos/），导入还原；旧包（无 memos）兼容。
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:creative_kb/features/settings/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late Directory schemasDir;
  late Directory memosDir;
  late Directory exportsDir;
  late File dbFile;
  late BackupService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('creative_kb_backup');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    schemasDir = Directory('${root.path}${Platform.pathSeparator}schemas');
    memosDir = Directory('${root.path}${Platform.pathSeparator}memos');
    exportsDir = Directory('${root.path}${Platform.pathSeparator}exports');
    await schemasDir.create(recursive: true);
    await memosDir.create(recursive: true);
    dbFile = File('${root.path}${Platform.pathSeparator}app.db');
    await dbFile.writeAsBytes([1, 2, 3, 4], flush: true);
    await File(
      '${schemasDir.path}${Platform.pathSeparator}person.json',
    ).writeAsString('{"id":"person"}', flush: true);
    await File(
      '${memosDir.path}${Platform.pathSeparator}1700000000_1.jpg',
    ).writeAsBytes([9, 8, 7], flush: true);
    service = BackupService(
      dbFile: dbFile,
      schemasDir: schemasDir,
      exportsDir: exportsDir,
      memosDir: memosDir,
    );
  });

  test('导出包含 db/schema/备忘录图片与 manifest', () async {
    final zip = await service.exportTo(exportsDir);
    final archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
    final names = archive.files.where((f) => f.isFile).map((f) => f.name).toSet();
    expect(names, containsAll(['app.db', 'manifest.json', 'schemas/person.json']));
    expect(names, contains('memos/1700000000_1.jpg'));
    final image = archive.files.firstWhere(
      (f) => f.name == 'memos/1700000000_1.jpg',
    );
    expect(image.content, [9, 8, 7]);
  });

  test('导入还原备忘录图片（先删本地再导入）', () async {
    final zip = await service.exportTo(exportsDir);
    final imageFile = File(
      '${memosDir.path}${Platform.pathSeparator}1700000000_1.jpg',
    );
    await imageFile.delete();

    await service.importFrom(await zip.readAsBytes());

    expect(imageFile.existsSync(), isTrue, reason: '图片应随导入还原');
    expect(await imageFile.readAsBytes(), [9, 8, 7]);
  });

  test('旧版导出包（无 memos 条目）仍可导入', () async {
    // 手工构造旧版布局：只有 db + manifest + schema。
    final archive = Archive()
      ..addFile(ArchiveFile.bytes('app.db', [5, 6, 7, 8]))
      ..addFile(
        ArchiveFile.string(
          'manifest.json',
          '{"version":1,"exportedAt":"2026-01-01T00:00:00"}',
        ),
      )
      ..addFile(ArchiveFile.string('schemas/person.json', '{}'));
    final bytes = ZipEncoder().encode(archive);
    await File('${memosDir.path}${Platform.pathSeparator}keep.jpg')
        .writeAsBytes([1]);
    await memosDir.delete(recursive: true); // 清空 memos 模拟待还原状态

    await service.importFrom(bytes);

    // 旧包没有 memos 条目：目录不创建、不报错。
    expect(memosDir.existsSync(), isFalse);
    // db 暂存文件写入成功。
    expect(File('${dbFile.path}.imported').existsSync(), isTrue);
  });
}
