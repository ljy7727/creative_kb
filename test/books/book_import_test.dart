// 书籍导入单测：章节切分、HTML 提取、URL 安全校验（拒绝本机/私网/非 http(s)）、
// 重定向跟随（301/302 手动处理、相对 Location、私网目标拒绝、次数上限）。
import 'dart:typed_data';

import 'package:creative_kb/features/books/services/book_import_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// 按 URL 返回固定响应的假适配器（不经网络）。
class _CannedAdapter implements HttpClientAdapter {
  _CannedAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  final requests = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final url = options.uri.toString();
    requests.add(url);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

BookImportService _service(_CannedAdapter adapter) => BookImportService(
  dio: Dio(BaseOptions(validateStatus: (c) => c != null && c < 400))
    ..httpClientAdapter = adapter,
);

const _okHtml =
    '<html><head><meta property="og:title" content="重定向书"></head>'
    '<body><article><p>重定向后的正文</p></article></body></html>';

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

  test('重定向：跟随 301 相对 Location 到最终页', () async {
    final adapter = _CannedAdapter((options) {
      if (options.uri.path == '/a') {
        return ResponseBody.fromString('', 301, headers: {
          'location': ['/real-page'],
        });
      }
      return ResponseBody.fromString(_okHtml, 200, headers: {
        'content-type': ['text/html; charset=utf-8'],
      });
    });
    final book = await _service(adapter).importUrl('https://example.com/a');
    expect(adapter.requests, [
      'https://example.com/a',
      'https://example.com/real-page',
    ]);
    expect(book.title, '重定向书');
    expect(book.sourceUrl, 'https://example.com/real-page');
    expect(book.chapters.single.content, contains('重定向后的正文'));
  });

  test('重定向：302 缺少 Location 报错', () async {
    final adapter = _CannedAdapter(
      (_) => ResponseBody.fromString('', 302, headers: {
        'content-type': ['text/html'],
      }),
    );
    await expectLater(
      _service(adapter).importUrl('https://example.com/a'),
      throwsA(
        isA<BookImportException>().having(
          (e) => e.message,
          'message',
          contains('缺少目标地址'),
        ),
      ),
    );
    expect(adapter.requests, hasLength(1));
  });

  test('重定向：目标为私网地址被拒绝', () async {
    final adapter = _CannedAdapter(
      (_) => ResponseBody.fromString('', 302, headers: {
        'location': ['http://192.168.0.1/evil'],
      }),
    );
    await expectLater(
      _service(adapter).importUrl('https://example.com/a'),
      throwsA(
        isA<BookImportException>().having(
          (e) => e.message,
          'message',
          contains('内网或保留地址'),
        ),
      ),
    );
    expect(adapter.requests, hasLength(1));
  });

  test('重定向：超过 3 次报错', () async {
    var n = 0;
    final adapter = _CannedAdapter((options) {
      n += 1;
      return ResponseBody.fromString('', 301, headers: {
        'location': ['https://example.com/hop$n'],
      });
    });
    await expectLater(
      _service(adapter).importUrl('https://example.com/a'),
      throwsA(
        isA<BookImportException>().having(
          (e) => e.message,
          'message',
          contains('重定向次数过多'),
        ),
      ),
    );
    // 首次 + 3 次跟随 = 4 个请求，第 5 次跟随前已超限。
    expect(adapter.requests, hasLength(4));
  });
}
