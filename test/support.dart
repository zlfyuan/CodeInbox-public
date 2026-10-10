import 'dart:convert';
import 'dart:io';

import 'package:codeinbox/data/account_repository.dart';
import 'package:codeinbox/data/adapter_registry.dart';
import 'package:codeinbox/data/inbox_cache.dart';
import 'package:codeinbox/data/open_url.dart';
import 'package:codeinbox/data/prefs.dart';
import 'package:codeinbox/data/secure_store.dart';
import 'package:codeinbox/domain/forge_adapter.dart';
import 'package:codeinbox/domain/models.dart';
import 'package:codeinbox/store.dart';

dynamic loadFixture(String name) {
  return jsonDecode(File('test/fixtures/$name').readAsStringSync());
}

ChangeRequest samplePr({
  String id = 'github:a:acme/box:12',
  int number = 12,
  ForgePlatform platform = ForgePlatform.github,
  String accountId = 'a',
  String repo = 'acme/box',
  String title = 'Fix inbox merge',
  String webUrl = 'https://github.com/acme/box/pull/12',
  DateTime? updatedAt,
  bool reviewRequested = true,
  bool assignedToMe = false,
}) {
  final updated = updatedAt ?? DateTime.utc(2026, 9, 14, 8);
  return ChangeRequest(
    id: id,
    localNumber: number,
    platform: platform,
    accountId: accountId,
    repoFullName: repo,
    title: title,
    authorLogin: 'alice',
    webUrl: webUrl,
    updatedAt: updated,
    createdAt: DateTime.utc(2026, 9, 1, 10),
    reviewRequested: reviewRequested,
    assignedToMe: assignedToMe,
  );
}

Future<AppStore> makeStore({
  Map<ForgePlatform, ForgeAdapter>? adapters,
  List<PlatformAccount> accounts = const [],
  Map<String, String> tokens = const {},
}) async {
  final prefs = MemoryPrefs();
  final secure = MemorySecureStore();
  final repo = AccountRepository(secure: secure, prefs: prefs);
  for (final account in accounts) {
    await repo.saveAccount(account, tokens[account.id] ?? 'ghs_test_***');
  }
  final store = AppStore(
    accounts: repo,
    adapters: AdapterRegistry(adapters: adapters),
    cache: InboxCache(prefs),
    openUrl: RecordingOpenUrl(),
    pollInterval: null,
  );
  await store.load();
  return store;
}

PlatformAccount sampleAccount({
  String id = 'a',
  ForgePlatform platform = ForgePlatform.github,
  String login = 'octocat',
}) {
  return PlatformAccount(
    id: id,
    platform: platform,
    displayName: login,
    login: login,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

Repo sampleRepo({
  String id = 'r1',
  ForgePlatform platform = ForgePlatform.github,
  String accountId = 'a',
  String fullName = 'acme/box',
  String webUrl = 'https://github.com/acme/box',
  bool private = false,
  String defaultBranch = 'main',
  DateTime? updatedAt,
  String? description = 'Inbox for reviews',
  String? language = 'Dart',
  int starCount = 3,
  int forkCount = 1,
  int openIssueCount = 4,
  String? license = 'MIT',
  String? homepage = 'https://example.com',
  DateTime? createdAt,
  bool archived = false,
  bool fork = false,
  List<String> topics = const ['inbox', 'flutter'],
  RepoVisibility visibility = RepoVisibility.public,
}) {
  return Repo(
    id: id,
    platform: platform,
    accountId: accountId,
    fullName: fullName,
    webUrl: webUrl,
    private: private,
    defaultBranch: defaultBranch,
    updatedAt: updatedAt ?? DateTime.utc(2026, 9, 14),
    description: description,
    language: language,
    starCount: starCount,
    forkCount: forkCount,
    openIssueCount: openIssueCount,
    license: license,
    homepage: homepage,
    createdAt: createdAt ?? DateTime.utc(2026, 9, 1),
    archived: archived,
    fork: fork,
    topics: topics,
    visibility: visibility,
  );
}
