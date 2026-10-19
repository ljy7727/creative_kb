// OpenAI 兼容 LLM 客户端（docs/02 A1）：dio + 手写 SSE 分帧解析。
// 纯 Dart 无 UI 依赖，网络层异常统一映射为类型化 LlmException。
import 'dart:convert';

import 'package:dio/dio.dart';

import 'providers.dart';

/// 对话消息。role 取 system|user|assistant。
class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  const ChatMessage.system(String content)
    : this(role: 'system', content: content);
  const ChatMessage.user(String content) : this(role: 'user', content: content);
  const ChatMessage.assistant(String content)
    : this(role: 'assistant', content: content);

  final String role;
  final String content;
}

/// token 用量。estimated=true 表示厂商未返回 usage，按字符数/4 估算（docs/02 A1）。
class UsageInfo {
  const UsageInfo({
    required this.inputTokens,
    required this.outputTokens,
    this.estimated = false,
  });

  final int inputTokens;
  final int outputTokens;
  final bool estimated;
}

/// 单次对话结果：content 为全部增量拼接；usage 为记账依据（core/tasks 消费）。
class ChatResult {
  const ChatResult({
    required this.content,
    required this.usage,
    this.finishReason,
  });

  final String content;
  final UsageInfo usage;
  final String? finishReason;
}

/// /models 返回的模型。tags 由 core/llm/model_catalog 的启发式规则补齐，
/// 本文件的传输层只负责透传 id（tags 默认空）。
class ModelInfo {
  const ModelInfo({required this.id, this.tags = const []});

  final String id;
  final List<String> tags;
}

/// LLM 调用抽象（docs/02 A1 接口）。实现类见 [OpenAiCompatLlmClient]。
abstract class LlmClient {
  /// SSE 流式对话。onDelta 逐段回调；返回值含 usage（取最后一个带 usage 的
  /// chunk，缺失时按字符数/4 估算并标记 estimated=true）。
  Future<ChatResult> chat({
    required ProviderConfig provider,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
    Map<String, dynamic>? extra,
    void Function(String delta)? onDelta,
  });

  /// GET {baseUrl}/models，拉取厂商模型目录。
  Future<List<ModelInfo>> listModels(ProviderConfig provider);

  /// POST {baseUrl}/embeddings，批量向量化；返回顺序与 texts 一一对应。
  Future<List<List<double>>> embed({
    required ProviderConfig provider,
    required String model,
    required List<String> texts,
  });
}

// ---------------------------------------------------------------------------
// 类型化异常（docs/02 A1：无网络/401/429/5xx 等）
// ---------------------------------------------------------------------------

/// 基类：message 为可直接展示给用户的中文描述。
class LlmException implements Exception {
  LlmException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;

  /// 原始异常，仅用于日志排查。
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// 认证失败（HTTP 401/403）：Key 缺失、无效或无权限。
class LlmAuthException extends LlmException {
  LlmAuthException(super.message, {super.statusCode, super.cause});
}

/// 触发限流（HTTP 429）。
class LlmRateLimitException extends LlmException {
  LlmRateLimitException(super.message, {super.statusCode, super.cause});
}

/// 厂商服务端错误（HTTP 5xx）。
class LlmServerException extends LlmException {
  LlmServerException(super.message, {super.statusCode, super.cause});
}

/// 请求被拒绝（其余 4xx）：参数不合法、模型不存在等。
class LlmBadRequestException extends LlmException {
  LlmBadRequestException(super.message, {super.statusCode, super.cause});
}

/// 网络不可达、连接/读写超时、流中断。
class LlmNetworkException extends LlmException {
  LlmNetworkException(super.message, {super.statusCode, super.cause});
}

/// 请求方主动取消。
class LlmCancelledException extends LlmException {
  LlmCancelledException(super.message, {super.cause});
}

// ---------------------------------------------------------------------------
// SSE 分帧（手写，docs/02 A1：按空行分帧、取 data: 行、忽略 [DONE]）
// ---------------------------------------------------------------------------

/// 增量式 SSE 分帧器：feed 任意切分的文本块，吐出完整帧（不含结尾空行）。
/// 支持 \n\n 与 \r\n\r\n 两种帧分隔；\r\n 行尾在取行时剥离。
class SseFrameParser {
  final StringBuffer _buffer = StringBuffer();

