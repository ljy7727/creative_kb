// token 记账 + 额度防护（docs/01 core/tasks/usage_ledger.dart，docs/02 A5）。
// 约定：记账行只由 TaskRunner 在任务收尾时统一写入（成功/失败/拦截都记），
// 业务 handler 仅通过 TaskContext.reportUsage 上报，避免重复记账。
import 'package:drift/drift.dart';

import '../db/app_setting_keys.dart';
import '../db/database.dart';
import '../seed/price_table.dart';

/// handler 单次（或单次调用中分段）上报的用量。
class UsageReport {
  const UsageReport({
    required this.providerName,
    required this.model,
    this.presetCode,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.durationMs = 0,
  });

  final String providerName;
  final String model;
  final String? presetCode;
  final int inputTokens;
  final int outputTokens;
  final int durationMs;
}

/// 当日额度快照（docs/01 第三节：超日上限直接 blocked）。
class QuotaSnapshot {
  const QuotaSnapshot({required this.usedTokens, this.limitTokens});

  /// 当日（本地时区）input+output token 合计。
  final int usedTokens;

  /// 日上限；null = 未设置/非法值，不设限。
  final int? limitTokens;

  /// 已用达到上限即视为超额（再放行必然突破上限）。
  bool get exceeded =>
      limitTokens != null && limitTokens! > 0 && usedTokens >= limitTokens!;

  String blockedMessage() =>
      '当日额度已用尽：已用 $usedTokens / 上限 $limitTokens token，任务被拦截';
}

class UsageLedger {
  UsageLedger(this._db);

  final AppDatabase _db;

  /// 日上限（token）。设置缺失、非数字或 ≤0 视为不设限。
  Future<int?> dailyTokenLimit() =>
      _readPositiveInt(AppSettingKeys.dailyMaxTokens);

  /// 单次任务 max_tokens 封顶。设置缺失、非数字或 ≤0 视为不封顶。
  Future<int?> singleTaskTokenCap() =>
      _readPositiveInt(AppSettingKeys.singleTaskMaxTokens);

  Future<QuotaSnapshot> dailyUsage({DateTime? now}) async => QuotaSnapshot(
    usedTokens: await _db.usageLogDao.todayTokens(now: now),
    limitTokens: await dailyTokenLimit(),
  );

  /// 任务收尾统一落账：每份 UsageReport 一行；无上报且 [writeSyntheticWhenEmpty]
  /// 为真时补一行零 token 记录，保证「成功失败都记」（docs/02 A5）。
  Future<void> writeTaskReports({
    required String module,
    required String taskType,
    required List<UsageReport> reports,
    required UsageStatus status,
    String? error,
    int fallbackDurationMs = 0,
    bool writeSyntheticWhenEmpty = true,
  }) async {
    if (reports.isEmpty) {
      if (!writeSyntheticWhenEmpty) return;
      await _insert(
        module: module,
        taskType: taskType,
        providerName: '',
        model: '',
        presetCode: null,
        inputTokens: 0,
        outputTokens: 0,
        durationMs: fallbackDurationMs,
        status: status,
        error: error,
      );
      return;
    }
    for (final report in reports) {
      await _insert(
        module: module,
        taskType: taskType,
        providerName: report.providerName,
        model: report.model,
        presetCode: report.presetCode,
        inputTokens: report.inputTokens,
        outputTokens: report.outputTokens,
        durationMs: report.durationMs > 0
            ? report.durationMs
            : fallbackDurationMs,
        status: status,
        error: error,
      );
    }
  }

  /// 日额度拦截记录（status=blocked，docs/01 第三节）。
  Future<void> recordBlocked({
    required String module,
    required String taskType,
    required String error,
  }) => _insert(
    module: module,
    taskType: taskType,
    providerName: '',
    model: '',
    presetCode: null,
    inputTokens: 0,
    outputTokens: 0,
    durationMs: 0,
    status: UsageStatus.blocked,
    error: error,
  );

  /// 费用估算查内置价格表（docs/00 D5）：查不到只记 token，costEstimate 为 null。
  Future<void> _insert({
    required String module,
    required String taskType,
    required String providerName,
    required String model,
    required String? presetCode,
    required int inputTokens,
    required int outputTokens,
    required int durationMs,
    required UsageStatus status,
    String? error,
  }) {
    return _db.usageLogDao.add(
      UsageLogsCompanion.insert(
        module: module,
        taskType: taskType,
        providerName: providerName,
        model: model,
        presetCode: Value(presetCode),
        inputTokens: Value(inputTokens),
        outputTokens: Value(outputTokens),
        costEstimate: Value(
          PriceTable.estimateCost(
            modelId: model,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
          ),
        ),
        durationMs: Value(durationMs),
        status: status,
        error: Value(error),
      ),
    );
  }

  Future<int?> _readPositiveInt(String key) async {
    final raw = await _db.appSettingsDao.get(key);
    final value = int.tryParse(raw ?? '');
    return (value == null || value <= 0) ? null : value;
  }
}
