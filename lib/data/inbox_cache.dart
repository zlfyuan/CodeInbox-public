import 'dart:convert';

import '../domain/models.dart';
import 'prefs.dart';

/// Inbox 磁盘缓存。底层 [IPrefs]，鸿蒙与 iOS/Android 同一套 key。
class InboxCache {
  InboxCache(this._prefs);

  static const key = 'inbox_cache';

  final IPrefs _prefs;

  Future<void> write(List<ChangeRequest> items) async {
    final payload = {
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
    await _prefs.setString(key, jsonEncode(payload));
  }

  Future<List<ChangeRequest>> read() async {
    final raw = await _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final items = map['items'] as List<dynamic>? ?? [];
      return items.map((e) => ChangeRequest.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
