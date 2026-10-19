// API Key 安全存储封装（docs/00 D2）：Key 只进 flutter_secure_storage
// （Windows 凭据管理器 / Android Keystore），数据库 providers.keyRef 仅存引用名。
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 可替换的键值存储接口：生产实现为 FlutterSecureStorage；
/// 测试可注入纯 Dart 内存实现，避免平台通道依赖。
abstract class KeyStore {
  Future<String?> read(String key);

  Future<void> write(String key, String? value);

  Future<void> delete(String key);

  Future<bool> containsKey(String key);
}

class _FlutterSecureKeyStore implements KeyStore {
  const _FlutterSecureKeyStore();

  static const _storage = FlutterSecureStorage();

  @override
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String? value) =>
      _storage.write(key: key, value: value);
}

/// API Key 存取。keyRef 引用名的生成见 core/llm/providers.dart 的 buildKeyRef。
class SecureKeys {
  SecureKeys({KeyStore? store})
    : _store = store ?? const _FlutterSecureKeyStore();

  final KeyStore _store;

  /// 保存/覆盖某个厂商配置的 API Key。
  Future<void> save(String keyRef, String apiKey) =>
      _store.write(keyRef, apiKey);

  /// 读取 API Key；未配置返回 null。
  Future<String?> read(String keyRef) => _store.read(keyRef);

  Future<bool> has(String keyRef) => _store.containsKey(keyRef);

  /// 删除厂商配置时同步清除密文。
  Future<void> delete(String keyRef) => _store.delete(keyRef);
}