  /// 已缓存的残余文本长度。
  bool get hasResidue => _buffer.isNotEmpty;

  /// 输入一段文本，返回其中已完成的帧。
  List<String> push(String text) {
    _buffer.write(text);
    return _drain();
  }

  /// 流结束时调用：残余未以空行结尾的内容按一帧补出（厂商偶发漏发终止空行）。
  List<String> flush() {
    if (_buffer.isEmpty) return const [];
    final rest = _buffer.toString();
    _buffer.clear();
    return [rest];
  }

  List<String> _drain() {
    final frames = <String>[];
    while (true) {
      final s = _buffer.toString();
      var idx = s.indexOf('\n\n');
      var sepLen = 2;
      final crlf = s.indexOf('\r\n\r\n');
      if (crlf >= 0 && (idx < 0 || crlf < idx)) {
        idx = crlf;
        sepLen = 4;
      }
      if (idx < 0) break;
      frames.add(s.substring(0, idx));
      _buffer
        ..clear()
        ..write(s.substring(idx + sepLen));
    }
    return frames;
  }
}

/// 从一帧 SSE 文本取出全部 data 负载（一帧可含多行 data）；忽略注释行与
/// event:/id:/retry: 等字段。`data:` 后的空格按规范剥离。
List<String> sseDataPayloads(String frame) {
  final payloads = <String>[];
  for (final rawLine in frame.split('\n')) {
    final line = rawLine.endsWith('\r')
        ? rawLine.substring(0, rawLine.length - 1)
        : rawLine;
    if (!line.startsWith('data:')) continue;
    var payload = line.substring(5);
    if (payload.startsWith(' ')) payload = payload.substring(1);
    payloads.add(payload);
  }
  return payloads;
}

// ---------------------------------------------------------------------------
// OpenAI 兼容实现
// ---------------------------------------------------------------------------

/// OpenAI 兼容协议客户端（DeepSeek/通义/豆包/智谱及任意自定义 baseUrl）。
class OpenAiCompatLlmClient implements LlmClient {
  OpenAiCompatLlmClient({
    Dio? dio,
    this.connectTimeout = const Duration(seconds: 15),
  }) : _dio = dio ?? Dio() {
    if (dio == null) {
      _dio.options
        ..connectTimeout = connectTimeout
        // 流式场景下 receiveTimeout 是「相邻 chunk 间隔」超时，不是总时长。
        ..receiveTimeout = const Duration(seconds: 60);
    }
  }

  final Dio _dio;
  final Duration connectTimeout;

  @override
  Future<ChatResult> chat({
    required ProviderConfig provider,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
    Map<String, dynamic>? extra,
    void Function(String delta)? onDelta,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'messages': [
        for (final m in messages) {'role': m.role, 'content': m.content},
      ],
      'stream': true,
    };
    if (temperature != null) body['temperature'] = temperature;
    if (topP != null) body['top_p'] = topP;
    if (maxTokens != null) body['max_tokens'] = maxTokens;
    if (extra != null) body.addAll(extra);

    // validateStatus 恒真：非 2xx 也走正常返回，由本类按状态码统一映射异常
    //（流式错误响应体需要手动排水，交给 dio 转换层行为不直观）。
    Response<ResponseBody> resp;
    try {
      resp = await _dio.post<ResponseBody>(
        _joinUrl(provider.baseUrl, 'chat/completions'),
        data: body,
        options: Options(
          responseType: ResponseType.stream,
          validateStatus: (_) => true,
          headers: _authHeaders(provider),
        ),
      );
    } on DioException catch (e) {
      throw await _toLlmException(e);
    }

    final status = resp.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw _httpStatusException(
        status,
        _errorMessage(await _drainBody(resp.data)),
      );
    }

