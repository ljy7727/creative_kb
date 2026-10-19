// 灵感碎片首页 widget 测试：无 Key 引导、手动录入、Ctrl+Enter 提交 + AI 拆分链路。
import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/core/db/database_provider.dart';
import 'package:creative_kb/features/fragments/pages/fragments_page.dart';
import 'package:creative_kb/features/fragments/services/fragment_ai_invoker.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

class _ScriptedInvoker implements FragmentAiInvoker {
  _ScriptedInvoker(this.replies);

  final List<Object> replies;
  int callCount = 0;

  @override
  Future<FragmentAiReply> invoke(FragmentAiRequest request) async {
    callCount += 1;
    final step = replies.isEmpty
        ? '"无脚本"'
        : replies[callCount - 1 < replies.length
              ? callCount - 1
              : replies.length - 1];
    if (step is Exception) throw step;
    return FragmentAiReply(
      content: step as String,
      inputTokens: 10,
      outputTokens: 10,
    );
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedModel() async {
    final providerId = await db.providersDao.add(
      ProvidersCompanion.insert(
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com/v1',
        presetCode: 'deepseek',
        keyRef: const Value('key_main'),
      ),
    );
    await db.modelsDao.upsertModelId(
      providerId: providerId,
      modelId: 'deepseek-chat',
      displayName: 'DeepSeek Chat',
    );
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    FragmentAiInvoker? invoker,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          if (invoker != null)
            fragmentAiInvokerProvider.overrideWithValue(invoker),
        ],
        child: const MaterialApp(home: FragmentsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder entryField() =>
      find.widgetWithText(TextField, '随手记下灵感，Enter 换行，Ctrl+Enter 提交');

  testWidgets('未配置 Key：AI 复选框置灰并可手动录入原始记录', (tester) async {
    await pumpPage(tester);

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(
      checkbox.onChanged,
      isNull,
      reason: 'docs/02 B3：无 Key 时 AI 复选框 disabled',
    );

    await tester.enterText(entryField(), '随手记一条原始灵感');
    await tester.tap(find.text('保存灵感'));
    await tester.pumpAndSettle();

    // 列表出现该卡片，且状态为「原始」。
    expect(find.textContaining('随手记一条原始灵感'), findsOneWidget);
    expect(find.text('原始'), findsOneWidget);

    final rows = await db.fragmentsDao.getAll();
    expect(rows, hasLength(1));
    expect(rows.single.status, FragmentStatus.raw);
    expect(rows.single.source, FragmentSource.manual);
    expect(await db.select(db.taskQueue).get(), isEmpty, reason: '手动保存不入队');

    // 推走 SnackBar 的 4 秒自动消失时钟，避免测试结束遗留 Timer。
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('已配置模型：勾选 AI 后 Ctrl+Enter 提交，两主题拆分入库并展示', (tester) async {
    await seedModel();
    final invoker = _ScriptedInvoker([tangBoardAiJson]);
    await pumpPage(tester, invoker: invoker);

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.onChanged, isNotNull, reason: '已配置 Key 与启用模型时可勾选');
    expect(checkbox.value, isTrue);

    await tester.enterText(entryField(), tangBoardInput);
    // Ctrl+Enter 提交（docs/02 B1）。
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    // 输入框已清空。
    expect(tester.widget<TextField>(entryField()).controller!.text, isEmpty);

    final rows = await db.fragmentsDao.getAll();
    expect(rows, hasLength(2), reason: '唐朝笏板示例两主题应拆分为两行');
    expect(
      rows.where((r) => r.status == FragmentStatus.optimized),
      hasLength(2),
    );
    expect(invoker.callCount, 1);
    expect(find.textContaining('笏板'), findsWidgets);
  });

  testWidgets('AI 输出非法时展示中文错误提示，原始记录保留', (tester) async {
    await seedModel();
    final invoker = _ScriptedInvoker(['"不是契约输出"', '"仍然不对"', '{"bad":1}']);
    await pumpPage(tester, invoker: invoker);

    await tester.enterText(entryField(), '会失败的一条灵感');
    await tester.tap(find.text('保存灵感'));
    await tester.pumpAndSettle();

    expect(find.textContaining('AI 输出不符合约定格式'), findsOneWidget);

    final rows = await db.fragmentsDao.getAll();
    expect(rows.single.status, FragmentStatus.failed);
    expect(find.textContaining('会失败的一条灵感'), findsOneWidget, reason: '原文仍在列表中');

    // SnackBar 默认 4 秒自动消失：推走时钟避免测试结束时遗留 Timer。
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
