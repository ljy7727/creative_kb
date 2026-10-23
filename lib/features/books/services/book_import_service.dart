// 书籍导入（v0.4）：章节切分、TXT/MD 文件导入、网页链接导入。
// 链接抓取遵循安全约束：仅 http/https；校验 host 并解析 IP，拒绝环回/私网/
// 链路本地/保留地址；手动跟随有限次重定向且每次重新校验；限制响应体积。
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// 导入结果（尚未落库）。
class ImportedBook {
  const ImportedBook({
    required this.title,
    required this.author,
    required this.chapters,
    this.sourceUrl = '',
  });

  final String title;
  final String author;
  final List<ImportedChapter> chapters;
  final String sourceUrl;
}

class ImportedChapter {
  const ImportedChapter({required this.title, required this.content});

  final String title;
  final String content;
}

/// 导入失败（面向用户的提示）。
class BookImportException implements Exception {
  const BookImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BookImportService {
  BookImportService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              validateStatus: (code) => code != null && code < 400,
              maxRedirects: 0,
            ),
          );

  static const _maxHtmlBytes = 3 * 1024 * 1024;
  static const _maxRedirects = 3;

  final Dio _dio;

  /// 从 TXT/MD 文件导入；多选时每本书一条。
  Future<List<ImportedBook>> importFiles(List<PlatformFile> files) async {
    final books = <ImportedBook>[];
    for (final file in files) {
      final bytes = await file.xFile.readAsBytes();
      if (bytes.length > _maxHtmlBytes) {
        throw BookImportException('文件过大（>3MB）：${file.name}');
      }
      final text = utf8.decode(bytes, allowMalformed: true).trim();
      if (text.isEmpty) continue;
      final baseName = file.name.contains('.')
          ? file.name.substring(0, file.name.lastIndexOf('.'))
          : file.name;
      books.add(
        ImportedBook(
          title: baseName,
          author: '',
          chapters: splitChapters(text),
        ),
      );
    }
    if (books.isEmpty) {
      throw const BookImportException('没有可导入的文本内容');
    }
    return books;
  }

  /// 从网页链接导入（安全校验见文件头注释）。
  Future<ImportedBook> importUrl(String rawUrl) async {
    var url = rawUrl.trim();
    var redirects = 0;
    Response<List<int>> response;
    while (true) {
      await _validateUrl(url);
      try {
        response = await _dio.get<List<int>>(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                  'AppleWebKit/537.36 (KHTML, like Gecko) '
                  'Chrome/120.0 Safari/537.36',
              'Accept-Language': 'zh-CN,zh;q=0.9',
            },
          ),
        );
      } on DioException catch (e) {
        throw BookImportException('抓取失败：${e.message ?? '网络错误'}');
      }
      // validateStatus 允许 <400：3xx 会作为正常响应返回，须在此处跟随。
      final status = response.statusCode ?? 0;
      if (status >= 300 && status < 400) {
        final location = response.headers.value('location');
        if (location == null || location.isEmpty) {
          throw const BookImportException('重定向缺少目标地址');
        }
        redirects += 1;
        if (redirects > _maxRedirects) {
          throw const BookImportException('重定向次数过多');
        }
        url = Uri.parse(url).resolve(location).toString();
        continue;
      }
      if (status >= 400) {
        throw BookImportException('抓取失败：HTTP $status');
      }
      break;
    }

    final bytes = response.data ?? const <int>[];
    if (bytes.isEmpty) {
      throw const BookImportException('页面内容为空');
    }
    if (bytes.length > _maxHtmlBytes) {
      throw const BookImportException('页面过大（>3MB），暂不支持导入');
    }
    final html = utf8.decode(bytes, allowMalformed: true);
    return parseHtmlBook(html, sourceUrl: url);
  }

  /// 章节切分：中文「第X章/回/节/卷」或 Markdown 1–3 级标题；
  /// 无标题时整篇作为一章（标题「全文」）。
  static List<ImportedChapter> splitChapters(String text) {
    final heading = RegExp(
      r'^(第[0-9一二三四五六七八九十百千万零两]+[章回节卷][^\n]*|#{1,3}\s+.+)$',
    );
    // 正文行也可能以「第二章…」开头：标题行须短且不以句读结尾。
    bool isHeading(String line) {
      final trimmed = line.trim();
      if (!heading.hasMatch(trimmed)) return false;
      if (trimmed.startsWith('#')) return true;
      if (trimmed.length > 40) return false;
      const endMarks = ['。', '，', '；', '：', ',', '.', ';'];
      for (final mark in endMarks) {
        if (trimmed.endsWith(mark)) return false;
      }
      return true;
    }

    final lines = text.split('\n');
    final chapters = <ImportedChapter>[];
    String? title;
    var sawHeading = false;
    final buffer = StringBuffer();
    void flush() {
      final content = buffer.toString().trim();
      final currentTitle = title;
      if (content.isEmpty &&
          (currentTitle == null || currentTitle.trim().isEmpty)) {
        return;
      }
      chapters.add(
        ImportedChapter(
          title: (currentTitle == null || currentTitle.trim().isEmpty)
              ? '正文'
              : currentTitle.trim(),
          content: content,
        ),
      );
      buffer.clear();
    }

    for (final line in lines) {
      final trimmed = line.trim();
      if (isHeading(trimmed)) {
        sawHeading = true;
        flush();
        title = trimmed.replaceFirst(RegExp(r'^#{1,3}\s+'), '').trim();
      } else {
        buffer.writeln(line);
      }
    }
    flush();

    if (!sawHeading) {
      return [ImportedChapter(title: '全文', content: text.trim())];
    }
    return chapters;
  }

  /// 从 HTML 中提取书名与正文（优先 #js_content / article / body）。
  ImportedBook parseHtmlBook(String html, {required String sourceUrl}) {
    final document = html_parser.parse(html);
    final title =
        document
            .querySelector('meta[property="og:title"]')
            ?.attributes['content']
            ?.trim() ??
        document.querySelector('title')?.text.trim() ??
        '未命名书籍';
    final author =
        document
            .querySelector('meta[name="author"]')
            ?.attributes['content']
            ?.trim() ??
        '';
    for (final node in document.querySelectorAll('script,style,noscript')) {
      node.remove();
    }
    final container =
        document.querySelector('#js_content') ??
        document.querySelector('article') ??
        document.body;
    if (container == null) {
      throw const BookImportException('无法解析页面正文');
    }
    final text = _domText(container);
    if (text.trim().isEmpty) {
      throw const BookImportException('页面没有可提取的文字内容');
    }
    return ImportedBook(
      title: title.isEmpty ? '未命名书籍' : title,
      author: author,
      chapters: splitChapters(text),
      sourceUrl: sourceUrl,
    );
  }

  String _domText(dom.Element container) {
    final marked = container.innerHtml.replaceAllMapped(
      RegExp(
        r'<br\s*/?>|</p>|</div>|</section>|</h[1-6]>|</li>|</blockquote>|</tr>|</pre>',
        caseSensitive: false,
      ),
      (_) => '\n',
    );
    final fragment = html_parser.parseFragment(marked);
    var text = fragment.text ?? '';
    text = text.replaceAll('\u200b', '').replaceAll('\ufeff', '');
    text = text.replaceAll(RegExp(r'[ \t\u3000]+'), ' ');
    text = text.replaceAll(RegExp(r'\n[ ]+'), '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  /// URL 安全校验：协议、host、DNS 解析后的地址边界（防 SSRF）。
  Future<void> _validateUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw const BookImportException('链接格式不正确');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const BookImportException('仅支持 http/https 链接');
    }
    final host = uri.host.trim();
    if (host.isEmpty) {
      throw const BookImportException('链接缺少主机名');
    }
    final lower = host.toLowerCase();
    if (lower == 'localhost' || lower.endsWith('.localhost')) {
      throw const BookImportException('不允许访问本机地址');
    }
    final List<InternetAddress> addresses;
    try {
      addresses = await InternetAddress.lookup(host);
    } catch (_) {
      throw const BookImportException('无法解析该域名');
    }
    if (addresses.isEmpty) {
      throw const BookImportException('无法解析该域名');
    }
    for (final address in addresses) {
      if (!_isPublicAddress(address.rawAddress)) {
        throw const BookImportException('不允许访问内网或保留地址');
      }
    }
  }

  /// 判断原始 IP 是否公网可访问（拒绝环回/私网/链路本地/保留/组播）。
  static bool _isPublicAddress(List<int> bytes) {
    if (bytes.length == 4) {
      final a = bytes[0];
      final b = bytes[1];
      if (a == 0 || a == 10 || a == 127) return false;
      if (a == 169 && b == 254) return false;
      if (a == 172 && b >= 16 && b <= 31) return false;
      if (a == 192 && b == 168) return false;
      if (a == 100 && b >= 64 && b <= 127) return false;
      if (a == 192 && b == 0 && bytes[2] == 0) return false;
      if (a == 198 && (b == 18 || b == 19)) return false;
      if (a >= 224) return false;
      return true;
    }
    if (bytes.length == 16) {
      final allZero = bytes.sublist(0, 15).every((v) => v == 0);
      if (allZero && bytes[15] == 1) return false; // ::1
      if ((bytes[0] & 0xFE) == 0xFC) return false; // fc00::/7
      if (bytes[0] == 0xFE && (bytes[1] & 0xC0) == 0x80) return false; // fe80::/10
      if (bytes[0] == 0xFF) return false; // ff00::/8
      return true;
    }
    return false;
  }
}
