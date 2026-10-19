import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/core/db/database_provider.dart';
import 'package:creative_kb/features/prompts/models/prompt_models.dart';
import 'package:creative_kb/features/prompts/pages/prompt_detail_page.dart';
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

  Future<void> pumpDetail(WidgetTester tester, int promptId) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: PromptDetailPage(promptId: promptId)),
      ),
    );
  }

  testWidgets('展示标题/变量面板/版本历史，仅历史版本提供回滚', (tester) async {
    final promptId = await repository.create(
      title: '回滚示例',
      type: PromptType.novel,
      body: 'V1 正文',
      variables: const [PromptVariable(name: '主角', desc: '人物姓名')],
    );
    await repository.saveNewVersion(
      promptId: promptId,
      body: 'V2 正文',
      note: '扩写丰富',
    );

    await pumpDetail(tester, promptId);
    await tester.pumpAndSettle();

    expect(find.text('回滚示例'), findsOneWidget);
    expect(find.text('变量（1）'), findsOneWidget);
    expect(find.text('V2 正文'), findsOneWidget);
    expect(find.text('初始版本'), findsOneWidget);
    expect(find.text('扩写丰富'), findsOneWidget);
    // 当前版本（V2）不显示回滚，只有历史版本（V1）显示。
    expect(find.widgetWithText(TextButton, '回滚'), findsOneWidget);
  });

  testWidgets('一键回滚：正文回到目标版本，回滚作为新版本保留在历史中', (tester) async {
    final promptId = await repository.create(
      title: '回滚示例',
      type: PromptType.novel,
      body: 'V1 正文',
    );
    await repository.saveNewVersion(
      promptId: promptId,
      body: 'V2 正文',
      note: '扩写丰富',
    );

    await pumpDetail(tester, promptId);
    await tester.pumpAndSettle();
    expect(find.text('V2 正文'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '回滚'));
    await tester.pumpAndSettle();
    expect(find.text('回滚版本'), findsOneWidget); // 确认弹窗

    await tester.tap(find.widgetWithText(FilledButton, '回滚'));
    await tester.pumpAndSettle();

    // 走完 UI 流程后校验库内状态：body 回到 V1，历史共 3 条。
    final prompt = (await repository.byId(promptId))!;
    expect(prompt.body, 'V1 正文');
    final versions = await db.promptVersionsDao.byPrompt(promptId);
    expect(versions, hasLength(3));
    expect(versions.first.note, contains('回滚自版本'));
    expect(versions.first.body, 'V1 正文');
  });
}
