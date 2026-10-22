// 图片文字识别（OCR）：调用已配置厂商的视觉模型（OpenAI 兼容
// chat/completions，content 数组含 image_url 的 base64 data URL）。
// 兼容通义 qwen-vl 系列、智谱 glm-4v 系列等；无视觉模型时给出明确引导。
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../db/app_setting_keys.dart';
import '../db/database.dart';
import '../seed/price_table.dart';
import '../storage/secure_keys.dart';

/// OCR 失败（面向用户的提示）。
class VisionOcrException implements Exception {
  const VisionOcrException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// OCR 结果：识别文本 + 用量。
class VisionOcrResult {
  const VisionOcrResult({
    required this.text,
    required this.providerName,
    required this.model,
    this.inputTokens = 0,
    this.outputTokens = 0,
  });

  final String text;
  final String providerName;
  final String model;
  final int inputTokens;
  final int outputTokens;
}

/// 视觉模型识别服务。
class VisionOcrService {
  VisionOcrService(
    this._db, {
    Dio? dio,
    SecureKeys? secureKeys,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 120),
               validateStatus: (code) => code != null && code < 500,
             ),
           ),
       _secureKeys = secureKeys ?? SecureKeys();

  final AppDatabase _db;
  final Dio _dio;
  final SecureKeys _secureKeys;

  /// 视觉模型识别（modelId 含 vl/vision/4v/omni，或模型 tags 含 vision）。
  static bool looksVisionModel({required String modelId, required String tagsJson}) {
    if (tagsJson.contains('vision')) return true;
    return RegExp(
      r'vl|vision|4v|omni',
      caseSensitive: false,
    ).hasMatch(modelId);
  }

  Future<VisionOcrResult> recognize(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    if (imageBytes.isEmpty) {
      throw const VisionOcrException('图片内容为空，请重新选择');
    }
    final picked = await _pickVisionModel();
    if (picked == null) {
      throw const VisionOcrException(
        '未找到可用的视觉模型：请到设置配置支持图片识别的厂商（如通义 qwen-vl、智谱 glm-4v）的 Key 并拉取模型',
      );
    }
    final apiKey = await _secureKeys.read(picked.$1.keyRef!);
    if (apiKey == null || apiKey.isEmpty) {
      throw VisionOcrException(
        '未找到厂商「${picked.$1.name}」的 API Key，请到设置中重新保存',
      );
    }

    // 额度防护（与其它 AI 任务同语义）。
    final settings = await _db.appSettingsDao.getAll();
    final dailyMax = int.tryParse(settings[AppSettingKeys.dailyMaxTokens] ?? '');
    if (dailyMax != null && dailyMax > 0) {
      final today = await _db.usageLogDao.todayTokens();
      if (today >= dailyMax) {
        throw VisionOcrException(
          '今日 token 额度已用尽（已用 $today / 上限 $dailyMax），可在设置中调整限额',
        );
      }
    }
    var maxTokens = 4096;
    final singleMax = int.tryParse(
      settings[AppSettingKeys.singleTaskMaxTokens] ?? '',
    );
    if (singleMax != null && singleMax > 0 && maxTokens > singleMax) {
      maxTokens = singleMax;
    }

    final dataUrl = 'data:$mimeType;base64,${base64Encode(imageBytes)}';
    final watch = Stopwatch()..start();
    try {
      final response = await _dio.post<Object>(
        '${_trimBaseUrl(picked.$1.baseUrl)}/chat/completions',
        data: {
          'model': picked.$2.modelId,
          'temperature': 0,
          'max_tokens': maxTokens,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': '识别图片中的全部文字，保持原有段落与顺序，'
                      '只输出识别到的文字，不要解释或补充。',
                },
                {
                  'type': 'image_url',
                  'image_url': {'url': dataUrl},
                },
              ],
            },
          ],
        },
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
        ),
      );
      _ensureOk(response);
      final body = response.data;
      final choices = body is Map ? body['choices'] : null;
      final message = choices is List && choices.isNotEmpty
          ? (choices.first is Map ? (choices.first as Map)['message'] : null)
          : null;
      final content = message is Map ? message['content'] : null;
      final text = _contentText(content).trim();
      if (text.isEmpty) {
        throw const VisionOcrException('未能从图片中识别出文字');
      }
      final usage = body is Map ? body['usage'] : null;
      final inputTokens = usage is Map
          ? (usage['prompt_tokens'] as num?)?.toInt() ?? 0
          : 0;
      final outputTokens = usage is Map
          ? (usage['completion_tokens'] as num?)?.toInt() ?? 0
          : 0;
      await _logUsage(
        providerName: picked.$1.name,
        model: picked.$2.modelId,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        durationMs: watch.elapsedMilliseconds,
        status: UsageStatus.ok,
      );
      return VisionOcrResult(
        text: text,
        providerName: picked.$1.name,
        model: picked.$2.modelId,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
      );
    } on VisionOcrException {
      rethrow;
    } on DioException catch (e) {
      await _logUsage(
        providerName: picked.$1.name,
        model: picked.$2.modelId,
        inputTokens: 0,
        outputTokens: 0,
        durationMs: watch.elapsedMilliseconds,
        status: UsageStatus.error,
        error: e.message,
      );
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        throw VisionOcrException('识别失败：API Key 无效或无权限（HTTP $code）');
      }
      if (code == 429) {
        throw const VisionOcrException('识别失败：请求过于频繁，请稍后重试');
      }
      throw VisionOcrException('识别请求失败：${e.message ?? '网络错误'}');
    }
  }

  Future<(ProviderRow, ModelRow)?> _pickVisionModel() async {
    final candidates = <(ProviderRow, ModelRow)>[];
    for (final provider in await _db.providersDao.getAll()) {
      final keyRef = provider.keyRef;
      if (keyRef == null || keyRef.isEmpty) continue;
      for (final model in await _db.modelsDao.activeByProvider(provider.id)) {
        if (looksVisionModel(modelId: model.modelId, tagsJson: model.tags)) {
          candidates.add((provider, model));
        }
      }
    }
    return candidates.isEmpty ? null : candidates.first;
  }

  /// OpenAI 兼容 content 可能是字符串或分段数组，拼接其中的文本段。
  String _contentText(Object? content) {
    if (content is String) return content;
    if (content is List) {
      final buffer = StringBuffer();
      for (final part in content) {
        if (part is Map && part['text'] != null) {
          buffer.write(part['text']);
        } else if (part is String) {
          buffer.write(part);
        }
      }
      return buffer.toString();
    }
    return '';
  }

  String _trimBaseUrl(String baseUrl) =>
      baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  void _ensureOk(Response<Object> response) {
    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) return;
    final data = response.data;
    final message = data is Map ? '${data['message'] ?? ''}' : '';
    throw VisionOcrException(
      '识别失败：HTTP $code${message.isEmpty ? '' : '（$message）'}',
    );
  }

  Future<void> _logUsage({
    required String providerName,
    required String model,
    required int inputTokens,
    required int outputTokens,
    required int durationMs,
    required UsageStatus status,
    String? error,
  }) {
    final cost = status == UsageStatus.ok
        ? PriceTable.estimateCost(
            modelId: model,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
          )
        : null;
    return _db.usageLogDao.add(
      UsageLogsCompanion.insert(
        module: 'fragments',
        taskType: 'ocr',
        providerName: providerName,
        model: model,
        presetCode: const Value('standard'),
        inputTokens: Value(inputTokens),
        outputTokens: Value(outputTokens),
        costEstimate: Value(cost),
        durationMs: Value(durationMs),
        status: status,
        error: Value(error),
      ),
    );
  }
}
