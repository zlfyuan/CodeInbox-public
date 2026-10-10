import 'package:flutter/services.dart';

import '../../data/secure_store.dart';

/// 鸿蒙 Token 存储。通道 `codeinbox/secure_store` → HUKS AES-256-GCM，
/// 密文落在独立 preferences `codeinbox_secure`。
///
/// 不走 `flutter_secure_storage`：官方插件没有 ohos 实现。
class OhosSecureStore implements ISecureStore {
  OhosSecureStore({MethodChannel? channel})
      : _ch = channel ?? const MethodChannel('codeinbox/secure_store');

  final MethodChannel _ch;

  @override
  Future<void> write(String key, String value) =>
      _ch.invokeMethod<void>('write', {'key': key, 'value': value});

  @override
  Future<String?> read(String key) =>
      _ch.invokeMethod<String>('read', {'key': key});

  @override
  Future<void> delete(String key) =>
      _ch.invokeMethod<void>('delete', {'key': key});
}
