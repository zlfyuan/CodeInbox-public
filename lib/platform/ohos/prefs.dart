import 'package:flutter/services.dart';

import '../../data/prefs.dart';

/// 鸿蒙 KV。通道 `codeinbox/prefs` → ArkTS `@ohos.data.preferences`。
///
/// 不走 `shared_preferences`：官方插件没有 ohos 实现，本仓也不接 CPF 三方 fork。
class OhosPrefs implements IPrefs {
  OhosPrefs({MethodChannel? channel})
      : _ch = channel ?? const MethodChannel('codeinbox/prefs');

  final MethodChannel _ch;

  /// 等 ArkTS 端 preferences store 打开。`main()` 在 `store.load()` 之前必须 await。
  Future<void> ready() => _ch.invokeMethod<void>('ready');

  @override
  Future<String?> getString(String key) =>
      _ch.invokeMethod<String>('getString', {'key': key});

  @override
  Future<int?> getInt(String key) =>
      _ch.invokeMethod<int>('getInt', {'key': key});

  @override
  Future<bool?> getBool(String key) =>
      _ch.invokeMethod<bool>('getBool', {'key': key});

  @override
  Future<void> setString(String key, String value) =>
      _ch.invokeMethod<void>('setString', {'key': key, 'value': value});

  @override
  Future<void> setInt(String key, int value) =>
      _ch.invokeMethod<void>('setInt', {'key': key, 'value': value});

  @override
  Future<void> setBool(String key, bool value) =>
      _ch.invokeMethod<void>('setBool', {'key': key, 'value': value});

  @override
  Future<void> remove(String key) =>
      _ch.invokeMethod<void>('remove', {'key': key});
}
