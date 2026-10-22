// DeepSeek Search / Fetch API 客户端（资料库「AI 搜集」专用）：
// POST https://api.deepseek.com/v1/tools/search  {"query","count","need_content"}
// POST https://api.deepseek.com/v1/tools/fetch   {"url"}
// Bearer 认证；两个接口均按官方文档返回 JSON。仅 DeepSeek 厂商支持。
import 'package:dio/dio.dart';

/// 搜索/抓取失败（鉴权、限流、网络、上游错误统一包装，message 面向用户）。
class DeepSeekToolsException implements Exception {
  const DeepSeekToolsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 单条搜索结果（字段按官方文档，全部可缺省）。
class DeepSeekSearchItem {
  const DeepSeekSearchItem({
    this.title = '',
    this.url = '',
    this.snippet = '',
    this.summary = '',
    this.content = '',
    this.siteName = '',
    this.date = '',
    this.authority = '',
    this.rerankScore,
  });

  final String title;
  final String url;
  final String snippet;
  final String summary;
  final String content;
  final String siteName;
  final String date;
  final String authority;
  final double? rerankScore;

  /// 优先正文，其次摘要，最后片段（供组装素材用）。
  String get bestText {
    if (content.trim().isNotEmpty) return content.trim();
    if (summary.trim().isNotEmpty) return summary.trim();
    return snippet.trim();
  }
}

/// 抓取结果：标题 + Markdown 正文。
class DeepSeekFetchResult {
  const DeepSeekFetchResult({required this.title, required this.content});

  final String title;
  final String content;
}

/// DeepSeek 工具接口客户端。baseUrl 固定 api.deepseek.com（官方公开端点）。
class DeepSeekToolsClient {
  DeepSeekToolsClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.deepseek.com',
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 60),
              // 4xx 由上抛类型化异常统一处理。
              validateStatus: (code) => code != null && code < 500,
            ),
          );

  final Dio _dio;

  /// 搜索。count ∈ 1..50（默认 10）；needContent=true 时结果带正文。
  Future<List<DeepSeekSearchItem>> search({
    required String apiKey,
    required String query,
    int count = 8,
    bool needContent = true,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    try {
      final response = await _dio.post<Object>(
        '/v1/tools/search',
        data: {
          'query': trimmed,
          'count': count.clamp(1, 50),
          'need_content': needContent,
        },
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );
      _ensureOk(response, '搜索');
      final data = response.data;
      final raw = data is Map ? data['results'] : null;
      if (raw is! List) return const [];
      return [
        for (final item in raw)
          if (item is Map)
            DeepSeekSearchItem(
              title: _str(item['title']),
              url: _str(item['url']),
              snippet: _str(item['snippet']),
              summary: _str(item['summary']),
              content: _str(item['content']),
              siteName: _str(item['site_name']),
              date: _str(item['date']),
              authority: _str(item['authority']),
              rerankScore: (item['rerank_score'] as num?)?.toDouble(),
            ),
      ];
    } on DioException catch (e) {
      throw DeepSeekToolsException(_actionMessage('搜索', e));
    }
  }

  /// 抓取网页正文（Markdown）。
  Future<DeepSeekFetchResult> fetch({
    required String apiKey,
    required String url,
  }) async {
    try {
      final response = await _dio.post<Object>(
        '/v1/tools/fetch',
        data: {'url': url},
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );
      _ensureOk(response, '抓取');
      final data = response.data;
      if (data is! Map) return const DeepSeekFetchResult(title: '', content: '');
      return DeepSeekFetchResult(
        title: _str(data['title']),
        content: _str(data['content']),
      );
    } on DioException catch (e) {
      throw DeepSeekToolsException(_actionMessage('抓取', e));
    }
  }

  /// 统一把 DioException（含 non-2xx 响应）映射为可读提示。
  String _actionMessage(String action, DioException e) {
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) {
      return '$action失败：API Key 无效或无权限（HTTP $code）';
    }
    if (code == 429) {
      return '$action失败：请求过于频繁，请稍后重试（HTTP 429）';
    }
    return '$action请求失败：${_dioMessage(e)}';
  }

  void _ensureOk(Response<Object> response, String action) {
    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) return;
    final data = response.data;
    final message = data is Map ? _str(data['message']) : '';
    if (code == 401 || code == 403) {
      throw DeepSeekToolsException('$action失败：API Key 无效或无权限（HTTP $code）');
    }
    if (code == 429) {
      throw DeepSeekToolsException('$action失败：请求过于频繁，请稍后重试（HTTP 429）');
    }
    throw DeepSeekToolsException(
      '$action失败：HTTP $code${message.isEmpty ? '' : '（$message）'}',
    );
  }

  String _dioMessage(DioException e) {
    final response = e.response;
    if (response != null) {
      final data = response.data;
      final message = data is Map ? _str(data['message']) : '';
      return 'HTTP ${response.statusCode}${message.isEmpty ? '' : '（$message）'}';
    }
    return e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout
        ? '请求超时'
        : e.message ?? '网络错误';
  }

  String _str(Object? value) => value == null ? '' : '$value';
}
