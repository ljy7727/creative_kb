// UsageLedger 单测：额度读取/边界、封顶解析、拦截记账行、费用估算回退。
import 'package:creative_kb/core/db/app_setting_keys.dart';
import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/core/tasks/usage_ledger.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late UsageLedger ledger;

  setUp(() {
    db = AppDatabase.inMemory();
    ledger = UsageLedger(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedTokens(int input, int output) => db.usageLogDao.add(
    UsageLogsCompanion.insert(
      module: 'fragments',
      taskType: 'optimize',
      providerName: 'p',
      model: 'm',
      status: UsageStatus.ok,
      inputTokens: Value(input),
      outputTokens: Value(output),
    ),
  );

  test('dailyUsage 汇总当日 input+output 并读取日上限设置', () async {
    await db.appSettingsDao.set(AppSettingKeys.dailyMaxTokens, '1000');
    await seedTokens(300, 200);

    final quota = await ledger.dailyUsage();
    expect(quota.usedTokens, 500);
    expect(quota.limitTokens, 1000);
    expect(quota.exceeded, isFalse);
  });

  test('额度边界：used ≥ limit 即超额；上限缺失/非数字/≤0 视为不设限', () async {
    await db.appSettingsDao.set(AppSettingKeys.dailyMaxTokens, '100');
    await seedTokens(60, 40);
    expect((await ledger.dailyUsage()).exceeded, isTrue);

    await db.appSettingsDao.set(AppSettingKeys.dailyMaxTokens, '0');
    expect((await ledger.dailyUsage()).limitTokens, isNull);
    expect((await ledger.dailyUsage()).exceeded, isFalse);

    await db.appSettingsDao.set(AppSettingKeys.dailyMaxTokens, 'abc');
    expect((await ledger.dailyUsage()).limitTokens, isNull);

    await db.appSettingsDao.set(AppSettingKeys.dailyMaxTokens, '-5');
    expect((await ledger.dailyUsage()).limitTokens, isNull);
  });

  test('singleTaskTokenCap 解析封顶值，非法值回退为不封顶', () async {
    await db.appSettingsDao.set(AppSettingKeys.singleTaskMaxTokens, '8192');
    expect(await ledger.singleTaskTokenCap(), 8192);

    await db.appSettingsDao.set(AppSettingKeys.singleTaskMaxTokens, 'oops');
    expect(await ledger.singleTaskTokenCap(), isNull);
  });

  test('recordBlocked 写入 blocked 记账行；writeTaskReports 成功失败都落账', () async {
    await ledger.recordBlocked(
      module: 'kb',
      taskType: 'ingest',
      error: '当日额度已用尽',
    );

    await ledger.writeTaskReports(
      module: 'prompts',
      taskType: 'generate',
      reports: const [
        UsageReport(
          providerName: 'DeepSeek',
          model: 'deepseek-chat',
          presetCode: 'fast',
          inputTokens: 100,
          outputTokens: 200,
          durationMs: 300,
        ),
      ],
      status: UsageStatus.error,
      error: '校验失败',
    );

    // 无上报的成功任务补零 token 行，保证全链路都有记录。
    await ledger.writeTaskReports(
      module: 'kb',
      taskType: 'cleanup',
      reports: const [],
      status: UsageStatus.ok,
      fallbackDurationMs: 42,
    );

    final logs = await db.usageLogDao.recent();
    expect(logs, hasLength(3));

    final blocked = logs.firstWhere((e) => e.status == UsageStatus.blocked);
    expect(blocked.module, 'kb');
    expect(blocked.error, '当日额度已用尽');
    expect(blocked.inputTokens, 0);
    expect(blocked.outputTokens, 0);

    final failed = logs.firstWhere((e) => e.status == UsageStatus.error);
    expect(failed.model, 'deepseek-chat');
    expect(failed.presetCode, 'fast');
    expect(failed.inputTokens, 100);
    expect(failed.outputTokens, 200);
    expect(failed.durationMs, 300);
    expect(failed.error, '校验失败');
    // deepseek-chat：100/1e6*2 + 200/1e6*8 = 0.0018 元。
    expect(failed.costEstimate, closeTo(0.0018, 1e-9));

    final synthetic = logs.firstWhere((e) => e.taskType == 'cleanup');
    expect(synthetic.status, UsageStatus.ok);
    expect(synthetic.durationMs, 42);
    expect(synthetic.costEstimate, isNull);
  });
}
