import 'package:creative_kb/features/kb/widgets/category_tree.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildCategoryTree（纯函数）', () {
    test('逐级补父、去重、按名称排序', () {
      final nodes = buildCategoryTree([
        '仙侠设定/势力宗门',
        '历史设定/官职',
        '仙侠设定/势力宗门', // 重复
        '仙侠设定',
        '历史设定/官职/中央官职',
      ]);
      // 排序为码元序（compareTo）：'仙'(U+4ED9) 在 '历'(U+5386) 之前。
      expect(nodes.map((n) => n.label).toList(), ['仙侠设定', '历史设定']);
      final history = nodes.last;
      expect(history.path, '历史设定');
      expect(history.children.single.label, '官职');
      expect(history.children.single.children.single.path, '历史设定/官职/中央官职');
      final xianxia = nodes.first;
      expect(xianxia.children.single.label, '势力宗门');
    });

    test('空输入返回空树', () {
      expect(buildCategoryTree(const []), isEmpty);
    });
  });

  group('subtreeCount / inCategorySubtree', () {
    test('子树计数为直接计数递归求和（docs/02 D4 每类计数）', () {
      final nodes = buildCategoryTree(['a/b', 'a/c', 'd']);
      final direct = {'a': 1, 'a/b': 2, 'a/c': 3, 'd': 4};
      final a = nodes.firstWhere((n) => n.label == 'a');
      expect(a.totalCount(direct), 6);
      final d = nodes.firstWhere((n) => n.label == 'd');
      expect(d.totalCount(direct), 4);
    });

    test('inCategorySubtree：本级或前缀命中，兄弟目录不误判', () {
      expect(inCategorySubtree('仙侠设定/势力宗门', '仙侠设定'), isTrue);
      expect(inCategorySubtree('仙侠设定', '仙侠设定'), isTrue);
      expect(inCategorySubtree('仙侠设定外/势力宗门', '仙侠设定'), isFalse);
      expect(inCategorySubtree('仙侠设定', '仙侠设定/势力宗门'), isFalse);
    });
  });
}
