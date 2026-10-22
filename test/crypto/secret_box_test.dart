// SecretBox（AES-GCM）单测：加解密往返、篡改检测、密钥来自注入的 KeyStore。
import 'dart:convert';

import 'package:creative_kb/core/crypto/secret_box.dart';
import 'package:creative_kb/core/storage/secure_keys.dart';
import 'package:flutter_test/flutter_test.dart';

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
  test('加解密往返：中文/长文本/空串', () async {
    final store = _MemoryKeyStore();
    final box = SecretBoxService(store: store);
    for (final plain in ['123456', '撸啊撸的密码：abc!@#', '', '长文本' * 500]) {
      final cipher = await box.encrypt(plain);
      expect(cipher, isNot(equals(plain)));
      expect(await box.decrypt(cipher), plain);
    }
    // 主密钥只写入一次安全存储。
    expect(store.values.keys.where((k) => k.contains('secret_box')).length, 1);
  });

  test('同一明文两次加密密文不同（随机 nonce）', () async {
    final box = SecretBoxService(store: _MemoryKeyStore());
    final a = await box.encrypt('same');
    final b = await box.encrypt('same');
    expect(a, isNot(equals(b)));
    expect(await box.decrypt(a), 'same');
    expect(await box.decrypt(b), 'same');
  });

  test('密文被篡改 → 解密抛异常', () async {
    final box = SecretBoxService(store: _MemoryKeyStore());
    final cipher = await box.encrypt('secret');
    final raw = base64Decode(cipher);
    raw[raw.length - 1] ^= 0xFF; // 破坏 MAC
    await expectLater(
      box.decrypt(base64Encode(raw)),
      throwsA(anything),
    );
  });

  test('另一把主密钥无法解密（密钥隔离）', () async {
    final cipher = await SecretBoxService(store: _MemoryKeyStore()).encrypt(
      'secret',
    );
    await expectLater(
      SecretBoxService(store: _MemoryKeyStore()).decrypt(cipher),
      throwsA(anything),
    );
  });
}
