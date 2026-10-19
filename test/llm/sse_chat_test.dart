// SSE 分帧解析与 chat 流式聚合（docs/03 测试策略 core/llm 行）。
import 'package:creative_kb/core/llm/llm_client.dart';
import 'package:creative_kb/core/llm/providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_adapter.dart';

const _provider = ProviderConfig(
  name: 'DeepSeek',
  baseUrl: 'https://api.example.com/v1',
  apiKey: 'sk-test',
);

OpenAiCompatLlmClient _clientWith(FakeAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return OpenAiCompatLlmClient(dio: dio);
}

void main() {
  group('SseFrameParser 手写分帧', () {
    test('按空行分帧，跨输入块边界的帧正确拼接', () {
      final parser = SseFrameParser();
      final frames = <String>[
        ...parser.push('data: {"a":1}\n\nda'),
        ...parser.push('ta: {"b":2}\n\n'),
        ...parser.push('data: [DONE]'),
        ...parser.flush(),
      ];
      expect(frames, ['data: {"a":1}', 'data: {"b":2}', 'data: [DONE]']);
    });

    test('支持 \\r\\n\\r\\n 分隔与行尾 \\r 剥离', () {
      final parser = SseFrameParser();
      expect(parser.push('data: one\r\n\r\ndata: two\r\n'), ['data: one']);
      expect(parser.push('\r\n'), ['data: two']);
      expect(parser.hasResidue, isFalse);
    });

    test('取 data: 行、忽略注释行与 event 行，多行 data 全部保留', () {
      final payloads = sseDataPayloads(
        ': keep-alive\nevent: message\ndata: first\ndata:second',
      );
      expect(payloads, ['first', 'second']);
    });
  });

  group('chat 流式对话', () {
    test('onDelta 逐段回调，content 拼接完整，[DONE] 帧被忽略', () async {
      final adapter = FakeAdapter(
        (_) async => sseResponse([
          chatChunkData(delta: '你好'),
          chatChunkData(delta: '，世界'),
          'data: [DONE]',
        ]),
      );
      final deltas = <String>[];
      final result = await _clientWith(adapter).chat(
        provider: _provider,
        model: 'deepseek-chat',
        messages: const [ChatMessage.user('打个招呼')],
        onDelta: deltas.add,
      );
      expect(deltas, ['你好', '，世界']);
      expect(result.content, '你好，世界');
    });

    test('请求体含 model/messages/stream:true 与 Authorization 头', () async {
      final adapter = FakeAdapter(
        (_) async => sseResponse([chatChunkData(delta: 'ok'), 'data: [DONE]']),
      );
      await _clientWith(adapter).chat(
        provider: _provider,
        model: 'deepseek-chat',
        messages: const [ChatMessage.system('系统'), ChatMessage.user('用户')],
        temperature: 0.7,
        maxTokens: 1024,
      );
      final options = adapter.requests.single;
      final body = options.data! as Map<String, dynamic>;
      expect(
        options.uri.toString(),
        'https://api.example.com/v1/chat/completions',
      );
      expect(body['model'], 'deepseek-chat');
      expect(body['stream'], true);
      expect(body['temperature'], 0.7);
      expect(body['max_tokens'], 1024);
      expect(body['messages'], hasLength(2));
      expect(body['messages'][0], {'role': 'system', 'content': '系统'});
      expect(options.headers['Authorization'], 'Bearer sk-test');
    });

    test('usage 提取：取最后一个带 usage 的 chunk，estimated=false', () async {
      final adapter = FakeAdapter(
        (_) async => sseResponse([
          chatChunkData(delta: 'a'),
          chatChunkData(usage: {'prompt_tokens': 3, 'completion_tokens': 5}),
          'data: [DONE]',
        ]),
      );
      final result = await _clientWith(adapter).chat(
        provider: _provider,
        model: 'deepseek-chat',
        messages: const [ChatMessage.user('hi')],
      );
      expect(result.usage.inputTokens, 3);
      expect(result.usage.outputTokens, 5);
      expect(result.usage.estimated, isFalse);
      expect(result.finishReason, isNull);
    });

    test('usage 缺失：按字符数/4 估算并标记 estimated=true', () async {
      final adapter = FakeAdapter(
        (_) async => sseResponse([
          chatChunkData(delta: '你'),
          chatChunkData(delta: '好世界'), // 输出共 4 字符 → 1 token
          'data: [DONE]',
        ]),
      );
      final result = await _clientWith(adapter).chat(
        provider: _provider,
        model: 'deepseek-chat',
        // 输入共 6 字符 → 2 tokens
        messages: const [ChatMessage.system('你是助手'), ChatMessage.user('你好')],
      );
      expect(result.usage.estimated, isTrue);
      expect(result.usage.inputTokens, 2);
      expect(result.usage.outputTokens, 1);
    });

    test('finish_reason 与 extra 透传', () async {
      final adapter = FakeAdapter((options) async {
        expect((options.data! as Map)['stream_options'], isNotNull);
        return sseResponse([
          chatChunkData(delta: 'x', finishReason: 'stop'),
          'data: [DONE]',
        ]);
      });
      final result = await _clientWith(adapter).chat(
        provider: _provider,
        model: 'deepseek-chat',
        messages: const [ChatMessage.user('hi')],
        extra: const {
          'stream_options': {'include_usage': true},
        },
      );
      expect(result.finishReason, 'stop');
    });

    test('非 JSON 负载（心跳）被忽略，不中断解析', () async {
      final adapter = FakeAdapter(
        (_) async => sseResponse([
          ': ping',
          chatChunkData(delta: 'y'),
          'data: not-json',
          'data: [DONE]',
        ]),
      );
      final result = await _clientWith(adapter).chat(
        provider: _provider,
        model: 'deepseek-chat',
        messages: const [ChatMessage.user('hi')],
      );
      expect(result.content, 'y');
    });
  });

  group('listModels / embed', () {
    test('listModels 解析 data[].id', () async {
      final adapter = FakeAdapter(
        (_) async => jsonResponse(
          '{"data":[{"id":"deepseek-chat"},{"id":"deepseek-reasoner"}]}',
        ),
      );
      final models = await _clientWith(adapter).listModels(_provider);
      expect(models.map((m) => m.id), ['deepseek-chat', 'deepseek-reasoner']);
      expect(
        adapter.requests.single.uri.toString(),
        'https://api.example.com/v1/models',
      );
    });

    test('embed 按 index 排序还原输入顺序', () async {
      final adapter = FakeAdapter(
        (_) async => jsonResponse(
          '{"data":['
          '{"index":1,"embedding":[3.0,4.0]},'
          '{"index":0,"embedding":[1.0,2.0]}'
          ']}',
        ),
      );
      final vectors = await _clientWith(adapter).embed(
        provider: _provider,
        model: 'text-embedding-v3',
        texts: const ['甲', '乙'],
      );
      expect(vectors, hasLength(2));
      expect(vectors[0], [1.0, 2.0]);
      expect(vectors[1], [3.0, 4.0]);
    });
  });
}