    final parser = SseFrameParser();
    final content = StringBuffer();
    UsageInfo? usage;
    String? finishReason;
    try {
      await for (final frame in _sseFrames(resp.data!.stream, parser)) {
        for (final payload in sseDataPayloads(frame)) {
          if (payload.trim() == '[DONE]') {
            return _done(content, usage, finishReason, messages);
          }
          final Object? decoded;
          try {
            decoded = jsonDecode(payload);
          } on FormatException {
            continue; // 忽略心跳等非 JSON 负载
          }
          if (decoded is! Map<String, dynamic>) continue;
          usage = _mergeUsage(usage, decoded['usage']);
          final choices = decoded['choices'];
          if (choices is List && choices.isNotEmpty) {
            final choice = choices.first;
            if (choice is Map<String, dynamic>) {
              final delta = choice['delta'];
              if (delta is Map<String, dynamic>) {
                final text = delta['content'];
                if (text is String && text.isNotEmpty) {
                  content.write(text);
                  onDelta?.call(text);
                }
              }
              final fr = choice['finish_reason'];
              if (fr is String && fr.isNotEmpty) finishReason = fr;
            }
          }
        }
      }
    } on DioException catch (e) {
      throw await _toLlmException(e);
    } on Exception catch (e) {
      // 流中途断开（连接重置等）以网络异常暴露，已收到的部分内容不返回。
      throw LlmNetworkException('流式响应中断：$e', cause: e);
    }
    return _done(content, usage, finishReason, messages);
  }

