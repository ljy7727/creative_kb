// 用量看板 widget 测试：汇总卡片/图表/明细渲染、空态、费用 "—" 列。
import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/core/db/database_provider.dart';
import 'package:creative_kb/features/usage/pages/usage_page.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedRows() async {
    await db.usageLogDao.add(
      UsageLogsCompanion.insert(
        module: 'fragments',
        taskType: 'optimize',
        providerName: 'DeepSeek',
        model: 'deepseek-chat',
        status: UsageStatus.ok,
        presetCode: const Value('fast'),
        inputTokens: const Value(1000),
        outputTokens: const Value(500),
        costEstimate: const Value(0.006),
        durationMs: const Value(800),
      ),
    );
    await db.usageLogDao.add(
      UsageLogsCompanion.insert(
        module: 'kb',
        taskType: 'ingest',
        providerName: '',
        model: '',
        status: UsageStatus.blocked,
        error: const Value('当日额度已用尽'),
      ),
    );
  }

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: UsagePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('渲染汇总卡片、双图表与明细表（费用无价显示 —）', (tester) async {
    await seedRows();
    await pumpPage(tester);

    expect(find.text('用量统计'), findsOneWidget);
    expect(find.text('今日 token'), findsOneWidget);
    expect(find.text('累计 token'), findsOneWidget);
    // 今日 1000+500=1500，累计相同。
    expect(find.text('1,500'), findsNWidgets(2));
    expect(find.text('按模块占比（输出 token）'), findsOneWidget);
    expect(find.text('按模型柱状（输出 token）'), findsOneWidget);
    expect(find.textContaining('最近明细'), findsOneWidget);
    // 明细行与状态 chips。
    expect(find.text('deepseek-chat'), findsWidgets);
    expect(find.text('已拦截'), findsWidgets);
    expect(find.text('成功'), findsWidgets);
    // 被拦截行无模型无价格 → 两处 "—"。
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('空库显示空态引导', (tester) async {
    await pumpPage(tester);
    expect(find.text('暂无用量记录'), findsOneWidget);
  });
}
