// 本地密文封装：AES-GCM(256) + 主密钥存系统安全存储（Windows 凭据管理器 /
// Android Keystore）。密码本的字段与备注经此加密后入库，数据库内不落明文。
import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../storage/secure_keys.dart';

/// 主密钥在安全存储中的引用名。
const _masterKeyRef = 'creative_kb.secret_box.master_v1';

/// AES-GCM 文本加解密。密文格式：base64( nonce(12B) + cipherText + mac(16B) )。
class SecretBoxService {
  SecretBoxService({KeyStore? store}) : _store = store ?? const SecureKeyStore();

  final KeyStore _store;
  SecretKey? _cached;

  Future<SecretKey> _masterKey() async {
    if (_cached != null) return _cached!;
    final existing = await _store.read(_masterKeyRef);
    if (existing != null && existing.isNotEmpty) {
      final key = SecretKey(base64Decode(existing));
      _cached = key;
      return key;
    }
    final key = await AesGcm.with256bits().newSecretKey();
    await _store.write(_masterKeyRef, base64Encode(await key.extractBytes()));
    _cached = key;
    return key;
  }

  Future<String> encrypt(String plainText) async {
    final algorithm = AesGcm.with256bits();
    final key = await _masterKey();
    final nonce = algorithm.newNonce();
    final box = await algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: nonce,
    );
    return base64Encode([...nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  Future<String> decrypt(String payload) async {
    final raw = base64Decode(payload);
    // nonce(12) + mac(16) 为最小合法长度（空明文时 cipherText 为空）。
    if (raw.length < 12 + 16) {
      throw const FormatException('密文长度不足');
    }
    final nonce = raw.sublist(0, 12);
    final mac = raw.sublist(raw.length - 16);
    final cipher = raw.sublist(12, raw.length - 16);
    final algorithm = AesGcm.with256bits();
    final clear = await algorithm.decrypt(
      SecretBox(cipher, nonce: nonce, mac: Mac(mac)),
      secretKey: await _masterKey(),
    );
    return utf8.decode(clear);
  }
}
