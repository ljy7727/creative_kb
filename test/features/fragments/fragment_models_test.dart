// 契约层单测：JSON 契约解析/校验、围栏剥离、aiMeta、强度参数、标签工具。
import 'package:creative_kb/features/fragments/models/fragment_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('parseOptimizeOutput：FragmentOptimizeTask JSON 契约（docs/02 B2）', () {
    test('剥离 ```json 围栏并解析多条 items（唐朝笏板示例，两主题拆分）', () {
      const fenced = '```json\n$tangBoardAiJson\n```';
      final items = parseOptimizeOutput(fenced);

      expect(items, hasLength(2));
      expect(items[0].title, contains('笏板'));
      expect(items[0].content, contains('提词器'));
      expect(items[0].tags, hasLength(3));
      expect(items[0].tags, contains('#设定-器物'));
      expect(items[1].title, contains('暗伤'));
      expect(items[1].tags, ['#情节-冲突', '#仙侠-修炼']);
    });

    test('容忍模型附加说明文字：截取首个 { 到末个 } 之间的内容', () {
      const noisy = '好的，以下是整理结果：\n$singleItemAiJson\n希望有帮助！';
      final items = parseOptimizeOutput(noisy);
      expect(items, hasLength(1));
      expect(items.single.title, '整合后的单条灵感');
    });

    test('缺少 items 数组时抛出中文契约异常', () {
      expect(
        () => parseOptimizeOutput('{"result":[]}'),
        throwsA(
          isA<FragmentContractException>().having(
            (e) => e.message,
            'message',
            contains('items'),
          ),
        ),
      );
    });

    test('items 内字段类型不符时定位到具体字段报错', () {
      const bad = '{"items":[{"title":123,"content":"正文"}]}';
      expect(
        () => parseOptimizeOutput(bad),
        throwsA(
          isA<FragmentContractException>().having(
            (e) => e.message,
            'message',
            contains('items[0].title'),
          ),
        ),
      );
    });

    test('空 items 与非法 JSON 均报中文异常', () {
      expect(
        () => parseOptimizeOutput('{"items":[]}'),
        throwsA(isA<FragmentContractException>()),
      );
      expect(
        () => parseOptimizeOutput('这不是 JSON'),
        throwsA(
          isA<FragmentContractException>().having(
            (e) => e.message,
            'message',
            contains('JSON'),
          ),
        ),
      );
    });
  });

  group('FragmentAiMeta：aiMeta JSON 序列化', () {
    test('encode/tryDecode 往返，含拆分派生行的 originId', () {
      final meta = FragmentAiMeta(
        providerName: 'DeepSeek',
        model: 'deepseek-chat',
        presetCode: 'standard',
        inputTokens: 120,
        outputTokens: 80,
        ts: DateTime.parse('2026-10-19T10:00:00.000'),
        originId: 7,
        retries: 1,
      );

      final decoded = FragmentAiMeta.tryDecode(meta.encode());

      expect(decoded, isNotNull);
      expect(decoded!.providerName, 'DeepSeek');
      expect(decoded.model, 'deepseek-chat');
      expect(decoded.presetCode, 'standard');
      expect(decoded.inputTokens, 120);
      expect(decoded.outputTokens, 80);
      expect(decoded.originId, 7);
      expect(decoded.retries, 1);
      expect(decoded.ts, DateTime.parse('2026-10-19T10:00:00.000'));
    });

    test('tryDecode 容忍 null 与损坏数据', () {
      expect(FragmentAiMeta.tryDecode(null), isNull);
      expect(FragmentAiMeta.tryDecode(''), isNull);
      expect(FragmentAiMeta.tryDecode('{broken'), isNull);
      expect(FragmentAiMeta.tryDecode('42'), isNull);
    });
  });

  group('强度参数与标签工具', () {
    test('OptimizeParams 解析 intensity_presets.params（deep 档含 extra）', () {
      final params = OptimizeParams.fromPresetJson(
        '{"temperature":0.5,"maxTokens":8192,"extra":{"stepByStep":true}}',
      );
      expect(params.temperature, 0.5);
      expect(params.maxTokens, 8192);
      expect(params.extra['stepByStep'], isTrue);

      final broken = OptimizeParams.fromPresetJson('不是 JSON');
      expect(broken.temperature, isNull);
      expect(broken.maxTokens, isNull);
    });

    test('cappedMaxTokens 以单次上限封顶（docs/02 A5）', () {
      const params = OptimizeParams(temperature: 0.7, maxTokens: 8192);
      expect(params.cappedMaxTokens(2048).maxTokens, 2048);
      expect(params.cappedMaxTokens(0).maxTokens, 8192, reason: '无效上限不封顶');
      expect(params.cappedMaxTokens(9999).maxTokens, 8192);
    });

    test('mergeTags 用户标签在前、去重保序；decodeTags 容忍损坏', () {
      expect(mergeTags(['#随手记', '#设定'], ['#设定', '#历史-唐朝', ' ']), [
        '#随手记',
        '#设定',
        '#历史-唐朝',
      ]);
      expect(decodeTags('["#a","#b"]'), ['#a', '#b']);
      expect(decodeTags('{broken'), isEmpty);
      expect(encodeTags([' #a ', '#b', '']), '["#a","#b"]');
    });
  });
}
