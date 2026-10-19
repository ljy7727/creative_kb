// 提示词模块 AI 调用的生产适配（主会话整合审核补齐，对应 docs/02 模块C 与 A5）：
// core/llm LlmClient 直调 + SecureKeys 读 Key + UsageLedger 额度防护与记账。
// JSON 契约解析/校验/重试由 PromptAiService 完成（prompt_ai_contracts.dart），
// 本适配器只负责一次原始文本调用；测试沿用假 invoker override，不经本文件。
import '../../../core/db/database.dart';
import '../../../core/llm/intensity.dart';
import '../../../core/llm/llm_client.dart';
import '../../../core/llm/providers.dart';
import '../../../core/storage/secure_keys.dart';
import '../../../core/tasks/usage_ledger.dart';
import 'prompt_ai_contracts.dart';

/// 生产实现：与 fragments 模块 StructuredOutputInvoker 同模式，但提示词模块
/// 自带契约重试，故不走 StructuredOutput 而直调 chat 取原始文本。
class LlmPromptAiInvoker implements PromptAiInvoker {
  LlmPromptAiInvoker(
    AppDatabase db, {
    LlmClient? client,
    SecureKeys? secureKeys,
  }) : _db = db,
       _client = client ?? OpenAiCompatLlmClient(),
       _secureKeys = secureKeys ?? SecureKeys(),
       _ledger = UsageLedger(db);

  final AppDatabase _db;
  final LlmClient _client;
  final SecureKeys _secureKeys;
  final UsageLedger _ledger;

  @override
  Future<String> invoke({
    required String systemPrompt,
    required String userPrompt,
    required String intensityCode,
  }) async {
    final taskType = _sniffTaskType(systemPrompt);
    final quota = await _ledger.dailyUsage();
    if (quota.exceeded) {
      await _ledger.recordBlocked(
        module: 'prompts',
        taskType: taskType,
        error: quota.blockedMessage(),
      );
      throw PromptAiException(quota.blockedMessage());
    }

    final pick = await _pickModel();
    if (pick == null) {
      throw PromptAiException('请先在设置中配置 API Key 并启用模型');
    }
    final apiKey = await _secureKeys.read(pick.$1.keyRef!);
    if (apiKey == null || apiKey.isEmpty) {
      throw PromptAiException('未找到厂商「${pick.$1.name}」的 API Key，请到设置中重新保存');
    }

    final params = await _resolveIntensity(intensityCode);
    final cap = await _ledger.singleTaskTokenCap();
    final chatParams = params.toChatParams(maxTokensCap: cap);

    final stopwatch = Stopwatch()..start();
    try {
      final result = await _client.chat(
        provider: ProviderConfig(
          name: pick.$1.name,
          baseUrl: pick.$1.baseUrl,
          apiKey: apiKey,
        ),
        model: pick.$2.modelId,
        messages: [
          ChatMessage.system(systemPrompt),
          ChatMessage.user(userPrompt),
        ],
        temperature: chatParams.temperature,
        topP: chatParams.topP,
        maxTokens: chatParams.maxTokens,
        extra: chatParams.extra,
      );
      stopwatch.stop();
      await _ledger.writeTaskReports(
        module: 'prompts',
        taskType: taskType,
        reports: [
          UsageReport(
            providerName: pick.$1.name,
            model: pick.$2.modelId,
            presetCode: intensityCode,
            inputTokens: result.usage.inputTokens,
            outputTokens: result.usage.outputTokens,
            durationMs: stopwatch.elapsedMilliseconds,
          ),
        ],
        status: UsageStatus.ok,
      );
      return result.content;
    } catch (error) {
      stopwatch.stop();
      if (error is PromptAiException) rethrow;
      await _ledger.writeTaskReports(
        module: 'prompts',
        taskType: taskType,
        reports: const [],
        status: UsageStatus.error,
        error: error.toString(),
        fallbackDurationMs: stopwatch.elapsedMilliseconds,
      );
      throw PromptAiException('AI 调用失败：$error');
    }
  }

  /// 取第一个「已存 Key 且有启用模型」的厂商及其首个启用模型
  /// （与 fragments pickOptimizeModel / kb hasUsableChatModel 同语义）。
  Future<(ProviderRow, ModelRow)?> _pickModel() async {
    final providers = await _db.providersDao.getAll();
    for (final provider in providers) {
      final keyRef = provider.keyRef;
      if (keyRef == null || keyRef.isEmpty) continue;
      final models = await _db.modelsDao.activeByProvider(provider.id);
      if (models.isNotEmpty) return (provider, models.first);
    }
    return null;
  }

  /// code → IntensityParams：intensity_presets 表未命中或参数非法时按默认（不设限）。
  Future<IntensityParams> _resolveIntensity(String code) async {
    final presets = await _db.intensityPresetsDao.byCode(code);
    if (presets == null) return const IntensityParams();
    return IntensityParams.fromJsonString(presets.params);
  }

  /// 接口未携带操作类型，按本模块自有系统提示词的开头特征归类记账 taskType；
  /// 提示词常量与本文件同包，文案变化时同步这里。
  String _sniffTaskType(String systemPrompt) {
    if (systemPrompt.contains('提示词工程助手')) return 'generate';
    if (systemPrompt.contains('提示词优化助手')) return 'optimize';
    if (systemPrompt.contains('变量')) return 'extract_variables';
    return 'ai_call';
  }
}
