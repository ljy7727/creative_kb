part of '../database.dart';

/// usage_log 表 DAO：记账写入 + 用量看板聚合（docs/02 A5）。
@DriftAccessor(tables: [UsageLogs])
class UsageLogDao extends DatabaseAccessor<AppDatabase>
    with _$UsageLogDaoMixin {
  UsageLogDao(super.db);

  Future<void> add(UsageLogsCompanion entry) => into(usageLogs).insert(entry);

  /// 最近明细（看板明细表，默认 50 条）。
  Future<List<UsageLogEntry>> recent({int limit = 50}) =>
      (select(usageLogs)
            ..orderBy([
              (t) => OrderingTerm.desc(t.ts),
              (t) => OrderingTerm.desc(t.id),
            ])
            ..limit(limit))
          .get();

  Stream<List<UsageLogEntry>> watchRecent({int limit = 50}) =>
      (select(usageLogs)
            ..orderBy([
              (t) => OrderingTerm.desc(t.ts),
              (t) => OrderingTerm.desc(t.id),
            ])
            ..limit(limit))
          .watch();

  /// [since, until) 区间内的 input/output token 总量。
  Future<(int, int)> usageBetween(DateTime since, DateTime until) async {
    final input = usageLogs.inputTokens.sum();
    final output = usageLogs.outputTokens.sum();
    final query = selectOnly(usageLogs)
      ..addColumns([input, output])
      ..where(
        usageLogs.ts.isBiggerOrEqualValue(since) &
            usageLogs.ts.isSmallerThanValue(until),
      );
    final row = await query.getSingle();
    return (row.read<int>(input) ?? 0, row.read<int>(output) ?? 0);
  }

  /// 当日（本地时区）累计 token，额度防护用（docs/01 第三节）。
  Future<int> todayTokens({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final start = DateTime(at.year, at.month, at.day);
    final (input, output) = await usageBetween(
      start,
      start.add(const Duration(days: 1)),
    );
    return input + output;
  }

  /// 按维度聚合 output token：module 饼图 / model 柱状图（docs/02 A5）。
  Future<Map<String, int>> sumOutputTokensBy(
    Expression<String> dimension, {
    DateTime? since,
  }) async {
    final total = usageLogs.outputTokens.sum();
    final query = selectOnly(usageLogs)
      ..addColumns([dimension, total])
      ..groupBy([dimension]);
    if (since != null) {
      query.where(usageLogs.ts.isBiggerOrEqualValue(since));
    }
    final rows = await query.get();
    final result = <String, int>{};
    for (final row in rows) {
      final key = row.read<String>(dimension);
      if (key != null) result[key] = row.read<int>(total) ?? 0;
    }
    return result;
  }
}
