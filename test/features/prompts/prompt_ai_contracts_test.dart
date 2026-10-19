import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/features/prompts/models/prompt_models.dart';
import 'package:creative_kb/features/prompts/services/prompt_ai_contracts.dart';
import 'package:flutter_test/flutter_test.dart';

/// 构造 drift Fragment 行（仅用于拼接 AI 用户消息，不入库）。
Fragment _fragment(int id, String title, String rawText) => Fragment(
  id: id,
  rawText: rawText,
  optimizedJson: null,
  title: title,
  tags: '[]',
  source: FragmentSource.manual,
  aiMeta: null,
  status: FragmentStatus.raw,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

/// 脚本化假调用端：按序返回预设响应，记录每次入参供断言。
class _ScriptedInvoker implements PromptAiInvoker {
  _ScriptedInvoker(this._responses);

  final List<String> _responses;
  int calls = 0;
  String? lastSystemPrompt;
  String? lastUserPrompt;
  String? lastIntensityCode;

  @override
  Future<String> invoke({
    required String systemPrompt,
    required String userPrompt,
    required String intensityCode,
  }) async {
    lastSystemPrompt = systemPrompt;
    lastUserPrompt = userPrompt;
    lastIntensityCode = intensityCode;
    final index = calls;
    calls++;
    if (index >= _responses.length) {
      throw StateError('脚本响应已用尽');
    }
    return _responses[index];
  }
}

const String _goodVersions =
    '{"versions":['
    '{"style":"精简","body":"A"},{"style":"详细","body":"B"},{"style":"创意","body":"C"}]}';

void main() {
  group('parseStyleVersions（3 风格 JSON 契约）', () {
    test('接受 ```json 围栏；重复风格取首个；按 精简/详细/创意 排序', () {
      const raw =
          '```json\n'
          '{"versions":[{"style":"创意","body":"C"},{"style":"精简","body":"A"},'
          '{"style":"详细","body":"B"},{"style":"精简","body":"A2"}]}\n'
          '```';
      final drafts = parseStyleVersions(raw);
      expect(drafts.map((d) => d.style).toList(), [
        PromptStyle.concise,
        PromptStyle.detailed,
        PromptStyle.creative,
      ]);
      expect(drafts.first.body, 'A');
    });

    test('缺任一风格或非法 JSON 抛 PromptAiException', () {
      expect(
        () => parseStyleVersions('{"versions":[{"style":"精简","body":"A"}]}'),
        throwsA(isA<PromptAiException>()),
      );
      expect(
        () => parseStyleVersions('这不是 JSON'),
        throwsA(isA<PromptAiException>()),
      );
    });
  });

  test('生成任务：用户消息含碎片文本与该类型的结构参考', () async {
    final invoker = _ScriptedInvoker([_goodVersions]);
    final service = PromptAiService(invoker);

    final drafts = await service.generateStyleVersions(
      type: PromptType.image,
      fragments: [_fragment(1, '唐朝笏板', '唐朝官员上朝手持的笏板，想画一张图')],
      intensityCode: 'fast',
    );

    expect(drafts, hasLength(3));
    expect(invoker.lastIntensityCode, 'fast');
    expect(invoker.lastUserPrompt, contains('唐朝官员上朝手持的笏板'));
    // image 类结构参考来自骨架模板常量。
    expect(invoker.lastSystemPrompt, contains('主体、风格、构图、画质词'));
  });

  test('契约校验失败自动重试 ≤2 次，仍失败明确报错（docs/00 验收 5）', () async {
    const bad = '{"versions":[]}';
    final okInvoker = _ScriptedInvoker([bad, bad, _goodVersions]);
    final okService = PromptAiService(okInvoker);
    final drafts = await okService.generateStyleVersions(
      type: PromptType.novel,
      fragments: [_fragment(1, '', '碎片内容')],
      intensityCode: 'standard',
    );
    expect(drafts, hasLength(3));
    expect(okInvoker.calls, 3); // 初始 + 2 次重试
    expect(okInvoker.lastUserPrompt, contains('未通过校验'));

    final failInvoker = _ScriptedInvoker([bad, bad, bad]);
    final failService = PromptAiService(failInvoker);
    await expectLater(
      failService.generateStyleVersions(
        type: PromptType.novel,
        fragments: [_fragment(1, '', '碎片内容')],
        intensityCode: 'standard',
      ),
      throwsA(isA<PromptAiException>()),
    );
    expect(failInvoker.calls, 3);
  });

  test('空碎片列表直接报错，不调用模型', () async {
    final invoker = _ScriptedInvoker([]);
    final service = PromptAiService(invoker);
    await expectLater(
      service.generateStyleVersions(
        type: PromptType.novel,
        fragments: const [],
        intensityCode: 'standard',
      ),
      throwsA(isA<PromptAiException>()),
    );
    expect(invoker.calls, 0);
  });

  group('定向优化（4 方向）', () {
    test('适配特定模型：用户消息含方向与目标模型名，note 缺省为 null', () async {
      final invoker = _ScriptedInvoker(['{"body":"新正文"}']);
      final service = PromptAiService(invoker);

      final result = await service.optimize(
        body: '旧正文',
        direction: OptimizeDirection.adaptModel,
        targetModel: 'deepseek-chat',
        intensityCode: 'fast',
      );

      expect(result.body, '新正文');
      expect(result.note, isNull);
      expect(invoker.lastUserPrompt, contains('适配特定模型'));
      expect(invoker.lastUserPrompt, contains('deepseek-chat'));
      expect(invoker.lastUserPrompt, contains('旧正文'));
    });

    test('风格转换缺目标风格直接报错，不调用模型', () async {
      final invoker = _ScriptedInvoker([]);
      final service = PromptAiService(invoker);
      await expectLater(
        service.optimize(
          body: '旧正文',
          direction: OptimizeDirection.restyle,
          intensityCode: 'standard',
        ),
        throwsA(isA<PromptAiException>()),
      );
      expect(invoker.calls, 0);
    });

    test('优化结果解析：note 有值保留，body 缺失报错', () {
      expect(parseOptimizeResult('{"body":"B","note":"更精炼"}').note, '更精炼');
      expect(parseOptimizeResult('{"body":"B"}').note, isNull);
      expect(
        () => parseOptimizeResult('{"note":"没有正文"}'),
        throwsA(isA<PromptAiException>()),
      );
    });

    test('四个方向的中文标签与附带参数要求正确', () {
      expect(OptimizeDirection.condense.label, '精简压缩');
      expect(OptimizeDirection.expand.label, '扩写丰富');
      expect(OptimizeDirection.adaptModel.label, '适配特定模型');
      expect(OptimizeDirection.restyle.label, '风格转换');
      expect(OptimizeDirection.adaptModel.needsTargetModel, isTrue);
      expect(OptimizeDirection.restyle.needsTargetStyle, isTrue);
      expect(OptimizeDirection.condense.needsTargetModel, isFalse);
      expect(OptimizeDirection.condense.needsTargetStyle, isFalse);
    });
  });

  group('变量提取', () {
    test('解析变量（去重）并本地标注正文为 {{变量名}}', () async {
      final invoker = _ScriptedInvoker([
        '{"variables":[{"name":"主角名","desc":"人物姓名"},{"name":"城市","desc":""},'
            '{"name":"主角名","desc":"重复应去重"}]}',
      ]);
      final service = PromptAiService(invoker);

      final result = await service.extractVariables(
        body: '主角名在城市中冒险',
        intensityCode: 'standard',
      );

      expect(result.variables.map((v) => v.name).toList(), ['主角名', '城市']);
      expect(result.annotatedBody, '{{主角名}}在{{城市}}中冒险');
    });

    test('缺 variables 数组抛 PromptAiException', () {
      expect(
        () => parseVariablesResult('{}', originalBody: '正文'),
        throwsA(isA<PromptAiException>()),
      );
    });
  });
}
