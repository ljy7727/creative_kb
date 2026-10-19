import 'dart:convert';

import '../../../core/db/database.dart';

/// 嵌入模型选择设置 key（本模块自管；app_setting_keys.dart 为骨架定稿不改）。
/// 值为 JSON：`{"providerId":int,"model":str}`。设置页据此提供「向量化模型」下拉。
const kbEmbeddingModelSettingKey = 'kb.embedding_model';

/// 已解析的嵌入模型配置（provider 必须存在且已配置 Key，否则视为未配置 → 检索降级）。
class KbEmbeddingConfig {
  const KbEmbeddingConfig({
    required this.providerId,
    required this.providerName,
    required this.model,
  });

  final int providerId;
  final String providerName;
  final String model;

  String get label => '$providerName / $model';
}

abstract final class KbEmbeddingConfigResolver {
  /// 读取设置并校验 provider 存在、已配 Key（keyRef 非空）。
  /// 任一条件不满足返回 null（调用方降级纯 FTS，docs/00 D7）。
  static Future<KbEmbeddingConfig?> resolve(AppDatabase db) async {
    final raw = await db.appSettingsDao.get(kbEmbeddingModelSettingKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final providerId = (decoded['providerId'] as num?)?.toInt();
      final model = decoded['model'] as String?;
      if (providerId == null || model == null || model.isEmpty) return null;
      final provider = await db.providersDao.byId(providerId);
      if (provider == null || (provider.keyRef ?? '').isEmpty) return null;
      return KbEmbeddingConfig(
        providerId: providerId,
        providerName: provider.name,
        model: model,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(
    AppDatabase db, {
    required int providerId,
    required String model,
  }) {
    return db.appSettingsDao.set(
      kbEmbeddingModelSettingKey,
      jsonEncode({'providerId': providerId, 'model': model}),
    );
  }

  static Future<void> clear(AppDatabase db) =>
      db.appSettingsDao.set(kbEmbeddingModelSettingKey, '');
}
