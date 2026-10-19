// core/llm 测试共用：伪造 dio 适配器与 SSE 响应构造，不访问网络。
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 伪造 HttpClientAdapter：按 handler 返回响应或抛异常。
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  /// 记录每次请求的 options，供断言请求体。
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// 将多帧 SSE 文本合成 200 响应（帧间自动补空行分隔）。statusCode 非 200 时
/// 模拟错误响应（body 为错误 JSON 文本）。
ResponseBody sseResponse(List<String> frames, {int statusCode = 200}) {
  final buffer = StringBuffer();
  for (final frame in frames) {
    buffer
      ..write(frame)
      ..write('\n\n');
  }
  return ResponseBody.fromString(buffer.toString(), statusCode);
}

/// 构造 OpenAI 兼容 chat chunk 的 SSE data 行。
String chatChunkData({
  String? delta,
  Map<String, dynamic>? usage,
  String? finishReason,
  int choices = 1,
}) {
  final chunk = <String, dynamic>{
    'id': 'chatcmpl-test',
    'object': 'chat.completion.chunk',
    'choices': [
      for (var i = 0; i < choices; i++)
        <String, dynamic>{
          'index': i,
          'delta': {'content': ?delta},
          'finish_reason': ?finishReason,
        },
    ],
    'usage': ?usage,
  };
  return 'data: ${jsonEncode(chunk)}';
}

/// JSON 响应：必须带 application/json 头，dio 才会把 body 解码为 Map
///（供 listModels/embed 的 `Response<Map<String, dynamic>>` 路径使用）。
ResponseBody jsonResponse(String body, {int statusCode = 200}) =>
    ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

/// 标准错误响应体（OpenAI 风格）。
ResponseBody errorResponse(int statusCode, {String message = 'boom'}) =>
    jsonResponse(
      jsonEncode({
        'error': {'message': message},
      }),
      statusCode: statusCode,
    );

/// 流中途断开的响应：先发一帧，再抛出 [error]。
ResponseBody brokenStreamResponse(Object error) {
  final controller = StreamController<Uint8List>();
  controller.add(
    Uint8List.fromList(utf8.encode('${chatChunkData(delta: '部分')}\n\n')),
  );
  controller.addError(error);
  controller.close();
  return ResponseBody(controller.stream, 200);
}
