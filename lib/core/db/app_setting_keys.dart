/// app_settings 表 key 常量。值一律为字符串，数值/布尔由上层转换。
abstract final class AppSettingKeys {
  /// 单次任务 max_tokens 封顶（docs/02 A5）。
  static const singleTaskMaxTokens = 'limits.single_task_max_tokens';

  /// 当日 input+output token 总量上限，超过则任务置 blocked。
  static const dailyMaxTokens = 'limits.daily_max_tokens';

  /// 全局默认思考强度预设 code（fast|standard|deep|custom）。
  static const defaultIntensity = 'llm.default_intensity';

  /// 资料库「极速入库模式」开关，默认关（docs/02 D2）。
  static const quickIngest = 'kb.quick_ingest';

  /// 更新检查仓库 owner/repo，默认占位（docs/02 A6）。
  static const updateRepo = 'update.repo';

  /// 启动时自动检查更新，默认开。
  static const updateAutoCheck = 'update.auto_check';
}
