// DeepSeek Search/Fetch 客户端单测：请求形状、鉴权头、结果解析、错误映射。
import 'dart:convert';

import 'package:creative_kb/core/llm/deepseek_tools.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'llm/fake_adapter.dart';

ResponseBody jsonResponse(Object data, {int statusCode = 200}) =>
    ResponseBody.fromString(
      jsonEncode(data),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  test('search：路径 / 鉴权头 / 参数正确，结果按文档字段解析', () async {
    final adapter = FakeAdapter(
      (options) async => jsonResponse({
        'results': [
          {
            'title': '唐朝官服',
            'url': 'https://example.com/a',
            'summary': '摘要',
            'content': '正文内容',
            'site_name': '示例站',
            'date': '2024-01-01',
            'authority': 'high',
            'rerank_score': 0.92,
          },
          {'title': '仅标题'},
        ],
      }),
    );
    final client = DeepSeekToolsClient(
      dio: Dio()..httpClientAdapter = adapter,
    );
    final items = await client.search(
      apiKey: 'sk-test',
      query: '唐朝 官服',
      count: 5,
    );
    expect(items, hasLength(2));
    expect(items.first.bestText, '正文内容');
    expect(items.first.siteName, '示例站');
    expect(items.last.bestText, '');

    final request = adapter.requests.single;
    expect(request.path, '/v1/tools/search');
    expect(request.headers['Authorization'], 'Bearer sk-test');
    final body = request.data as Map;
    expect(body['query'], '唐朝 官服');
    expect(body['count'], 5);
    expect(body['need_content'], true);
  });

  test('search：空查询不发请求', () async {
    final adapter = FakeAdapter((options) async => jsonResponse({'results': []}));
    final client = DeepSeekToolsClient(
      dio: Dio()..httpClientAdapter = adapter,
    );
    expect(await client.search(apiKey: 'k', query: '   '), isEmpty);
    expect(adapter.requests, isEmpty);
  });

  test('search：401 → 可读的凭据异常', () async {
    final adapter = FakeAdapter(
      (options) async => jsonResponse({'message': 'invalid key'}, statusCode: 401),
    );
    final client = DeepSeekToolsClient(
      dio: Dio()..httpClientAdapter = adapter,
    );
    await expectLater(
      client.search(apiKey: 'bad', query: 'q'),
      throwsA(
        isA<DeepSeekToolsException>().having(
          (e) => e.message,
          'message',
          contains('API Key 无效或无权限'),
        ),
      ),
    );
  });

  test('search：429 → 提示稍后重试', () async {
    final adapter = FakeAdapter(
      (options) async => jsonResponse({'message': 'rate limited'}, statusCode: 429),
    );
    final client = DeepSeekToolsClient(
      dio: Dio()..httpClientAdapter = adapter,
    );
    await expectLater(
      client.search(apiKey: 'k', query: 'q'),
      throwsA(
        isA<DeepSeekToolsException>().having(
          (e) => e.message,
          'message',
          contains('稍后重试'),
        ),
      ),
    );
  });

  test('fetch：路径与标题/正文解析', () async {
    final adapter = FakeAdapter(
      (options) async => jsonResponse({
        'title': '页面标题',
        'content': '# Markdown 正文',
      }),
    );
    final client = DeepSeekToolsClient(
      dio: Dio()..httpClientAdapter = adapter,
    );
    final page = await client.fetch(apiKey: 'k', url: 'https://example.com/a');
    expect(page.title, '页面标题');
    expect(page.content, contains('Markdown'));
    final request = adapter.requests.single;
    expect(request.path, '/v1/tools/fetch');
    expect((request.data as Map)['url'], 'https://example.com/a');
  });

  test('fetch：5xx → 类型化异常', () async {
    final adapter = FakeAdapter(
      (options) async => jsonResponse({'message': 'boom'}, statusCode: 502),
    );
    final client = DeepSeekToolsClient(
      dio: Dio()..httpClientAdapter = adapter,
    );
    await expectLater(
      client.fetch(apiKey: 'k', url: 'https://example.com'),
      throwsA(isA<DeepSeekToolsException>()),
    );
  });
}
