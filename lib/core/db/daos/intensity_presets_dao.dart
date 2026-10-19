part of '../database.dart';

/// intensity_presets 表 DAO。
@DriftAccessor(tables: [IntensityPresets])
class IntensityPresetsDao extends DatabaseAccessor<AppDatabase> with _$IntensityPresetsDaoMixin {
  IntensityPresetsDao(super.db);

  Stream<List<IntensityPreset>> watchAll() =>
      (select(intensityPresets)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  Future<List<IntensityPreset>> getAll() => select(intensityPresets).get();

  Future<IntensityPreset?> byCode(String code) =>
      (select(intensityPresets)..where((t) => t.code.equals(code))).getSingleOrNull();

  /// 内置预设种子写入：只补缺，不覆盖用户已有的自定义修改。
  Future<void> insertIfAbsent({
    required String code,
    required String name,
    required String paramsJson,
    bool isBuiltin = false,
  }) async {
    if (await byCode(code) != null) return;
    await into(intensityPresets).insert(IntensityPresetsCompanion.insert(
      code: code,
      name: name,
      params: Value(paramsJson),
      isBuiltin: Value(isBuiltin),
    ));
  }

  /// 保存自定义预设参数（custom 档，docs/02 A4）。
  Future<void> updateParams(String code, String paramsJson) =>
      (update(intensityPresets)..where((t) => t.code.equals(code)))
          .write(IntensityPresetsCompanion(params: Value(paramsJson)));
}
