import 'dart:convert';

import '../domain/models.dart';
import 'prefs.dart';
import 'secure_store.dart';

/// 账号列表走 [IPrefs]（鸿蒙 preferences / iOS Android SharedPreferences）。
/// Token 只进 [ISecureStore]，禁止写进 prefs JSON。
class AccountRepository {
  AccountRepository({required ISecureStore secure, required IPrefs prefs})
      : _secure = secure,
        _prefs = prefs;

  static const accountsKey = 'accounts';

  final ISecureStore _secure;
  final IPrefs _prefs;

  static String tokenKey(String accountId) => 'token:$accountId';

  Future<List<PlatformAccount>> loadAccounts() async {
    final raw = await _prefs.getString(accountsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => PlatformAccount.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveAccount(PlatformAccount account, String token) async {
    final accounts = await loadAccounts();
    final displaced = accounts.where((a) => a.sameIdentity(account));
    for (final old in displaced) {
      await _secure.delete(tokenKey(old.id));
    }
    final next = [
      ...accounts.where((a) => !a.sameIdentity(account)),
      account,
    ];
    await _prefs.setString(accountsKey, jsonEncode(next.map((a) => a.toJson()).toList()));
    await _secure.write(tokenKey(account.id), token);
  }

  Future<String?> tokenFor(String accountId) => _secure.read(tokenKey(accountId));

  Future<void> revoke(String accountId) async {
    final accounts = await loadAccounts();
    final next = accounts.where((a) => a.id != accountId).toList();
    await _prefs.setString(accountsKey, jsonEncode(next.map((a) => a.toJson()).toList()));
    await _secure.delete(tokenKey(accountId));
  }
}
