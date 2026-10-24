import 'dart:convert';
import 'dart:io';

import 'package:creative_kb/core/db/app_setting_keys.dart';
import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/core/seed/app_seeder.dart';
import 'package:creative_kb/features/kb/models/kb_ingest_models.dart';
import 'package:creative_kb/features/kb/services/kb_ingest_task.dart';
import 'package:creative_kb/features/kb/services/schema_registry.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'fake_gateway.dart';

/// 青云宗示例（docs/02 D5 验收）AI 输出脚本。
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

/// 唐朝官职示例（docs/03 测试数据）AI 输出脚本。
const String tangResponse = '''
{
  "cleaned": "唐朝中央官制：尚书省长官户部尚书，掌天下土地与赋税。",
  "proposedCategory": "历史设定/中央官职",
  "proposedSchemaId": "official",
  "entries": [{
    "entryName": "户部尚书",
    "summary": "唐朝六部长官之一。",
    "contentMd": "户部尚书，正三品，上隶尚书省，掌天下土地、户籍与赋税。",
    "tags": ["官职", "唐朝"],
    "relatedEntries": [],
    "credibility": "high",
    "dynasty": "唐",
    "rank": "正三品",
    "duties": "掌天下土地、户籍与赋税",
    "superior_subordinate": "上隶尚书省，下领户部四司"
  }]
}
''';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late SchemaRegistry registry;
  late FakeKbAiGateway gateway;
  late KbIngestTask task;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('creative_kb_ingest_test');
    db = AppDatabase.inMemory();
    await AppSeeder(db, appDirResolver: () async => tempDir).run();
    registry = SchemaRegistry(
      Directory('${tempDir.path}${Platform.pathSeparator}schemas'),
    );
    gateway = FakeKbAiGateway(const []);
    task = KbIngestTask(
      db,
      gateway: gateway,
      loadSchemas: () => registry.load(),
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<IntensityParams> standardIntensity() async {
    final preset = await db.intensityPresetsDao.byCode('standard');
    return IntensityParams.fromPreset(preset!);
  }

  Future<List<UsageLogEntry>> usageRows() => db.usageLogDao.recent(limit: 20);

  test('青云宗示例：宗门条目解析、分类与 Schema 建议、扩展字段、强度参数透传', () async {
    await db.kbCategoriesDao.ensurePath('仙侠设定/势力宗门');
    await db.kbEntriesDao.add(
      KbEntriesCompanion.insert(entryName: '张小凡', categoryPath: '仙侠设定/人物'),
    );
    gateway.enqueue(qingyunResponse);

    final outcome = await task.run(
      rawText: '（用户粘贴的青云宗原文，约两百字）',
      intensity: await standardIntensity(),
    );

    expect(outcome.blocked, isFalse);
    expect(outcome.error, isNull);
    expect(outcome.result, isNotNull);
    expect(outcome.attempts, 1);
    final result = outcome.result!;
    expect(result.proposedCategory, '仙侠设定/势力宗门');
    expect(result.proposedSchemaId, 'sect');
    expect(result.cleaned, contains('护山大阵'));
    final entry = result.entries.single;
    expect(entry.entryName, '青云宗');
    expect(entry.tags, ['宗门', '正道']);
    expect(entry.related, ['张小凡']);
    expect(entry.credibility, 'mid');
    expect(entry.extra['location'], '青云山脉');
    expect(entry.extra['inheritance'], '神剑御雷真诀');

    // 系统提示词附分类树现状 + Schema 摘要 + 已有条目名（docs/02 D2）。
    expect(gateway.lastSystem, contains('【分类树】'));
    expect(gateway.lastSystem, contains('仙侠设定/势力宗门'));
    expect(gateway.lastSystem, contains('宗门势力'));
    expect(gateway.lastSystem, contains('张小凡'));
    // 标准档 temperature 0.7 / maxTokens 4096，且被单次上限 8192 透传。
    expect(gateway.lastTemperature, closeTo(0.7, 1e-9));
    expect(gateway.lastMaxTokens, 4096);
  });

  test('唐朝示例：官职条目按 official Schema 解析朝代/品级/职权', () async {
    gateway.enqueue(tangResponse);

    final outcome = await task.run(
      rawText: '（用户粘贴的唐朝官职原文）',
      intensity: await standardIntensity(),
    );

    final entry = outcome.result!.entries.single;
    expect(entry.entryName, '户部尚书');
    expect(entry.credibility, 'high');
    expect(entry.extra['dynasty'], '唐');
    expect(entry.extra['rank'], '正三品');
    expect(entry.extra['duties'], contains('赋税'));
    expect(outcome.result!.proposedSchemaId, 'official');
  });

  test('JSON 校验失败自动重试 ≤2 次：第二次通过，错误拼回提示词', () async {
    gateway
      ..enqueue('这不是 JSON，我只是随口一说。')
      ..enqueue(qingyunResponse);

    final outcome = await task.run(
      rawText: '（青云宗原文）',
      intensity: await standardIntensity(),
    );

    expect(outcome.result, isNotNull, reason: '第二次尝试应成功');
    expect(outcome.attempts, 2);
    expect(gateway.completeCalls, 2);
    expect(gateway.lastUser, contains('未通过校验'));
    expect(gateway.lastUser, contains('只输出 JSON'));
  });

  test('minMaxTokens 抬底：低档位素材量大时至少用下限，防止 JSON 被截断', () async {
    gateway.enqueue(qingyunResponse);
    await task.run(
      rawText: '（青云宗原文）',
      intensity: await standardIntensity(),
      minMaxTokens: 8192,
    );
    expect(gateway.lastMaxTokens, 8192);
  });

  test('输出疑似截断：重试提示要求压缩 cleaned/contentMd', () async {
    gateway
      // 不以 } 或 ``` 结尾：判定为截断，重试应带压缩指引。
      ..enqueue('{"cleaned":"开头写了很多很多内容，然后突然断了，没有闭合括号')
      ..enqueue(qingyunResponse);
    final outcome = await task.run(
      rawText: '（原文）',
      intensity: await standardIntensity(),
    );
    expect(outcome.result, isNotNull, reason: '第二次尝试应成功');
    expect(gateway.lastUser, contains('截断'));
    expect(gateway.lastUser, contains('压缩'));
  });

  test('三次均失败：返回中文错误并留痕（usage error + 队列 failed）', () async {
    for (var i = 0; i < 3; i++) {
      gateway.enqueue('还是不是 JSON。');
    }

    final outcome = await task.run(
      rawText: '（原文）',
      intensity: await standardIntensity(),
    );

    expect(outcome.result, isNull);
    expect(outcome.error, contains('JSON'));
    expect(outcome.attempts, 3);
    expect(gateway.completeCalls, 3);

    final failedRows = await db.taskQueueDao.byStatus(QueueTaskStatus.failed);
    expect(failedRows, hasLength(1));
    expect(failedRows.single.error, contains('JSON'));

    final rows = await usageRows();
    expect(rows.where((r) => r.status == UsageStatus.error), hasLength(1));
    // 失败也全额记账（docs/02 A5：成功失败都写）。
    expect(
      rows.fold<int>(0, (sum, r) => sum + r.inputTokens + r.outputTokens),
      900,
    );
  });

  test('日额度拦截：不调用模型，任务 blocked 且用量页可见记录', () async {
    await db.appSettingsDao.set(AppSettingKeys.dailyMaxTokens, '50');
    await db.usageLogDao.add(
      UsageLogsCompanion.insert(
        module: 'kb',
        taskType: 'kb_ingest',
        providerName: 'DeepSeek',
        model: 'deepseek-chat',
        outputTokens: const Value(100),
        status: UsageStatus.ok,
      ),
    );

    final outcome = await task.run(
      rawText: '（原文）',
      intensity: await standardIntensity(),
    );

    expect(outcome.blocked, isTrue);
    expect(outcome.error, contains('额度'));
    expect(gateway.completeCalls, 0);

    final rows = await usageRows();
    expect(rows.where((r) => r.status == UsageStatus.blocked), hasLength(1));
    // 被拦截的任务不应产生队列行。
    expect(await db.taskQueueDao.pending(limit: 10), isEmpty);
  });

  test('成功路径记账：module/taskType/model/token/费用估算完整', () async {
    gateway.enqueue(tangResponse);
    final outcome = await task.run(
      rawText: '（唐朝官职原文）',
      intensity: await standardIntensity(),
    );
    expect(outcome.result, isNotNull);

    final rows = await usageRows();
    final row = rows.singleWhere((r) => r.status == UsageStatus.ok);
    expect(row.module, 'kb');
    expect(row.taskType, 'kb_ingest');
    expect(row.model, 'deepseek-chat');
    expect(row.providerName, 'DeepSeek');
    expect(row.inputTokens, 100);
    expect(row.outputTokens, 200);
    // deepseek-chat：100/1M*2.0 + 200/1M*8.0 = 0.0018 元。
    expect(row.costEstimate, closeTo(0.0018, 1e-9));
    expect(row.error, isNull);

    final okRows = await db.taskQueueDao.byStatus(QueueTaskStatus.success);
    expect(okRows, hasLength(1));
    final payload = jsonDecode(okRows.single.result!) as Map<String, dynamic>;
    expect(payload['entries'], ['户部尚书']);
  });

  group('KbIngestParser 契约解析', () {
    test('剥离 ```json 围栏后解析', () {
      const fenced =
          '```json\n'
          '{"cleaned":"正文","proposedCategory":"未分类","proposedSchemaId":"general",'
          '"entries":[{"entryName":"A","tags":["x"],"relatedEntries":["B"],"credibility":"low"}]}'
          '\n```';
      final result = KbIngestParser.parse(fenced);
      expect(result.entries.single.entryName, 'A');
      expect(result.entries.single.credibility, 'low');
      expect(result.proposedCategory, '未分类');
    });

    test('缺 entries / 缺 entryName / 顶层非对象给出明确中文问题', () {
      expect(
        () => KbIngestParser.parse('{"cleaned":"x"}'),
        throwsA(
          isA<KbIngestValidationException>().having(
            (e) => e.issues.join(),
            'issues',
            contains('entries'),
          ),
        ),
      );
      expect(
        () => KbIngestParser.parse(
          '{"cleaned":"x","entries":[{"summary":"没名字"}]}',
        ),
        throwsA(
          isA<KbIngestValidationException>().having(
            (e) => e.issues.join(),
            'issues',
            contains('entryName'),
          ),
        ),
      );
      expect(
        () => KbIngestParser.parse('[]'),
        throwsA(
          isA<KbIngestValidationException>().having(
            (e) => e.issues.join(),
            'issues',
            contains('顶层'),
          ),
        ),
      );
    });

    test('未知字段归入 extra，related 与 relatedEntries 等价', () {
      final result = KbIngestParser.parse(
        jsonEncode({
          'cleaned': 'c',
          'proposedCategory': 'P',
          'proposedSchemaId': 'sect',
          'entries': [
            {
              'entryName': 'A',
              'related': ['B'],
              'grade': '下品灵器',
            },
          ],
        }),
      );
      final entry = result.entries.single;
      expect(entry.related, ['B']);
      expect(entry.extra['grade'], '下品灵器');
    });
  });
}
