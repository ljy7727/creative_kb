// 书籍阅读页：长内容可滚动（回归 v0.6 无法下滑的问题）。
import 'package:creative_kb/features/books/pages/book_reader_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('长章节可以上下滚动', (tester) async {
    final longText = List.generate(
      80,
      (i) => '## 第 $i 节\n\n这是第 $i 节的内容，用于验证阅读页可以正常上下滚动。',
    ).join('\n\n');
    await tester.pumpWidget(
      MaterialApp(
        home: BookReaderPage(title: '测试章节', content: longText),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    final scrollable = find.descendant(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Scrollable),
    );
    final state = tester.state<ScrollableState>(scrollable.first);
    final before = state.position.pixels;
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    final after = tester.state<ScrollableState>(scrollable.first).position.pixels;
    expect(after, greaterThan(before));
  });
}
