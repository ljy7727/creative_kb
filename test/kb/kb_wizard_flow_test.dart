import 'dart:convert';
import 'dart:io';

import 'package:creative_kb/core/db/app_setting_keys.dart';
import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/core/db/database_provider.dart';
import 'package:creative_kb/core/seed/app_seeder.dart';
import 'package:creative_kb/features/kb/models/kb_schema.dart';
import 'package:creative_kb/features/kb/pages/kb_ingest_wizard_page.dart';
import 'package:creative_kb/features/kb/services/kb_embedding_config.dart';
import 'package:creative_kb/features/kb/services/kb_ingest_task.dart';
import 'package:creative_kb/features/kb/services/kb_providers.dart';
import 'package:creative_kb/features/kb/services/schema_registry.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_gateway.dart';

/// 青云宗示例 AI 输出（docs/02 D5 验收场景）。
const String qingyunResponse = '''
{
  "cleaned": "青云宗，正道宗门，坐落于青云山脉，护持护山大阵。",
  "proposedCategory": "仙侠设定/势力宗门",
  "proposedSchemaId": "sect",
  "entries": [{
    "entryName": "青云宗",
    "summary": "正道魁首宗门，坐落于青云山脉。",
    "contentMd": "## 层级\\n- 掌门\\n- 长老\\n\\n山门由护山大阵护持，镇派功法为神剑御雷真诀。",
    "tags": ["宗门", "正道"],
    "relatedEntries": ["张小凡"],
    "credibility": "mid",
    "hierarchy": "掌门—长老—内门弟子—外门弟子",
    "location": "青云山脉",
    "inheritance": "神剑御雷真诀",
    "key_figures": "道玄真人",
    "rival_forces": "鬼王宗"
  }]
}
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppDatabase db;
  late FakeKbAiGateway gateway;
  // setUp 在 FakeAsync 区外执行：真实 I/O 可正常完成。
  // testWidgets 体内真实文件 I/O 永不完成（fake async），因此 Schema 一律
  // 预加载进内存并 override 相关 provider（见 pumpWizard）。
  late List<KbSchema> seededSchemas;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('creative_kb_wizard_test');
    db = AppDatabase.inMemory();
    await AppSeeder(db, appDirResolver: () async => tempDir).run();
    seededSchemas = await SchemaRegistry(
      Directory('${tempDir.path}${Platform.pathSeparator}schemas'),
    ).load();
    await db.kbEntriesDao.add(
      KbEntriesCompanion.insert(entryName: '张小凡', categoryPath: '仙侠设定/人物'),
    );
    await db.kbCategoriesDao.ensurePath('仙侠设定/势力宗门');
    gateway = FakeKbAiGateway(const []);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      // Windows 下可能有短暂句柄延迟，重试删除。
      for (var attempt = 0; attempt < 5; attempt++) {
        try {
          await tempDir.delete(recursive: true);
          break;
        } on FileSystemException {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }
    }
  });

  Future<void> pumpWizard(
    WidgetTester tester, {
    bool aiAvailable = true,
    String initialText = '（粘贴的资料原文）',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          schemaDirProvider.overrideWith(
            (ref) async =>
                Directory('${tempDir.path}${Platform.pathSeparator}schemas'),
          ),
          // 体内读盘会卡死 fake async：Schema 用内存预载值。
          schemaRegistryProvider.overrideWith((ref) async => seededSchemas),
          kbAiAvailableProvider.overrideWithValue(AsyncValue.data(aiAvailable)),
          kbAiGatewayProvider.overrideWithValue(gateway),
          kbIngestTaskProvider.overrideWith(
            (ref) => KbIngestTask(
              db,
              gateway: gateway,
              loadSchemas: () async => seededSchemas,
            ),
          ),
        ],
        child: MaterialApp(home: KbIngestWizardPage(initialText: initialText)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('向导 2→5 步数据流：AI 清洗 → 校验映射 → 预览 → 入库+关联+向量化', (tester) async {
    // 配置嵌入模型（provider 带 keyRef + kb.embedding_model 设置），入库后自动向量化。
    final providerId = await db.providersDao.add(
      ProvidersCompanion.insert(
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com/v1',
        presetCode: 'deepseek',
        keyRef: const Value('key_deepseek_main'),
      ),
    );
    await KbEmbeddingConfigResolver.save(
      db,
      providerId: providerId,
      model: 'deepseek-chat',
    );

    gateway.enqueue(qingyunResponse);
    await pumpWizard(tester, initialText: '青云宗，正道宗门，坐落于青云山脉……（原文）');

    // 第 1 → 2 步
    await tester.tap(find.text('下一步：AI 清洗'));
    await tester.pumpAndSettle();
    expect(find.text('AI 清洗并分类'), findsOneWidget);

    // 第 2 → 3 步（AI 成功后自动进入映射）
    await tester.tap(find.text('AI 清洗并分类'));
    await tester.pumpAndSettle();
    expect(find.textContaining('校验映射'), findsWidgets);
    expect(find.textContaining('青云宗'), findsWidgets);

    // 第 3 → 4 步：预览渲染 Markdown
    await tester.tap(find.text('下一步：预览'));
    await tester.pumpAndSettle();
    expect(find.text('第 4 步：预览确认'), findsOneWidget);
    expect(find.byType(MarkdownBody), findsWidgets);
    expect(find.textContaining('护山大阵'), findsWidgets);

    // 第 4 → 5 步：确认入库
    await tester.tap(find.text('下一步：入库'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认入库'));
    await tester.pumpAndSettle();
    expect(find.text('入库完成'), findsOneWidget);

    // 数据流落库断言。
    final entry = await db.kbEntriesDao.byName('青云宗');
    expect(entry, isNotNull);
    expect(entry!.categoryPath, '仙侠设定/势力宗门');
    expect(entry.source, 'ai');
    final extra = jsonDecode(entry.extra) as Map<String, dynamic>;
    expect(extra['location'], '青云山脉');
    expect(extra['rival_forces'], '鬼王宗');

    final zhang = (await db.kbEntriesDao.byName('张小凡'))!;
    final relations = await db.kbRelationsDao.forEntry(entry.id);
    expect(relations, hasLength(2), reason: '与已有条目建立双向关联');
    expect(zhang.id, isPositive);

    // 配置了嵌入模型（fake gateway）→ 入库后自动向量化。
    final vector = await db.embeddingsDao.byEntry(entry.id);
    expect(vector, isNotNull);
    expect(vector!.dim, 2);
    expect(vector.model, 'deepseek-chat');
    expect(gateway.embedCalls, 1);
  });

  testWidgets('极速入库模式：映射后跳过预览步直接入库', (tester) async {
    await db.appSettingsDao.set(AppSettingKeys.quickIngest, 'true');
    gateway.enqueue(qingyunResponse);
    await pumpWizard(tester);

    await tester.tap(find.text('下一步：AI 清洗'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI 清洗并分类'));
    await tester.pumpAndSettle();

    expect(find.text('下一步（极速入库）'), findsOneWidget);
    await tester.tap(find.text('下一步（极速入库）'));
    await tester.pumpAndSettle();

    expect(find.text('第 5 步：入库'), findsOneWidget);
    expect(find.byType(MarkdownBody), findsNothing, reason: '极速模式跳过预览');

    await tester.tap(find.text('确认入库'));
    await tester.pumpAndSettle();
    expect(find.text('入库完成'), findsOneWidget);
    expect(await db.kbEntriesDao.byName('青云宗'), isNotNull);
  });

  testWidgets('未配置 AI：清洗按钮置灰引导，跳过 AI 手动整理仍可走完入库', (tester) async {
    await pumpWizard(
      tester,
      aiAvailable: false,
      initialText: '青云山脉北麓的护山大阵常年不熄。',
    );

    await tester.tap(find.text('下一步：AI 清洗'));
    await tester.pumpAndSettle();

    final aiButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'AI 清洗并分类'),
    );
    expect(aiButton.onPressed, isNull, reason: '未配置模型时 AI 按钮置灰（docs/00 验收 2）');
    expect(gateway.completeCalls, 0);

    await tester.tap(find.text('跳过 AI，手动整理'));
    await tester.pumpAndSettle();
    expect(find.text('未命名条目'), findsOneWidget);

    await tester.tap(find.text('下一步：预览'));
    await tester.pumpAndSettle();
    expect(find.textContaining('护山大阵'), findsWidgets);

    await tester.tap(find.text('下一步：入库'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认入库'));
    await tester.pumpAndSettle();
    expect(find.text('入库完成'), findsOneWidget);

    final entry = await db.kbEntriesDao.byName('未命名条目');
    // DIAG
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
    expect(entry, isNotNull);
    expect(entry!.categoryPath, '未分类');
    expect(entry.source, 'manual');
    expect(entry.contentMd, contains('护山大阵'));
  });
}
