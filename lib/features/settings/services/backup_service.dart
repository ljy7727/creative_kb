// 数据备份与恢复（docs/02 模块E「数据」分组）：
// 导出 = app.db 快照（VACUUM INTO，一致性快照不阻塞连接）+ schemas/*.json + manifest；
// 导入 = 选择 zip → 校验 manifest 版本与必需条目 → 先自动导出一份备份 → 整体替换，
// 替换后提示用户重启应用生效（drift 连接在进程内不可热切换，见 applyPendingImport）。
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

/// 导出包内清单（导入时校验版本与必需条目）。
class BackupManifest {
  static const currentVersion = 1;

  const BackupManifest({
    required this.version,
    required this.exportedAt,
    this.appVersion,
  });

  factory BackupManifest.fromJson(Map<String, dynamic> json) => BackupManifest(
    version: (json['version'] as num?)?.toInt() ?? 0,
    exportedAt: (json['exportedAt'] as String?) ?? '',
    appVersion: json['appVersion'] as String?,
  );

  final int version;
  final String exportedAt;
  final String? appVersion;

  Map<String, dynamic> toJson() => {
    'version': version,
    'exportedAt': exportedAt,
    if (appVersion != null) 'appVersion': appVersion,
  };
}

/// 导入校验失败（中文问题列表，UI 直接展示）。
class BackupValidationException implements Exception {
  const BackupValidationException(this.issues);

  final List<String> issues;

  @override
  String toString() => '导入包校验失败：${issues.join('；')}';
}

class BackupService {
  BackupService({
    required this.dbFile,
    required this.schemasDir,
    required this.exportsDir,
    this.appVersion,
    this.snapshotDb,
  });

  /// drift 主库文件（app.db）。
  final File dbFile;

  /// Schema 注册表目录（schemas/）。
  final Directory schemasDir;

  /// 导出落盘目录（exports/，不存在自动创建）。
  final Directory exportsDir;

  /// 打进 manifest 的应用版本（package_info，可空）。
  final String? appVersion;

  /// SQLite 一致性快照执行器（页面层注入 drift `VACUUM INTO` 包装；
  /// 未注入时退化为文件复制，纯单测环境注入假快照）。
  final Future<void> Function(File target)? snapshotDb;

  static const _dbEntryName = 'app.db';
  static const _manifestEntryName = 'manifest.json';
  static const _schemasPrefix = 'schemas/';

  /// 导出全量 zip 到 [destination]：`creative_kb-export-<时间戳>.zip`。
  Future<File> exportTo(Directory destination) async {
    await destination.create(recursive: true);
    final stamp = _timestamp();
    final file = File(
      p.join(destination.path, 'creative_kb-export-$stamp.zip'),
    );
    final archive = Archive();

    final snapshot = File(p.join(destination.path, '.snapshot-$stamp.db'));
    try {
      await _createSnapshot(snapshot);
      archive.addFile(_entryFromFile(snapshot, _dbEntryName));
    } finally {
      if (snapshot.existsSync()) await snapshot.delete();
    }

    if (schemasDir.existsSync()) {
      for (final entity in schemasDir.listSync()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.json')) {
          archive.addFile(
            _entryFromFile(entity, '$_schemasPrefix${p.basename(entity.path)}'),
          );
        }
      }
    }

    final manifest = BackupManifest(
      version: BackupManifest.currentVersion,
      exportedAt: DateTime.now().toIso8601String(),
      appVersion: appVersion,
    );
    archive.addFile(
      ArchiveFile.string(
        _manifestEntryName,
        const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      ),
    );

    final bytes = ZipEncoder().encode(archive);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _createSnapshot(File target) async {
    final snapshot = snapshotDb;
    if (snapshot != null) {
      await snapshot(target);
      return;
    }
    if (!dbFile.existsSync()) {
      await target.writeAsBytes(const []);
      return;
    }
    // 未注入 executor 的退化路径：直接复制（导出为低频操作，占用风险可接受）。
    if (target.existsSync()) await target.delete();
    await target.writeAsBytes(await dbFile.readAsBytes(), flush: true);
  }

  /// 导入 zip：校验 → 整体替换 schemas 与库文件（先自动备份当前数据到 exports/）。
  /// 库文件写到 `app.db.imported` 暂存（drift 连接持有旧句柄，不能热覆盖），
  /// 重启时由 [applyPendingImport] 换入。
  Future<File> importFrom(List<int> zipBytes) async {
    final issues = <String>[];
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (_) {
      throw const BackupValidationException(['不是合法的 zip 包']);
    }

    BackupManifest? manifest;
    ArchiveFile? dbEntry;
    final schemaEntries = <ArchiveFile>[];
    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (file.name == _dbEntryName) {
        dbEntry = file;
      } else if (file.name == _manifestEntryName) {
        try {
          manifest = BackupManifest.fromJson(
            jsonDecode(utf8.decode(file.content)) as Map<String, dynamic>,
          );
        } catch (_) {
          issues.add('manifest.json 损坏');
        }
      } else if (file.name.startsWith(_schemasPrefix) &&
          file.name.toLowerCase().endsWith('.json')) {
        schemaEntries.add(file);
      }
    }
    if (dbEntry == null) issues.add('缺少 $_dbEntryName（不是本应用的导出包）');
    if (manifest == null && issues.isEmpty) issues.add('缺少 manifest.json');
    if (manifest != null && manifest.version > BackupManifest.currentVersion) {
      issues.add(
        '导出包版本（${manifest.version}）高于当前应用支持版本'
        '（${BackupManifest.currentVersion}），请先升级应用',
      );
    }
    if (issues.isNotEmpty) {
      throw BackupValidationException(issues);
    }

    // 操作前自动备份当前数据（docs/02 模块E）。
    final backup = await exportTo(exportsDir);

    // 整体替换 schemas。
    if (schemasDir.existsSync()) {
      for (final entity in schemasDir.listSync()) {
        if (entity is File) await entity.delete();
      }
    } else {
      await schemasDir.create(recursive: true);
    }
    for (final entry in schemaEntries) {
      final out = File(p.join(schemasDir.path, p.basename(entry.name)));
      await out.writeAsBytes(entry.content, flush: true);
    }

    await dbFile.parent.create(recursive: true);
    final staged = File('${dbFile.path}.imported');
    await staged.writeAsBytes(dbEntry!.content, flush: true);
    return backup;
  }

  /// 启动入口调用（main.dart，打开数据库前）：存在待换入的 app.db.imported
  /// 时原子替换并清理旧库 -wal/-shm。返回是否发生了导入替换。
  static Future<bool> applyPendingImport(File dbFile) async {
    final staged = File('${dbFile.path}.imported');
    if (!staged.existsSync()) return false;
    for (final suffix in ['-wal', '-shm']) {
      final side = File('${dbFile.path}$suffix');
      if (side.existsSync()) await side.delete();
    }
    await staged.copy(dbFile.path);
    await staged.delete();
    return true;
  }

  /// 列出 exports/ 下已有导出包（新的在前）。
  Future<List<File>> listExported() async {
    if (!exportsDir.existsSync()) return const [];
    final files =
        exportsDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.zip'))
            .toList()
          ..sort((a, b) => b.path.compareTo(a.path));
    return files;
  }
}

ArchiveFile _entryFromFile(File file, String name) {
  final bytes = file.readAsBytesSync();
  return ArchiveFile.bytes(name, bytes);
}

String _timestamp() {
  final now = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${now.year}${two(now.month)}${two(now.day)}-'
      '${two(now.hour)}${two(now.minute)}${two(now.second)}';
}
