import 'package:codeinbox/data/account_repository.dart';
import 'package:codeinbox/data/prefs.dart';
import 'package:codeinbox/data/secure_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  test('revoke deletes token from secure store', () async {
    final prefs = MemoryPrefs();
    final secure = MemorySecureStore();
    final repo = AccountRepository(secure: secure, prefs: prefs);
    final account = sampleAccount();
    await repo.saveAccount(account, 'ghs_test_***');
    expect(await repo.tokenFor(account.id), 'ghs_test_***');
    await repo.revoke(account.id);
    expect(await repo.tokenFor(account.id), isNull);
    expect(await repo.loadAccounts(), isEmpty);
  });
}
