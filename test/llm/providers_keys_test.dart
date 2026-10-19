// 厂商预设（A2）、keyRef 生成（D2）与 SecureKeys 封装。
import 'package:creative_kb/core/llm/providers.dart';
import 'package:creative_kb/core/storage/secure_keys.dart';
import 'package:flutter_test/flutter_test.dart';

/// 内存 KeyStore：模拟 secure storage，无平台通道。
class InMemoryKeyStore implements KeyStore {
  final Map<String, String> data = {};

  @override
  Future<bool> containsKey(String key) async => data.containsKey(key);

  @override
  Future<void> delete(String key) async => data.remove(key);

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      data.remove(key);
    } else {
      data[key] = value;
    }
  }
}

void main() {
  group('厂商预设（A2，baseUrl 见 docs/01）', () {
    test('四个内置预设的 baseUrl 与规格一致', () {
      expect(ProviderPreset.deepseek.baseUrl, 'https://api.deepseek.com/v1');
      expect(
        ProviderPreset.qwen.baseUrl,
        'https://dashscope.aliyuncs.com/compatible-mode/v1',
      );
      expect(
        ProviderPreset.doubao.baseUrl,
        'https://ark.cn-beijing.volces.com/api/v3',
      );
      expect(
        ProviderPreset.zhipu.baseUrl,
        'https://open.bigmodel.cn/api/paas/v4',
      );
    });

    test('custom 档 baseUrl 留空由用户填写；byCode 未知名回落 custom', () {
      expect(ProviderPreset.custom.baseUrl, isEmpty);
      expect(ProviderPreset.byCode('zhipu'), ProviderPreset.zhipu);
      expect(ProviderPreset.byCode('nope'), ProviderPreset.custom);
    });
  });

  group('keyRef 生成（docs/00 D2：key_deepseek_main 形态）', () {
    test('ASCII 名称归一为小写下划线片段', () {
      expect(
        buildKeyRef(presetCode: 'deepseek', providerName: 'Main Key'),
        'key_deepseek_main_key',
      );
      expect(
        buildKeyRef(presetCode: 'qwen', providerName: 'work'),
        'key_qwen_work',
      );
    });

    test('纯中文名称回落 main，数据库只存引用名不存密文', () {
      expect(
        buildKeyRef(presetCode: 'deepseek', providerName: '主力'),
        'key_deepseek_main',
      );
    });
  });

  group('SecureKeys 封装', () {
    test('save/read/has/delete 往返，可覆盖', () async {
      final keys = SecureKeys(store: InMemoryKeyStore());
      expect(await keys.has('key_deepseek_main'), isFalse);
      expect(await keys.read('key_deepseek_main'), isNull);

      await keys.save('key_deepseek_main', 'sk-abc');
      expect(await keys.has('key_deepseek_main'), isTrue);
      expect(await keys.read('key_deepseek_main'), 'sk-abc');

      await keys.save('key_deepseek_main', 'sk-new');
      expect(await keys.read('key_deepseek_main'), 'sk-new');

      await keys.delete('key_deepseek_main');
      expect(await keys.read('key_deepseek_main'), isNull);
      expect(await keys.has('key_deepseek_main'), isFalse);
    });

    test('不同 keyRef 相互隔离', () async {
      final keys = SecureKeys(store: InMemoryKeyStore());
      await keys.save('key_deepseek_main', 'sk-1');
      await keys.save('key_qwen_work', 'sk-2');
      expect(await keys.read('key_deepseek_main'), 'sk-1');
      await keys.delete('key_deepseek_main');
      expect(await keys.read('key_qwen_work'), 'sk-2');
    });
  });

  test('ProviderConfig 承载解出的密文与 baseUrl', () {
    const config = ProviderConfig(
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com/v1',
      apiKey: 'sk-1',
    );
    expect(config.name, 'DeepSeek');
    expect(config.apiKey, 'sk-1');
  });
}
