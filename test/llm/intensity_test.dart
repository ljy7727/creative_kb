// 思考强度预设参数（A4）：解析、chat 参数映射、单次上限封顶、内部键过滤。
import 'package:creative_kb/core/llm/intensity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('standard 种子解析：temperature/maxTokens 直传', () {
    final params = IntensityParams.fromJsonString(
      '{"temperature":0.7,"maxTokens":4096}',
    );
    expect(params.temperature, 0.7);
    expect(params.maxTokens, 4096);
    expect(params.requestsStepByStep, isFalse);

    final chat = params.toChatParams();
    expect(chat.temperature, 0.7);
    expect(chat.maxTokens, 4096);
    expect(chat.topP, isNull);
    expect(chat.extra, isNull);
  });

  test('deep 种子：stepByStep 不进请求体，厂商参数原样透传', () {
    final params = IntensityParams.fromJsonString(
      '{"temperature":0.5,"maxTokens":8192,'
      '"extra":{"stepByStep":true,"vendorReasoning":"auto","enable_thinking":true}}',
    );
    expect(params.requestsStepByStep, isTrue);
    final chat = params.toChatParams();
    expect(chat.temperature, 0.5);
    expect(chat.maxTokens, 8192);
    // 内部语义键剥离；其余 extra 键透传给厂商（docs/02 A4「厂商自适应推理参数」）。
    expect(chat.extra, {'enable_thinking': true});
  });

  test('单次上限封顶：取预设与上限较小值（docs/02 A5）', () {
    final deep = IntensityParams.fromJsonString('{"maxTokens":8192}');
    expect(deep.toChatParams(maxTokensCap: 2048).maxTokens, 2048);

    final fast = IntensityParams.fromJsonString('{"maxTokens":1024}');
    expect(fast.toChatParams(maxTokensCap: 4096).maxTokens, 1024);

    // 预设未设 maxTokens 时用上限本身。
    expect(
      IntensityParams.fromJsonString('{}')
          .toChatParams(maxTokensCap: 777)
          .maxTokens,
      777,
    );
  });

  test('非法/空 params JSON 回落默认（不设限不崩溃）', () {
    for (final raw in ['', '   ', '不是 JSON', '[1,2,3]']) {
      final params = IntensityParams.fromJsonString(raw);
      expect(params.temperature, isNull, reason: '输入：$raw');
      expect(params.maxTokens, isNull);
      expect(params.extra, isEmpty);
      expect(params.toChatParams().maxTokens, isNull);
    }
  });

  test('roundtrip：toJson 输出可再解析', () {
    const params = IntensityParams(
      temperature: 0.3,
      topP: 0.9,
      maxTokens: 2048,
      extra: {'k': 1},
    );
    final parsed = IntensityParams.fromJsonString(params.toJsonString());
    expect(parsed.temperature, 0.3);
    expect(parsed.topP, 0.9);
    expect(parsed.maxTokens, 2048);
    expect(parsed.extra, {'k': 1});
  });

  test('IntensityCodes 与种子表四档一致（docs/02 A4）', () {
    expect(IntensityCodes.all, ['fast', 'standard', 'deep', 'custom']);
  });
}
