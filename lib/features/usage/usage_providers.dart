// 用量看板状态层（docs/02 A5）。
// usage_log 任何写入都会让 watchRecent 重发；以递增序号作为时钟驱动聚合刷新，
// 避免为看板新增 DAO 查询流。
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/db/database_provider.dart';

/// usage_log 变更序号（每次重发自增 1）。
final usageTickProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  var ticks = 0;
  return db.usageLogDao.watchRecent(limit: 1).map((_) => ++ticks);
});

/// 最近 50 条明细（docs/02 A5）。
final usageRecentProvider = StreamProvider<List<UsageLogEntry>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.usageLogDao.watchRecent(limit: 50);
});

/// 看板聚合：今日/累计 token 与费用、按模块/模型 output token 分布。
class UsageTotals {
  const UsageTotals({
    required this.todayInput,
    required this.todayOutput,
    required this.todayCost,
    required this.totalInput,
    required this.totalOutput,
    required this.totalCost,
    required this.outputByModule,
    required this.outputByModel,
  });

  final int todayInput;
  final int todayOutput;
  final double todayCost;
  final int totalInput;
  final int totalOutput;
  final double totalCost;
  final Map<String, int> outputByModule;
  final Map<String, int> outputByModel;

  int get todayTotal => todayInput + todayOutput;
  int get totalTokens => totalInput + totalOutput;
}

final usageTotalsProvider = FutureProvider<UsageTotals>((ref) async {
  ref.watch(usageTickProvider);
  final db = ref.watch(appDatabaseProvider);
  final dao = db.usageLogDao;

  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day);
  final (todayIn, todayOut) = await dao.usageBetween(
    dayStart,
    dayStart.add(const Duration(days: 1)),
  );
  final (totalIn, totalOut) = await dao.usageBetween(
    DateTime.fromMillisecondsSinceEpoch(0),
    DateTime(9999, 12, 31),
  );

  final byModule = await dao.sumOutputTokensBy(db.usageLogs.module);
  final byModel = await dao.sumOutputTokensBy(db.usageLogs.model);

  return UsageTotals(
    todayInput: todayIn,
    todayOutput: todayOut,
    todayCost: await _sumCost(db, since: dayStart),
    totalInput: totalIn,
    totalOutput: totalOut,
    totalCost: await _sumCost(db),
    outputByModule: byModule,
    outputByModel: byModel,
  );
});

/// 费用参考合计（costEstimate 为 null 的行不计入）。
Future<double> _sumCost(AppDatabase db, {DateTime? since}) async {
  final total = db.usageLogs.costEstimate.sum();
  final query = db.selectOnly(db.usageLogs)..addColumns([total]);
  if (since != null) {
    query.where(db.usageLogs.ts.isBiggerOrEqualValue(since));
  }
  final row = await query.getSingle();
  return row.read<double>(total) ?? 0;
}
