// 视觉 OCR 单测：请求形状（OpenAI 兼容多模态）、模型选择、结果解析、无模型提示。
import 'dart:convert';
import 'dart:typed_data';

import 'package:creative_kb/core/db/database.dart';
import 'package:creative_kb/core/llm/vision_ocr.dart';
import 'package:creative_kb/core/storage/secure_keys.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../llm/fake_adapter.dart';

class _MemoryKeyStore implements KeyStore {
  final Map<String, String> values = {};

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

void main() {
  late AppDatabase db;
  late _MemoryKeyStore keyStore;

  setUp(() async {
    db = AppDatabase.inMemory();
    keyStore = _MemoryKeyStore();
    final providerId = await db.providersDao.add(
      ProvidersCompanion.insert(
        name: '通义千问',
        baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
        keyRef: const Value('key_qwen'),
        presetCode: 'qwen',
      ),
    );
    await db.modelsDao.upsertModelId(
      providerId: providerId,
      modelId: 'qwen-vl-max',
      displayName: 'Qwen VL Max',
    );
    await keyStore.write('key_qwen', 'sk-qwen');
  });

  tearDown(() => db.close());

  test('识别：请求带 base64 图片与鉴权头，结果取 content，记账写 ocr 行', () async {
    final adapter = FakeAdapter(
      (options) async => ResponseBody.fromString(
        jsonEncode({
          'choices': [
            {
              'message': {'content': '识别到的第一行\n第二行'},
            },
          ],
          'usage': {'prompt_tokens': 1200, 'completion_tokens': 30},
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
    final service = VisionOcrService(
      db,
      dio: Dio()..httpClientAdapter = adapter,
      secureKeys: SecureKeys(store: keyStore),
    );
    final result = await service.recognize(
      Uint8List.fromList([1, 2, 3, 4]),
      mimeType: 'image/png',
    );
    expect(result.text, '识别到的第一行\n第二行');
    expect(result.model, 'qwen-vl-max');

    final request = adapter.requests.single;
    expect(request.path, contains('/chat/completions'));
    expect(request.headers['Authorization'], 'Bearer sk-qwen');
    final body = request.data as Map;
    expect(body['model'], 'qwen-vl-max');
    final messages = body['messages'] as List;
    final content = (messages.single as Map)['content'] as List;
    final imagePart = content.firstWhere(
      (part) => (part as Map)['type'] == 'image_url',
    ) as Map;
    final url = (imagePart['image_url'] as Map)['url'] as String;
    expect(url, startsWith('data:image/png;base64,'));
    expect(url, endsWith(base64Encode([1, 2, 3, 4])));

    final rows = await db.usageLogDao.recent(limit: 10);
    final ocrRow = rows.firstWhere((r) => r.taskType == 'ocr');
    expect(ocrRow.module, 'fragments');
    expect(ocrRow.inputTokens, 1200);
  });

  test('无视觉模型 → 明确提示配置 qwen-vl / glm-4v', () async {
    // 替换为纯文本模型。
    final provider = (await db.providersDao.getAll()).single;
    await db.modelsDao.removeByProvider(provider.id);
    await db.modelsDao.upsertModelId(
      providerId: provider.id,
      modelId: 'qwen-plus',
      displayName: 'Qwen Plus',
    );
    final service = VisionOcrService(
      db,
      dio: Dio()
        ..httpClientAdapter = FakeAdapter(
          (options) async => ResponseBody.fromString('{}', 200),
        ),
      secureKeys: SecureKeys(store: keyStore),
    );
    await expectLater(
      service.recognize(Uint8List.fromList([1])),
      throwsA(
        isA<VisionOcrException>().having(
          (e) => e.message,
          'message',
          contains('视觉模型'),
        ),
      ),
    );
  });

  test('上游 401 → 可读异常', () async {
    final service = VisionOcrService(
      db,
      dio: Dio()
        ..httpClientAdapter = FakeAdapter(
          (options) async => ResponseBody.fromString(
            jsonEncode({'message': 'invalid key'}),
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        ),
      secureKeys: SecureKeys(store: keyStore),
    );
    await expectLater(
      service.recognize(Uint8List.fromList([1])),
      throwsA(isA<VisionOcrException>()),
    );
  });
}
