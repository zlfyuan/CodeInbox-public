import 'package:shared_preferences/shared_preferences.dart';

/// 跨平台 KV。iOS / Android 包 [SharedPreferences]；鸿蒙没有该插件的
/// ohos 实现（本仓不接 CPF 三方 fork），走 MethodChannel → ArkTS preferences。
///
/// 全部异步：鸿蒙端读写都是 Promise，不能用 SharedPreferences 那种同步 getter。
abstract class IPrefs {
  Future<String?> getString(String key);
  Future<int?> getInt(String key);
  Future<bool?> getBool(String key);

  Future<void> setString(String key, String value);
  Future<void> setInt(String key, int value);
  Future<void> setBool(String key, bool value);
  Future<void> remove(String key);
}

/// iOS / Android 默认实现。持有已 `getInstance()` 的 [SharedPreferences]。
class SharedPrefsImpl implements IPrefs {
  SharedPrefsImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<String?> getString(String key) async => _prefs.getString(key);

  @override
  Future<int?> getInt(String key) async => _prefs.getInt(key);

  @override
  Future<bool?> getBool(String key) async => _prefs.getBool(key);

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}

/// 测试用内存 KV，对标 [MemorySecureStore]。
class MemoryPrefs implements IPrefs {
  final Map<String, Object> _map = {};

  @override
  Future<String?> getString(String key) async {
    final v = _map[key];
    return v is String ? v : null;
  }

  @override
  Future<int?> getInt(String key) async {
    final v = _map[key];
    return v is int ? v : null;
  }

  @override
  Future<bool?> getBool(String key) async {
    final v = _map[key];
    return v is bool ? v : null;
  }

  @override
  Future<void> setString(String key, String value) async => _map[key] = value;

  @override
  Future<void> setInt(String key, int value) async => _map[key] = value;

  @override
  Future<void> setBool(String key, bool value) async => _map[key] = value;

  @override
  Future<void> remove(String key) async => _map.remove(key);
}
