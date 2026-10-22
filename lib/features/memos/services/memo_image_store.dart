// 备忘录图片存储：把选择的图片复制到应用数据目录 memos/，数据库只存路径。
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MemoImageStore {
  MemoImageStore({Future<Directory> Function()? baseDirResolver})
    : _baseDirResolver = baseDirResolver ?? _defaultBaseDir;

  final Future<Directory> Function() _baseDirResolver;
  final Random _random = Random();

  static Future<Directory> _defaultBaseDir() async {
    final base = await getApplicationSupportDirectory();
    return Directory(p.join(base.path, 'creative_kb'));
  }

  Future<Directory> _imagesDir() async {
    final dir = Directory(p.join((await _baseDirResolver()).path, 'memos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// 复制一张图片进数据目录，返回文件路径。
  Future<String> save(PlatformFile file) async {
    final dir = await _imagesDir();
    final ext = p.extension(file.name).replaceFirst('.', '');
    final suffix = ext.isEmpty ? 'jpg' : ext.toLowerCase();
    final name =
        '${DateTime.now().microsecondsSinceEpoch}_'
        '${_random.nextInt(1 << 20)}.$suffix';
    final path = p.join(dir.path, name);
    await File(path).writeAsBytes(
      await file.xFile.readAsBytes(),
      flush: true,
    );
    return path;
  }

  /// 删除图片（文件不存在时静默）。
  Future<void> delete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // 删除失败不阻塞业务（下次导出/清理可再处理）。
    }
  }
}