  @override
  Future<List<ModelInfo>> listModels(ProviderConfig provider) async {
    final Response<Map<String, dynamic>> resp;
    try {
      resp = await _dio.get<Map<String, dynamic>>(
        _joinUrl(provider.baseUrl, 'models'),
        options: Options(headers: _authHeaders(provider)),
      );
    } on DioException catch (e) {
      throw await _toLlmException(e);
    }
    final list = resp.data?['data'];
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic> && item['id'] is String)
          ModelInfo(id: item['id'] as String),
    ];
  }

  @override
  Future<List<List<double>>> embed({
    required ProviderConfig provider,
    required String model,
    required List<String> texts,
  }) async {
    final Response<Map<String, dynamic>> resp;
    try {
      resp = await _dio.post<Map<String, dynamic>>(
        _joinUrl(provider.baseUrl, 'embeddings'),
        data: <String, dynamic>{'model': model, 'input': texts},
        options: Options(headers: _authHeaders(provider)),
      );
    } on DioException catch (e) {
      throw await _toLlmException(e);
    }
    final list = resp.data?['data'];
    if (list is! List) {
      throw LlmServerException(
        '厂商 embeddings 响应缺少 data 字段',
        statusCode: resp.statusCode,
      );
    }
    // 按 index 排序还原输入顺序（部分厂商乱序返回；缺 index 时按出现顺序）。
    final entries = <(int, List<double>)>[];
    var fallbackIndex = 0;
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final raw = item['embedding'];
      if (raw is! List) continue;
      final idx = (item['index'] as num?)?.toInt() ?? fallbackIndex;
      entries.add((idx, [for (final v in raw) (v as num).toDouble()]));
      fallbackIndex++;
    }
    entries.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final (_, vector) in entries) vector];
  }

  // -- 内部 -----------------------------------------------------------------

  ChatResult _done(
    StringBuffer content,
    UsageInfo? usage,
    String? finishReason,
    List<ChatMessage> messages,
  ) {
    final text = content.toString();
    return ChatResult(
      content: text,
      usage: usage ?? _estimateUsage(text, messages),
      finishReason: finishReason,
    );
  }

  Stream<String> _sseFrames(
    Stream<List<int>> bytes,
    SseFrameParser parser,
  ) async* {
    // 经 Converter.bind 解码：dio 实际给出 Stream<Uint8List>，
    // 走 Stream.transform 会在运行时因泛型不变性报类型错误。
    await for (final text in const Utf8Decoder(
      allowMalformed: true,
    ).bind(bytes)) {
      for (final frame in parser.push(text)) {
        yield frame;
      }
    }
    for (final frame in parser.flush()) {
      yield frame;
    }
  }

  UsageInfo? _mergeUsage(UsageInfo? current, Object? rawUsage) {
    if (rawUsage is! Map<String, dynamic>) return current;
    final input = rawUsage['prompt_tokens'];
    final output = rawUsage['completion_tokens'];
    if (input is! num || output is! num) return current;
    return UsageInfo(inputTokens: input.toInt(), outputTokens: output.toInt());
  }

  UsageInfo _estimateUsage(String outputText, List<ChatMessage> messages) {
    var inputChars = 0;
    for (final m in messages) {
      inputChars += m.content.length;
    }
    return UsageInfo(
      inputTokens: _estimateTokens(inputChars),
      outputTokens: _estimateTokens(outputText.length),
      estimated: true,
    );
  }

  /// docs/02 A1：缺失 usage 时按字符数/4 估算。
  static int _estimateTokens(int charCount) => (charCount / 4).ceil();

  static Map<String, String> _authHeaders(ProviderConfig provider) {
    if (provider.apiKey.isEmpty) return const {};
    return {'Authorization': 'Bearer ${provider.apiKey}'};
  }

  static String _joinUrl(String baseUrl, String path) =>
      baseUrl.endsWith('/') ? '$baseUrl$path' : '$baseUrl/$path';

  /// 排干错误响应体并解码为文本（流式与非流式响应都可能是 ResponseBody）。
  Future<String> _drainBody(Object? data) async {
    try {
      if (data is ResponseBody) {
        return await utf8.decoder.bind(data.stream).join();
      }
      if (data is Map) {
        return jsonEncode(data);
      }
      return data?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// 从错误体提取用户可读信息：标准 OpenAI 为 {"error":{"message":..}}，
  /// 部分厂商用 msg/message 顶层字段；都取不到时截断原文。
  String _errorMessage(String body) {
    if (body.isEmpty) return '';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map && error['message'] is String) {
          return (error['message'] as String).trim();
        }
        if (error is String && error.trim().isNotEmpty) return error.trim();
        for (final key in const ['message', 'msg']) {
          if (decoded[key] is String) return (decoded[key] as String).trim();
        }
      }
    } on FormatException {
      // 非 JSON 错误体，走原文截断
    }
    return body.length > 300 ? '${body.substring(0, 300)}…' : body;
  }

  LlmException _httpStatusException(int status, String detail) {
    final suffix = detail.isEmpty ? '' : '：$detail';
    if (status == 401 || status == 403) {
      return LlmAuthException(
        'API Key 无效或无权限（HTTP $status）$suffix',
        statusCode: status,
      );
    }
    if (status == 429) {
      return LlmRateLimitException(
        '触发厂商限流，请稍后重试（HTTP 429）$suffix',
        statusCode: status,
      );
    }
    if (status >= 500) {
      return LlmServerException(
        '厂商服务端错误（HTTP $status），请稍后重试$suffix',
        statusCode: status,
      );
    }
    return LlmBadRequestException(
      '请求被拒绝（HTTP $status）$suffix',
      statusCode: status,
    );
  }

  Future<LlmException> _toLlmException(DioException e) async {
    switch (e.type) {
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        final detail = _errorMessage(await _drainBody(e.response?.data));
        return _httpStatusException(status, detail);
      case DioExceptionType.connectionTimeout:
        return LlmNetworkException('连接厂商服务器超时', cause: e);
      case DioExceptionType.sendTimeout:
        return LlmNetworkException('请求发送超时', cause: e);
      case DioExceptionType.receiveTimeout:
        return LlmNetworkException('等待响应超时', cause: e);
      case DioExceptionType.cancel:
        return LlmCancelledException('请求已取消', cause: e);
      case DioExceptionType.badCertificate:
        return LlmNetworkException('证书校验失败，连接不安全', cause: e);
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return LlmNetworkException(
          '网络连接失败，请检查网络或 baseUrl${_causeText(e)}',
          cause: e,
        );
    }
  }

  static String _causeText(DioException e) {
    final cause = e.error ?? e.message;
    return cause == null ? '' : '（$cause）';
  }
}
