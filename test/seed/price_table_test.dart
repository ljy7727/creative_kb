import 'package:creative_kb/core/seed/price_table.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('内置价格表（docs/02 A5）', () {
    test('覆盖四类厂商与 embedding 系列的代表模型', () {
      const covered = [
        'deepseek-chat',
        'deepseek-reasoner',
        'qwen-plus',
        'doubao-pro',
        'glm-4',
        'text-embedding-v3',
      ];
      for (final model in covered) {
        expect(PriceTable.match(model), isNotNull, reason: '$model 应有价格记录');
      }
    });

    test('已知模型按百万 token 估算费用', () {
      // deepseek-chat：输入 2 元/百万、输出 8 元/百万。
      final cost = PriceTable.estimateCost(
        modelId: 'deepseek-chat',
        inputTokens: 1000000,
        outputTokens: 500000,
      );
      expect(cost, closeTo(2.0 + 4.0, 1e-9));
    });

    test('最长前缀优先：doubao-pro-128k 命中 128k 档而非 doubao-pro', () {
      final long = PriceTable.match('doubao-pro-128k');
      final plain = PriceTable.match('doubao-pro-32k');
      expect(long, isNotNull);
      expect(plain, isNotNull);
      expect(long, isNot(equals(plain)));
      // glm-4-flash 免费（0 元），不应落在 glm-4 的 100 元档。
      expect(PriceTable.match('glm-4-flash'), (0.0, 0.0));
    });

    test('查不到价格返回 null（只记账不估价）', () {
      expect(PriceTable.match('gpt-5-mini'), isNull);
      expect(
        PriceTable.estimateCost(modelId: 'unknown-model', inputTokens: 1000, outputTokens: 100),
        isNull,
      );
    });
  });
}
