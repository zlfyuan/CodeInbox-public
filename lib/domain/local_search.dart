import 'models.dart';

/// Client-side contains-match. Empty query keeps everything.
bool matchesQuery(String query, Iterable<String?> fields) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  for (final field in fields) {
    if (field != null && field.toLowerCase().contains(q)) return true;
  }
  return false;
}

bool inboxMatchesQuery(ChangeRequest item, String query) => matchesQuery(query, [
      item.title,
      item.repoFullName,
      item.authorLogin,
    ]);

bool alertMatchesQuery(NotificationItem item, String query) => matchesQuery(query, [
      item.title,
      item.repoFullName,
      item.reason,
      platformLabelEn(item.platform),
    ]);

bool repoMatchesQuery(Repo item, String query) => matchesQuery(query, [
      item.fullName,
      item.description,
      item.language,
      ...item.topics,
    ]);

class RepoGroup {
  const RepoGroup({required this.platform, required this.repos, this.accountLabel});

  final ForgePlatform platform;
  final String? accountLabel;
  final List<Repo> repos;

  String get title {
    final name = platformLabelEn(platform);
    final n = repos.length;
    if (accountLabel == null || accountLabel!.isEmpty) return '$name ($n)';
    return '$name · $accountLabel ($n)';
  }
}

/// Platform sections; split by account when the same platform has two logins.
List<RepoGroup> groupRepos(List<Repo> repos, List<PlatformAccount> accounts, {String query = ''}) {
  final filtered = repos.where((r) => repoMatchesQuery(r, query)).toList();
  final perPlatform = <ForgePlatform, int>{};
  for (final account in accounts) {
    perPlatform[account.platform] = (perPlatform[account.platform] ?? 0) + 1;
  }
  final groups = <RepoGroup>[];
  for (final platform in ForgePlatform.values) {
    final slice = filtered.where((r) => r.platform == platform).toList();
    if (slice.isEmpty) continue;
    if ((perPlatform[platform] ?? 0) <= 1) {
      groups.add(RepoGroup(platform: platform, repos: slice));
      continue;
    }
    final ids = slice.map((r) => r.accountId).toSet().toList()
      ..sort((a, b) {
        final la = accounts.where((x) => x.id == a).firstOrNull?.label ?? a;
        final lb = accounts.where((x) => x.id == b).firstOrNull?.label ?? b;
        return la.compareTo(lb);
      });
    for (final id in ids) {
      final account = accounts.where((a) => a.id == id).firstOrNull;
      groups.add(RepoGroup(
        platform: platform,
        accountLabel: account?.label,
        repos: slice.where((r) => r.accountId == id).toList(),
      ));
    }
  }
  return groups;
}
