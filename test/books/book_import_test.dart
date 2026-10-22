// 书籍导入单测：章节切分、HTML 提取、URL 安全校验（拒绝本机/私网/非 http(s)）。
import 'package:creative_kb/features/books/services/book_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('章节切分：中文「第X章」标题', () {
    const text = '第一章 开始\n这里是第一章内容。\n\n第二章 转折\n第二章内容。';
    final chapters = BookImportService.splitChapters(text);
    expect(chapters, hasLength(2));
    expect(chapters[0].title, '第一章 开始');
    expect(chapters[0].content, contains('第一章内容'));
    expect(chapters[1].title, '第二章 转折');
  });

  test('章节切分：Markdown 标题', () {
    const text = '# 序章\n导言内容\n\n## 第一节\n正文一\n\n## 第二节\n正文二';
    final chapters = BookImportService.splitChapters(text);
    expect(chapters.map((c) => c.title), ['序章', '第一节', '第二节']);
  });

  test('章节切分：无标题 → 全文单章', () {
    final chapters = BookImportService.splitChapters('只有一段普通文字，没有标题。');
    expect(chapters, hasLength(1));
    expect(chapters.single.title, '全文');
    expect(chapters.single.content, contains('普通文字'));
  });

  test('HTML 提取：优先 #js_content，取 og:title 与段落文本', () {
    final service = BookImportService();
    final book = service.parseHtmlBook(
      '<html><head><meta property="og:title" content="测试书名">'
      '<meta name="author" content="作者甲"></head><body>'
      '<div id="js_content"><p>第一段</p><p>第二段</p></div>'
      '<script>var x = 1;</script></body></html>',
      sourceUrl: 'https://example.com/a',
    );
    expect(book.title, '测试书名');
    expect(book.author, '作者甲');
    expect(book.chapters.single.content, contains('第一段'));
    expect(book.chapters.single.content, contains('第二段'));
    expect(book.chapters.single.content, isNot(contains('var x')));
  });

  test('URL 校验：拒绝非 http(s)、localhost、环回与私网地址', () async {
    final service = BookImportService();
    for (final url in [
      'ftp://example.com/a',
      'file:///etc/passwd',
      'http://localhost/a',
      'http://127.0.0.1/a',
      'http://10.0.0.1/a',
      'http://192.168.1.1/a',
      'http://169.254.169.254/latest/meta-data',
      'http://[::1]/a',
    ]) {
      await expectLater(
        service.importUrl(url),
        throwsA(isA<BookImportException>()),
        reason: url,
      );
    }
  });
}
