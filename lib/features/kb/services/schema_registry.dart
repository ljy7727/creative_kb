import 'dart:convert';
import 'dart:io';

import '../../../core/seed/app_seeder.dart';
import '../models/kb_schema.dart';

/// Schema 注册表（docs/02 D1）：读取应用数据目录 schemas/*.json。
/// 每次调用都重新读盘 —— 用户/设置页编辑 JSON 后无需重启即生效（热加载）。
/// 单个损坏文件跳过不阻塞其余 Schema。
class SchemaRegistry {
  SchemaRegistry(this.directory);

  final Directory directory;

  bool get exists => directory.existsSync();

  /// 读取全部合法 Schema；目录不存在时返回内置通用兜底。
  Future<List<KbSchema>> load() async {
    if (!exists) return [KbSchema.fallbackGeneral()];
    final files = <File>[];
    for (final entity in directory.listSync()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.json')) {
        files.add(entity);
      }
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    final schemas = <KbSchema>[];
    for (final file in files) {
      try {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) {
          schemas.add(KbSchema.fromJson(decoded));
        }
      } catch (_) {
        // 损坏的用户文件：跳过，等待设置页修复。
      }
    }
    if (schemas.isEmpty) return [KbSchema.fallbackGeneral()];
    return schemas;
  }

  Future<KbSchema?> byId(String id) async {
    return schemaById(await load(), id);
  }

  /// 按 matchKeywords 命中推荐（docs/02 D1）。
  Future<KbSchema> suggest(String text) async {
    return suggestSchemaFor(await load(), text);
  }

  /// 保存（新增/编辑）：写 `<id>.json`；写盘即生效（读侧每次重读目录）。
  Future<File> save(KbSchema schema) async {
    if (schema.id.trim().isEmpty) {
      throw const FormatException('Schema id 不能为空');
    }
    await directory.create(recursive: true);
    final file = File(
      '${directory.path}${Platform.pathSeparator}${schema.id}.json',
    );
    await file.writeAsString(schema.encode(), flush: true);
    return file;
  }

  /// 删除 Schema 文件。不存在时静默。
  Future<void> delete(String id) async {
    final file = File('${directory.path}${Platform.pathSeparator}$id.json');
    if (await file.exists()) await file.delete();
  }

  /// 内置 4 套补盘（不覆盖已有文件）。常规首启由 AppSeeder 完成，此处供修复入口复用。
  Future<List<File>> restoreBuiltin() async {
    return writeBuiltinSchemas(directory);
  }
}
