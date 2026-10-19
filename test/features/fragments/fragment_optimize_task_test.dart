// FragmentOptimizeTask 单测：多主题拆分入库（唐朝笏板示例）、校验失败重试、
// 失败状态与记账、日额度拦截、重新优化替换派生行。
// 走真实 TaskRunner 管线（内存 drift 库 + 脚本化假 invoker），不访问网络，
// 同步覆盖 docs/02 A5 的队列状态机与 usage_log 记账（docs/03 测试策略）。
import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/core/db/app_setting_keys.dart';
import 'package:creative_kb/core/tasks/task_runner.dart';
import 'package:creative_kb/features/fragments/models/fragment_models.dart';
import 'package:creative_kb/features/fragments/services/fragment_ai_invoker.dart';
import 'package:creative_kb/features/fragments/services/fragment_optimize_task.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

/// 按脚本逐次返回回复（String）或抛出异常；记录全部请求供断言。
class _ScriptedInvoker implements FragmentAiInvoker {
  _ScriptedInvoker(this.replies);

  final List<Object> replies; // String（模型输出）或 Exception
  final List<FragmentAiRequest> requests = [];
  int _callCount = 0;

  int get callCount => _callCount;

  @override
  Future<FragmentAiReply> invoke(FragmentAiRequest request) async {
    requests.add(request);
    final index = _callCount < replies.length ? _callCount : replies.length - 1;
    _callCount += 1;
    final step = replies[index];
    if (step is Exception) throw step;
    return FragmentAiReply(
      content: step as String,
      inputTokens: 120,
      outputTokens: 80,
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

  Future<int> seedFragment(String raw, {List<String> tags = const []}) =>
      db.fragmentsDao.add(
        FragmentsCompanion.insert(
          rawText: raw,
          source: FragmentSource.manual,
          tags: Value(encodeTags(tags)),
        ),
      );

  /// 装配真实管线：TaskRunner + 已注册的灵感优化 handler。
  Future<TaskRunner> pumpRunner(FragmentAiInvoker invoker) async {
    final runner = TaskRunner(db, sleep: (_) async {});
    runner.registerHandler(
      FragmentOptimizeTask.taskType,
      FragmentOptimizeTask.makeHandler(db: db, invoker: invoker),
    );
    await runner.start();
    return runner;
  }

  Future<TaskQueueItem> enqueueAndFinish(
    TaskRunner runner,
    int fragmentId,
    String intensityCode,
  ) async {
    final taskId = await runner.enqueue(
      module: FragmentOptimizeTask.module,
      taskType: FragmentOptimizeTask.taskType,
      payload: {'fragmentId': fragmentId, 'intensity': intensityCode},
    );
    return runner.whenFinished(taskId);
  }

  test('唐朝笏板示例：两主题拆分为多条，首条回写原行、其余插入派生行', () async {
    await seedModel();
    final fragmentId = await seedFragment(tangBoardInput, tags: ['#随手记']);
    final invoker = _ScriptedInvoker([tangBoardAiJson]);
    final runner = await pumpRunner(invoker);

    final row = await enqueueAndFinish(runner, fragmentId, 'standard');
    expect(row.status, QueueTaskStatus.success);
    expect(row.result, contains('2 条'));

    final rows = await db.fragmentsDao.getAll();
    expect(rows, hasLength(2));

    // 原始行：manual 来源保留、双版本齐备、用户标签与 AI 标签合并。
    final original = await db.fragmentsDao.byId(fragmentId);
    expect(original!.status, FragmentStatus.optimized);
    expect(original.source, FragmentSource.manual);
    expect(original.title, contains('笏板'));
    final originalItem = FragmentOptimizeItem.tryDecode(original.optimizedJson);
    expect(originalItem, isNotNull);
    expect(originalItem!.content, contains('提词器'));
    final originalTags = decodeTags(original.tags);
    expect(originalTags, contains('#随手记'));
    expect(originalTags, contains('#设定-器物'));
    final originalMeta = FragmentAiMeta.tryDecode(original.aiMeta);
    expect(originalMeta!.model, 'deepseek-chat');
    expect(originalMeta.presetCode, 'standard');
    expect(originalMeta.inputTokens, 120);
    expect(originalMeta.outputTokens, 80);
    expect(originalMeta.originId, isNull);

    // 派生行：source=ai、status=optimized、aiMeta.originId 指向原行。
    final derived = rows.singleWhere((row) => row.id != fragmentId);
    expect(derived.source, FragmentSource.ai);
    expect(derived.status, FragmentStatus.optimized);
    expect(derived.title, contains('暗伤'));
    expect(FragmentAiMeta.tryDecode(derived.aiMeta)!.originId, fragmentId);

    // 记账（TaskRunner 收尾统一写 usage_log，docs/02 A5：成功也记）。
    final usage = await db.usageLogDao.recent();
    expect(usage, hasLength(1));
    expect(usage.single.module, 'fragments');
    expect(usage.single.taskType, 'fragment_optimize');
    expect(usage.single.providerName, 'DeepSeek');
    expect(usage.single.model, 'deepseek-chat');
    expect(usage.single.presetCode, 'standard');
    expect(usage.single.inputTokens, 120);
    expect(usage.single.outputTokens, 80);
    expect(usage.single.status, UsageStatus.ok);

    // 提示词契约：系统提示词含 JSON 契约要点，用户消息含原始输入。
    expect(invoker.requests, hasLength(1));
    expect(invoker.requests.single.systemPrompt, contains('只输出一个 JSON 对象'));
    expect(invoker.requests.single.systemPrompt, contains('拆分为多条 items'));
    expect(invoker.requests.single.userPrompt, contains(tangBoardInput));
    expect(invoker.requests.single.providerName, 'DeepSeek');
    expect(invoker.requests.single.baseUrl, 'https://api.deepseek.com/v1');
    expect(invoker.requests.single.keyRef, 'key_main');
    expect(invoker.requests.single.modelId, 'deepseek-chat');
  });

  test('首次输出非法 JSON：把校验错误拼回消息重试，第二次成功', () async {
    await seedModel();
    final fragmentId = await seedFragment(tangBoardInput);
    final invoker = _ScriptedInvoker(['{"oops":"缺 items"}', tangBoardAiJson]);
    final runner = await pumpRunner(invoker);

    final row = await enqueueAndFinish(runner, fragmentId, 'standard');
    expect(row.status, QueueTaskStatus.success);

    expect(invoker.callCount, 2);
    expect(
      invoker.requests[1].userPrompt,
      allOf(contains('上一次输出未通过校验'), contains('items')),
      reason: 'docs/01 第五节：校验错误应拼回消息重试',
    );
    // 记账累计两次调用的 token。
    final usage = await db.usageLogDao.recent();
    expect(usage.single.inputTokens, 240);
  });

  test('重试 ≤2 次仍失败：任务 failed、灵感置 failed、记账 error', () async {
    await seedModel();
    final fragmentId = await seedFragment(tangBoardInput);
    final invoker = _ScriptedInvoker(['"纯文本"', '{"foo":1}', '{"items":"非数组"}']);
    final runner = await pumpRunner(invoker);

    final row = await enqueueAndFinish(runner, fragmentId, 'fast');
    expect(row.status, QueueTaskStatus.failed);
    expect(row.error, contains('已重试 2 次'));
    expect(invoker.callCount, 3, reason: '初次 + 2 次重试（docs/00 验收5）');

    final fragment = await db.fragmentsDao.byId(fragmentId);
    expect(fragment!.status, FragmentStatus.failed);
    expect(FragmentAiMeta.tryDecode(fragment.aiMeta)!.error, isNotNull);
    // rawText 保留，可供重新优化。
    expect(fragment.rawText, tangBoardInput);

    final usage = await db.usageLogDao.recent();
    expect(usage, hasLength(1));
    expect(usage.single.status, UsageStatus.error);
    expect(usage.single.inputTokens, 360, reason: '三次调用的累计输入');
    expect(usage.single.error, isNotNull);
  });

  test('日额度超限：任务被队列拦截 blocked、灵感保留 raw 状态', () async {
    await seedModel();
    final fragmentId = await seedFragment(tangBoardInput);
    await db.appSettingsDao.set(AppSettingKeys.dailyMaxTokens, '100');
    // 当日已有 120 token 消耗。
    await db.usageLogDao.add(
      UsageLogsCompanion.insert(
        module: 'other',
        taskType: 'warmup',
        providerName: 'DeepSeek',
        model: 'deepseek-chat',
        status: UsageStatus.ok,
        inputTokens: const Value(60),
        outputTokens: const Value(60),
      ),
    );

    final invoker = _ScriptedInvoker([tangBoardAiJson]);
    final runner = await pumpRunner(invoker);
    final row = await enqueueAndFinish(runner, fragmentId, 'standard');

    expect(row.status, QueueTaskStatus.failed);
    expect(row.error, contains('额度'));
    expect(invoker.callCount, 0, reason: '额度拦截不应发起 AI 调用');

    final fragment = await db.fragmentsDao.byId(fragmentId);
    expect(fragment!.status, FragmentStatus.raw, reason: '额度拦截不算该条灵感劣化');

    final usage = await db.usageLogDao.recent(limit: 5);
    expect(usage.map((u) => u.status), contains(UsageStatus.blocked));
  });

  test('重新优化：换强度重跑替换旧拆分行，不累积重复', () async {
    await seedModel();
    final fragmentId = await seedFragment(tangBoardInput);
    final first = _ScriptedInvoker([tangBoardAiJson]);
    final runner = await pumpRunner(first);

    final firstRow = await enqueueAndFinish(runner, fragmentId, 'standard');
    expect(firstRow.status, QueueTaskStatus.success);
    expect(await db.fragmentsDao.getAll(), hasLength(2));

    final second = _ScriptedInvoker([singleItemAiJson]);
    runner.registerHandler(
      FragmentOptimizeTask.taskType,
      FragmentOptimizeTask.makeHandler(db: db, invoker: second),
    );
    final rerunRow = await enqueueAndFinish(runner, fragmentId, 'fast');

    expect(rerunRow.status, QueueTaskStatus.success);
    final rows = await db.fragmentsDao.getAll();
    expect(rows, hasLength(1), reason: '旧派生行应被替换而非累积');
    expect(rows.single.title, '整合后的单条灵感');
    expect(rows.single.status, FragmentStatus.optimized);
  });

  test('payloadJson/decodePayload 往返（Map 与 JSON 字符串两种入参）', () {
    final payload = FragmentOptimizeTask.payloadJson(
      fragmentId: 42,
      intensityCode: 'deep',
    );
    final fromString = FragmentOptimizeTask.decodePayload(payload);
    expect(fromString.fragmentId, 42);
    expect(fromString.intensityCode, 'deep');

    final fromMap = FragmentOptimizeTask.decodePayload({
      'fragmentId': 7,
      'intensity': 'fast',
    });
    expect(fromMap.fragmentId, 7);
    expect(fromMap.intensityCode, 'fast');

    expect(FragmentOptimizeTask.module, 'fragments');
    expect(FragmentOptimizeTask.taskType, 'fragment_optimize');
  });

  test('run()：灵感不存在时抛出中文业务异常', () async {
    final task = FragmentOptimizeTask(db: db, invoker: _ScriptedInvoker([]));
    await expectLater(
      task.run(fragmentId: 999, intensityCode: 'standard'),
      throwsA(isA<FragmentOptimizeException>()),
    );
  });
}
