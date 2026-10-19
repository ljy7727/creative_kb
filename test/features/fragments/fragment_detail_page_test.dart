// 灵感详情页 widget 测试：双版本对比展示、转提示词/资料条目跳转参数、
// 重新优化（换强度重跑）、删除后返回。
import 'dart:convert';

import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/core/db/database_provider.dart';
import 'package:creative_kb/core/router.dart';
import 'package:creative_kb/features/fragments/models/fragment_models.dart';
import 'package:creative_kb/features/fragments/pages/fragment_detail_page.dart';
import 'package:creative_kb/features/fragments/services/fragment_ai_invoker.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

class _ScriptedInvoker implements FragmentAiInvoker {
  _ScriptedInvoker(this.replies);

  final List<Object> replies;
  int callCount = 0;

  @override
  Future<FragmentAiReply> invoke(FragmentAiRequest request) async {
    final index = callCount < replies.length ? callCount : replies.length - 1;
    callCount += 1;
    final step = replies[index];
    if (step is Exception) throw step;
    return FragmentAiReply(
      content: step as String,
      inputTokens: 30,
      outputTokens: 20,
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

  Future<int> seedOptimizedFragment() async {
    const item = FragmentOptimizeItem(
      title: '唐朝笏板：朝会奏对提词器',
      content: '**笏板即提词器。** 唐代大臣上朝手持笏板记录奏对要点。',
      tags: ['#设定-器物', '#历史-唐朝'],
    );
    final meta = FragmentAiMeta(
      providerName: 'DeepSeek',
      model: 'deepseek-chat',
      presetCode: 'standard',
      inputTokens: 100,
      outputTokens: 50,
      ts: DateTime(2026, 10, 19, 8),
    );
    return db.fragmentsDao.add(
      FragmentsCompanion.insert(
        rawText: tangBoardInput,
        source: FragmentSource.manual,
        title: Value(item.title),
        optimizedJson: Value(jsonEncode(item.toJson())),
        tags: Value(encodeTags(item.tags)),
        aiMeta: Value(meta.encode()),
        status: const Value(FragmentStatus.optimized),
      ),
    );
  }

  Future<void> pumpDetail(
    WidgetTester tester, {
    required int fragmentId,
    FragmentAiInvoker? invoker,
    List<RouteSettings>? pushed,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          if (invoker != null)
            fragmentAiInvokerProvider.overrideWithValue(invoker),
        ],
        child: MaterialApp(
          onGenerateRoute: (settings) {
            pushed?.add(settings);
            // 详情路由接真实页面（顺带覆盖 fromSettings 参数提取）；
            // 其余跳转目标（提示词/资料库）给占位页。
            if (settings.name == RoutePaths.fragmentDetail) {
              return MaterialPageRoute<void>(
                builder: (_) => FragmentDetailPage.fromSettings(settings),
              );
            }
            return MaterialPageRoute<void>(
              builder: (_) => Scaffold(body: Text('目标页：${settings.name}')),
            );
          },
          home: const Scaffold(body: Center(child: Text('灵感列表'))),
        ),
      ),
    );
    // 经命名路由推入详情页，保证删除后可 pop 回列表。
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed(
      RoutePaths.fragmentDetail,
      arguments: {RouteArgs.fragmentId: fragmentId},
    );
    await tester.pumpAndSettle();
  }

  testWidgets('双版本对比：原始记录与 AI 整理（Markdown）同屏展示', (tester) async {
    final fragmentId = await seedOptimizedFragment();
    await pumpDetail(tester, fragmentId: fragmentId);

    expect(find.text('原始记录'), findsOneWidget);
    expect(find.text('AI 整理'), findsOneWidget);
    // AI 版本渲染 Markdown 正文（RichText 文本）。
    expect(find.textContaining('笏板即提词器'), findsWidgets);
    // aiMeta 行展示模型与 token 记录。
    expect(find.textContaining('deepseek-chat'), findsOneWidget);
    expect(find.textContaining('输入 100 / 输出 50 token'), findsOneWidget);
  });

  testWidgets('转为提示词草稿 / 转为资料条目：命名路由携带 fragmentId', (tester) async {
    final fragmentId = await seedOptimizedFragment();
    final pushed = <RouteSettings>[];
    await pumpDetail(tester, fragmentId: fragmentId, pushed: pushed);

    await tester.tap(find.text('转为提示词草稿'));
    await tester.pumpAndSettle();
    expect(pushed.last.name, RoutePaths.promptGenerate);
    expect((pushed.last.arguments as Map)[RouteArgs.fragmentId], fragmentId);

    // 返回详情页再验证第二条跳转（目标页会遮住详情页按钮）。
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('转为资料条目'));
    await tester.pumpAndSettle();
    expect(pushed.last.name, RoutePaths.kbIngest);
    expect((pushed.last.arguments as Map)[RouteArgs.fragmentId], fragmentId);
  });

  testWidgets('重新优化：选择新强度后重跑并更新内容', (tester) async {
    await seedModel();
    await db.intensityPresetsDao.insertIfAbsent(
      code: 'fast',
      name: '极速',
      paramsJson: '{"temperature":0.3,"maxTokens":2048}',
      isBuiltin: true,
    );
    final fragmentId = await seedOptimizedFragment();
    final invoker = _ScriptedInvoker([singleItemAiJson]);
    await pumpDetail(tester, fragmentId: fragmentId, invoker: invoker);

    await tester.tap(find.text('重新优化'));
    await tester.pumpAndSettle();
    expect(find.text('选择强度重新优化'), findsOneWidget);

    await tester.tap(find.text('极速'));
    await tester.pumpAndSettle();

    expect(invoker.callCount, 1);
    final updated = await db.fragmentsDao.byId(fragmentId);
    expect(updated!.title, '整合后的单条灵感');
    expect(find.text('整合后的单条灵感'), findsOneWidget);
  });

  testWidgets('删除：确认后连带派生行一并删除并返回列表', (tester) async {
    final fragmentId = await seedOptimizedFragment();
    // 一条拆分派生行（aiMeta.originId 指向原行）。
    final derivedMeta = FragmentAiMeta(
      providerName: 'DeepSeek',
      model: 'deepseek-chat',
      presetCode: 'standard',
      ts: DateTime(2026, 10, 19, 8),
      originId: fragmentId,
    );
    await db.fragmentsDao.add(
      FragmentsCompanion.insert(
        rawText: tangBoardInput,
        source: FragmentSource.ai,
        aiMeta: Value(derivedMeta.encode()),
        status: const Value(FragmentStatus.optimized),
      ),
    );

    await pumpDetail(tester, fragmentId: fragmentId);

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除这条灵感？'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(await db.fragmentsDao.getAll(), isEmpty, reason: '原行与派生行都已删除');
    expect(find.text('灵感列表'), findsOneWidget, reason: '删除后应 pop 回列表');
  });
}
