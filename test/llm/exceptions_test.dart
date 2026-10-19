// 类型化异常映射：401/403/429/5xx/其他 4xx/网络断/流中断（docs/02 A1）。
import 'package:creative_kb/core/llm/llm_client.dart';
import 'package:creative_kb/core/llm/providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_adapter.dart';

const _provider = ProviderConfig(
  name: 'DeepSeek',
  baseUrl: 'https://api.example.com/v1',
  apiKey: 'sk-bad',
);

OpenAiCompatLlmClient _clientWith(FakeAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return OpenAiCompatLlmClient(dio: dio);
}

Future<ChatResult> _chat(LlmClient client) => client.chat(
  provider: _provider,
  model: 'deepseek-chat',
  messages: const [ChatMessage.user('hi')],
);

void main() {
  test('chat 收到 401 → LlmAuthException，错误信息含厂商 message', () async {
    final client = _clientWith(
      FakeAdapter((_) async => errorResponse(401, message: 'Invalid API key')),
    );
    await expectLater(
      _chat(client),
      throwsA(
        isA<LlmAuthException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', contains('Invalid API key')),
      ),
    );
  });

  test('chat 收到 403 → LlmAuthException', () async {
    final client = _clientWith(FakeAdapter((_) async => errorResponse(403)));
    await expectLater(_chat(client), throwsA(isA<LlmAuthException>()));
  });

  test('chat 收到 429 → LlmRateLimitException', () async {
    final client = _clientWith(
      FakeAdapter((_) async => errorResponse(429, message: 'rate limited')),
    );
    await expectLater(
      _chat(client),
      throwsA(
        isA<LlmRateLimitException>().having(
          (e) => e.statusCode,
          'statusCode',
          429,
        ),
      ),
    );
  });

  test(
    'chat 收到 500 → LlmServerException；400 → LlmBadRequestException',
    () async {
      final server = _clientWith(FakeAdapter((_) async => errorResponse(500)));
      await expectLater(
        _chat(server),
        throwsA(
          isA<LlmServerException>().having(
            (e) => e.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
      final bad = _clientWith(FakeAdapter((_) async => errorResponse(400)));
      await expectLater(
        _chat(bad),
        throwsA(
          isA<LlmBadRequestException>().having(
            (e) => e.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
    },
  );

  test('listModels 收到 401（dio 默认状态校验路径）→ LlmAuthException', () async {
    final client = _clientWith(
      FakeAdapter((_) async => errorResponse(401, message: 'auth failed')),
    );
    await expectLater(
      client.listModels(_provider),
      throwsA(
        isA<LlmAuthException>().having(
          (e) => e.message,
          'message',
          contains('auth failed'),
        ),
      ),
    );
  });

  test('embed 收到 503 → LlmServerException', () async {
    final client = _clientWith(FakeAdapter((_) async => errorResponse(503)));
    await expectLater(
      client.embed(provider: _provider, model: 'm', texts: const ['x']),
      throwsA(isA<LlmServerException>()),
    );
  });

  test('连接失败（适配器抛 connectionError）→ LlmNetworkException', () async {
    final client = _clientWith(
      FakeAdapter((options) async {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'connection refused',
        );
      }),
    );
    await expectLater(
      _chat(client),
      throwsA(
        isA<LlmNetworkException>().having(
          (e) => e.message,
          'message',
          contains('网络'),
        ),
      ),
    );
  });

  test('SSE 流中途断开 → LlmNetworkException', () async {
    final client = _clientWith(
      FakeAdapter(
        (_) async => brokenStreamResponse(Exception('connection reset')),
      ),
    );
    await expectLater(
      _chat(client),
      throwsA(
        isA<LlmNetworkException>().having(
          (e) => e.message,
          'message',
          contains('中断'),
        ),
      ),
    );
  });
}
