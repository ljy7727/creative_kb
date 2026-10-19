import 'package:creative_kb/features/prompts/models/prompt_models.dart';
import 'package:creative_kb/features/prompts/services/prompt_variables.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractVariableNames（{{变量}}标注提取）', () {
    test('按首次出现顺序去重', () {
      expect(extractVariableNames('{{城市}}的{{主角}}走在{{城市}}的街头'), ['城市', '主角']);
    });

    test('无标注时返回空列表', () {
      expect(extractVariableNames('唐朝官员上朝手持笏板'), isEmpty);
    });

    test('容忍花括号内空白', () {
      expect(extractVariableNames('{{ 主角 }}登场'), ['主角']);
    });
  });

  group('fillVariables（变量替换）', () {
    test('已填值替换，未填值保留 {{}} 标注便于继续编辑', () {
      const body = '{{主角}}离开{{城市}}，前往{{目的地}}。';
      final filled = fillVariables(body, {'主角': '李慕白', '城市': '长安'});
      expect(filled, '李慕白离开长安，前往{{目的地}}。');
    });

    test('全部填值后无残留标注', () {
      const body = '{{主角}}离开{{城市}}';
      final filled = fillVariables(body, {'主角': '李慕白', '城市': '长安'});
      expect(filled, '李慕白离开长安');
      expect(extractVariableNames(filled), isEmpty);
    });

    test('missingVariables 列出尚未填值的变量', () {
      const body = '{{主角}}去往{{目的地}}';
      expect(missingVariables(body, {'主角': '李慕白'}), ['目的地']);
    });
  });

  group('annotateVariables（正文标注）', () {
    test('包裹裸出现，已标注区间原样保留', () {
      expect(annotateVariables('主角在长安', ['主角']), '{{主角}}在长安');
      expect(
        annotateVariables('已标注 {{主角}}，另有裸写主角', ['主角']),
        '已标注 {{主角}}，另有裸写{{主角}}',
      );
    });

    test('空变量名列表原文返回', () {
      expect(annotateVariables('正文原样', []), '正文原样');
    });
  });

  group('resolveVariables（DB 变量表 + 正文标注合并）', () {
    test('正文为准补缺，保留已存说明', () {
      final resolved = resolveVariables(
        variablesJson: PromptVariable.encode([
          const PromptVariable(name: '主角', desc: '人物姓名'),
        ]),
        body: '{{主角}}进入{{秘境}}',
      );
      expect(resolved.map((v) => v.name).toList(), ['主角', '秘境']);
      expect(resolved.first.desc, '人物姓名');
      expect(resolved.last.desc, '');
    });
  });

  group('PromptVariable 序列化', () {
    test('encode/decode 往返一致，非法 JSON 容错为空', () {
      const variables = [
        PromptVariable(name: '主角', desc: '人物姓名'),
        PromptVariable(name: '城市', desc: '地点'),
      ];
      final json = PromptVariable.encode(variables);
      final decoded = PromptVariable.decode(json);
      expect(decoded.map((v) => v.name).toList(), ['主角', '城市']);
      expect(decoded.map((v) => v.desc).toList(), ['人物姓名', '地点']);

      expect(PromptVariable.decode('not json'), isEmpty);
      expect(PromptVariable.decode('{"a":1}'), isEmpty);
    });
  });
}
