import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/core/db/database_provider.dart';
import 'package:creative_kb/features/prompts/pages/prompts_page.dart';
import 'package:creative_kb/features/prompts/services/prompt_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PromptRepository repository;

  setUp(() {
    db = AppDatabase.inMemory();
    repository = PromptRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpPage(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: PromptsPage()),
      ),
    );
  }

  testWidgets('列表展示提示词，类型筛选 chips 联动', (tester) async {
    await repository.create(
      title: '笏板场景',
      type: PromptType.novel,
      body: '水墨山河',
      category: '场景',
    );
    await repository.create(
      title: '赛博城市',
      type: PromptType.image,
      body: '霓虹雨夜',
    );

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('笏板场景'), findsOneWidget);
    expect(find.text('赛博城市'), findsOneWidget);

    await tester.tap(find.text('AI 绘画'));
    await tester.pumpAndSettle();

    expect(find.text('赛博城市'), findsOneWidget);
    expect(find.text('笏板场景'), findsNothing);

    // 切回全部类型恢复展示。
    await tester.tap(find.text('全部类型'));
    await tester.pumpAndSettle();
    expect(find.text('笏板场景'), findsOneWidget);
  });

  testWidgets('关键词检索不命中时显示空态引导', (tester) async {
    await repository.create(
      title: '笏板场景',
      type: PromptType.novel,
      body: '水墨山河',
    );

    await pumpPage(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '不存在的关键词xyz');
    await tester.pumpAndSettle();

    expect(find.text('还没有提示词'), findsOneWidget);
    expect(find.text('笏板场景'), findsNothing);
  });
}
