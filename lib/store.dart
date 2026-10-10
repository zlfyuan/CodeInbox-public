import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'analytics.dart';
import 'data/account_repository.dart';
import 'data/adapter_registry.dart';
import 'data/adapters/coding_adapter.dart';
import 'data/adapters/codeup_adapter.dart';
import 'data/adapters/gitee_adapter.dart';
import 'data/adapters/github_adapter.dart';
import 'data/adapters/gitlab_adapter.dart';
import 'data/adapters/gongfeng_adapter.dart';
import 'data/inbox_cache.dart';
import 'data/open_url.dart';
import 'domain/forge_adapter.dart';
import 'domain/inbox.dart';
import 'domain/models.dart';

class AppStore extends ChangeNotifier {
  AppStore({
    required AccountRepository accounts,
    required AdapterRegistry adapters,
    required InboxCache cache,
    required this.openUrl,
    this.pollInterval = const Duration(seconds: 60),
  })  : _accountsRepo = accounts,
        _adapters = adapters,
        _cache = cache;

  final AccountRepository _accountsRepo;
  final AdapterRegistry _adapters;
  final InboxCache _cache;

  /// 公开读访问,UI 用以查询 platform → adapter 能力(如 supportedCapabilities)。
  AdapterRegistry get adapters => _adapters;
  final IOpenUrl openUrl;
  // Null disables the foreground poll (widget tests).
  final Duration? pollInterval;

  List<PlatformAccount> accounts = [];
  List<ChangeRequest> inbox = [];
  List<NotificationItem> notifications = [];
  List<Repo> repos = [];
  InboxFilter inboxFilter = const InboxFilter();

  bool inboxLoading = false;
  bool inboxLoadingMore = false;
  bool inboxHasMore = false;
  int _inboxPage = 1;
  // Smallest adapter page (Gitee / Gongfeng / CODING). A shorter page is last.
  static const inboxPageSize = 20;
  bool notificationsLoading = false;
  bool reposLoading = false;
  String? inboxError;
  String? notificationsError;
  String? reposError;
  DateTime? lastRefreshedAt;
  Timer? _poll;
  static const _badge = MethodChannel('codeinbox/badge');

  List<ChangeRequest> get filteredInbox => applyInboxFilter(inbox, inboxFilter);

  int get inboxBadge {
    final n = filteredInbox.length;
    return n > 99 ? 99 : n;
  }

  Future<void> load() async {
    accounts = await _accountsRepo.loadAccounts();
    inbox = await _cache.read();
    notifyListeners();
  }

  void setInboxFilter(InboxFilter filter) {
    inboxFilter = filter;
    notifyListeners();
  }

  Future<void> addAccount({
    required ForgePlatform platform,
    required String token,
    String? displayName,
    String? baseUrl,
    String? orgId,
  }) async {
    final adapter = _adapters.forPlatform(platform);
    final profile = await adapter.verifyAndProfile(
      token: token,
      displayName: displayName,
      baseUrl: baseUrl,
      orgId: orgId,
    );
    final existing = accounts.where((a) => a.sameIdentity(profile)).toList();
    for (final old in existing) {
      await _accountsRepo.revoke(old.id);
    }
    await _accountsRepo.saveAccount(profile, token);
    accounts = await _accountsRepo.loadAccounts();
    track('account_add_success', {'platform': platform.name, 'auth_type': 'pat'});
    notifyListeners();
    await refreshAll();
  }

  Future<void> removeAccount(String id) async {
    await _accountsRepo.revoke(id);
    accounts = await _accountsRepo.loadAccounts();
    inbox = inbox.where((e) => e.accountId != id).toList();
    notifications = notifications.where((e) => e.accountId != id).toList();
    repos = repos.where((e) => e.accountId != id).toList();
    await _cache.write(inbox);
    notifyListeners();
  }

  void startPolling() {
    _poll?.cancel();
    final interval = pollInterval;
    if (interval == null || interval <= Duration.zero) return;
    _poll = Timer.periodic(interval, (_) {
      if (accounts.isEmpty) return;
      refreshAll();
    });
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> refreshAll() async {
    await Future.wait([refreshInbox(), refreshRepos()]);
    await refreshNotifications();
  }

  Future<void> refreshInbox() async {
    _inboxPage = 1;
    inboxLoading = true;
    notifyListeners();
    await _fetchInboxPage(page: 1, append: false);
  }

  Future<void> loadMoreInbox() async {
    if (!inboxHasMore || inboxLoading || inboxLoadingMore) return;
    inboxLoadingMore = true;
    notifyListeners();
    _inboxPage += 1;
    await _fetchInboxPage(page: _inboxPage, append: true);
  }

  Future<void> _fetchInboxPage({required int page, required bool append}) async {
    final collected = <ChangeRequest>[];
    final failed = <String>{};
    final errors = <String>[];
    await Future.wait(accounts.map((account) async {
      final token = await _accountsRepo.tokenFor(account.id);
      if (token == null) {
        failed.add(account.id);
        errors.add('${platformLabelEn(account.platform)} @${account.login}: missing token');
        return;
      }
      try {
        collected.addAll(
          await _adapters.forPlatform(account.platform).listInbox(account: account, token: token, page: page),
        );
      } on AdapterException catch (e) {
        failed.add(account.id);
        errors.add('${platformLabelEn(account.platform)} @${account.login}: ${e.message}');
      } catch (_) {
        failed.add(account.id);
        errors.add('${platformLabelEn(account.platform)} @${account.login}: failed');
      }
    }));
    if (append) {
      inbox = mergeInbox([...inbox, ...collected]);
    } else {
      final kept = inbox.where((item) => failed.contains(item.accountId));
      inbox = mergeInbox([...collected, ...kept]);
    }
    await _cache.write(inbox);
    inboxError = errors.isEmpty ? null : errors.join('\n');
    inboxHasMore = collected.length >= inboxPageSize;
    inboxLoading = false;
    inboxLoadingMore = false;
    lastRefreshedAt = DateTime.now();
    track('inbox_refresh', {'count': inbox.length, 'platforms': accounts.map((a) => a.platform.name).toSet().join(',')});
    await _updateAppBadge();
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    notificationsLoading = true;
    notifyListeners();
    final collected = <NotificationItem>[];
    final failed = <String>{};
    final errors = <String>[];
    await Future.wait(accounts.map((account) async {
      final token = await _accountsRepo.tokenFor(account.id);
      if (token == null) {
        failed.add(account.id);
        return;
      }
      try {
        collected.addAll(
          await _adapters.forPlatform(account.platform).listNotifications(account: account, token: token),
        );
      } on AdapterException catch (e) {
        failed.add(account.id);
        if (e.kind == AdapterErrorKind.unsupported) {
          errors.add('${platformLabelEn(account.platform)} notifications are not available');
        } else {
          errors.add('${platformLabelEn(account.platform)} @${account.login}: ${e.message}');
        }
      } catch (_) {
        failed.add(account.id);
        errors.add('${platformLabelEn(account.platform)} @${account.login}: failed');
      }
    }));
    final kept = notifications.where((item) => failed.contains(item.accountId));
    notifications = [...collected, ...kept]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _synthesizeAlerts(failed);
    notificationsError = errors.isEmpty ? null : errors.join('\n');
    notificationsLoading = false;
    notifyListeners();
  }

  // These forges have no GitHub-style notification inbox.
  static const _alertFallback = {ForgePlatform.codeup, ForgePlatform.gongfeng, ForgePlatform.coding};

  void _synthesizeAlerts(Set<String> failed) {
    final have = notifications.map((n) => n.accountId).toSet();
    for (final account in accounts) {
      if (failed.contains(account.id)) continue;
      if (!_alertFallback.contains(account.platform)) continue;
      // Native events already filled Alerts for this account.
      if (have.contains(account.id)) continue;
      notifications.addAll(
        inbox.where((e) => e.accountId == account.id).map(NotificationItem.fromChangeRequest),
      );
    }
    notifications.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> _updateAppBadge() async {
    try {
      await _badge.invokeMethod<void>('setBadge', inboxBadge);
    } catch (_) {
      // Channel is absent in tests and some hosts.
    }
  }

  Future<void> refreshRepos() async {
    reposLoading = true;
    notifyListeners();
    final collected = <Repo>[];
    final failed = <String>{};
    final errors = <String>[];
    await Future.wait(accounts.map((account) async {
      final token = await _accountsRepo.tokenFor(account.id);
      if (token == null) {
        failed.add(account.id);
        return;
      }
      try {
        collected.addAll(await _adapters.forPlatform(account.platform).listRepos(account: account, token: token));
      } on AdapterException catch (e) {
        failed.add(account.id);
        errors.add('${platformLabelEn(account.platform)} @${account.login}: ${e.message}');
      } catch (_) {
        failed.add(account.id);
        errors.add('${platformLabelEn(account.platform)} @${account.login}: failed');
      }
    }));
    final kept = repos.where((item) => failed.contains(item.accountId));
    repos = [...collected, ...kept]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    reposError = errors.isEmpty ? null : errors.join('\n');
    reposLoading = false;
    notifyListeners();
  }

  Future<void> openWeb(String url) async {
    if (url.isEmpty) return;
    track('pr_open_in_browser');
    await openUrl.open(url);
  }

  Future<(PlatformAccount, String, ForgeAdapter)> _resolve(ChangeRequest cr) async {
    final account = accounts.where((a) => a.id == cr.accountId).firstOrNull;
    if (account == null) {
      throw AdapterException.http(404, 'Account not found');
    }
    final token = await _accountsRepo.tokenFor(account.id);
    if (token == null) throw AdapterException.unauthorized();
    return (account, token, _adapters.forPlatform(account.platform));
  }

  Future<List<ChangeRequest>> loadRepoPulls(Repo repo) async {
    final account = accounts.where((a) => a.id == repo.accountId).firstOrNull;
    if (account == null) throw AdapterException.http(404, 'Account not found');
    final token = await _accountsRepo.tokenFor(account.id);
    if (token == null) throw AdapterException.unauthorized();
    List<ChangeRequest> remote = const [];
    try {
      remote = await _adapters.forPlatform(account.platform).listOpenChangeRequests(
            account: account,
            token: token,
            repo: repo,
          );
    } on FormatException {
      throw AdapterException.http(200, 'Unexpected response listing pull requests');
    }
    final extra = inbox.where((e) => e.accountId == repo.accountId && e.repoFullName == repo.fullName);
    return mergeInbox([...remote, ...extra]);
  }

  Future<String?> loadRepoReadme(Repo repo) async {
    final account = accounts.where((a) => a.id == repo.accountId).firstOrNull;
    if (account == null) throw AdapterException.http(404, 'Account not found');
    final token = await _accountsRepo.tokenFor(account.id);
    if (token == null) throw AdapterException.unauthorized();
    try {
      return await _adapters.forPlatform(account.platform).getReadme(
            account: account,
            token: token,
            repo: repo,
          );
    } on AdapterException catch (e) {
      if (e.kind == AdapterErrorKind.unsupported) return null;
      rethrow;
    } on FormatException {
      return null;
    }
  }

  Future<List<Issue>> loadRepoIssues(Repo repo, {IssueState state = IssueState.open}) async {
    final account = accounts.where((a) => a.id == repo.accountId).firstOrNull;
    if (account == null) throw AdapterException.http(404, 'Account not found');
    final token = await _accountsRepo.tokenFor(account.id);
    if (token == null) throw AdapterException.unauthorized();
    try {
      return await _adapters.forPlatform(account.platform).listIssues(
            account: account,
            token: token,
            repo: repo,
            state: state,
          );
    } on FormatException {
      throw AdapterException.http(200, 'Unexpected response listing issues');
    }
  }

  Future<List<Branch>> loadRepoBranches(Repo repo) async {
    final account = accounts.where((a) => a.id == repo.accountId).firstOrNull;
    if (account == null) throw AdapterException.http(404, 'Account not found');
    final token = await _accountsRepo.tokenFor(account.id);
    if (token == null) throw AdapterException.unauthorized();
    return _adapters.forPlatform(account.platform).listBranches(
          account: account,
          token: token,
          repo: repo,
        );
  }

  Future<List<GitCommit>> loadRepoCommits(Repo repo, {String? sha}) async {
    final account = accounts.where((a) => a.id == repo.accountId).firstOrNull;
    if (account == null) throw AdapterException.http(404, 'Account not found');
    final token = await _accountsRepo.tokenFor(account.id);
    if (token == null) throw AdapterException.unauthorized();
    return _adapters.forPlatform(account.platform).listCommits(
          account: account,
          token: token,
          repo: repo,
          sha: sha,
        );
  }

  Future<List<Contributor>> loadRepoContributors(Repo repo) async {
    final account = accounts.where((a) => a.id == repo.accountId).firstOrNull;
    if (account == null) throw AdapterException.http(404, 'Account not found');
    final token = await _accountsRepo.tokenFor(account.id);
    if (token == null) throw AdapterException.unauthorized();
    return _adapters.forPlatform(account.platform).listContributors(
          account: account,
          token: token,
          repo: repo,
        );
  }

  Future<IssueDetail> loadIssueDetail(Issue summary) async {
    track('issue_open', {'platform': summary.platform.name});
    final account = accounts.where((a) => a.id == summary.accountId).firstOrNull;
    if (account == null) throw AdapterException.http(404, 'Account not found');
    final token = await _accountsRepo.tokenFor(account.id);
    if (token == null) throw AdapterException.unauthorized();
    final adapter = _adapters.forPlatform(account.platform);
    final issue = await adapter.getIssue(account: account, token: token, summary: summary);
    final comments = await adapter.listIssueComments(account: account, token: token, issue: issue);
    return IssueDetail(issue: issue, comments: comments);
  }

  Future<CrDetail> loadDetail(ChangeRequest summary) async {
    track('pr_open', {'platform': summary.platform.name});
    final (account, token, adapter) = await _resolve(summary);
    final cr = await adapter.getChangeRequest(account: account, token: token, summary: summary);
    final files = await adapter.listFiles(account: account, token: token, cr: cr);
    final comments = await adapter.listComments(account: account, token: token, cr: cr);
    return CrDetail(
      changeRequest: cr,
      files: files,
      comments: comments,
      supportedReviews: adapter.supportedReviews,
    );
  }

  Future<void> submitReview(ChangeRequest cr, ReviewAction action) async {
    final (account, token, adapter) = await _resolve(cr);
    await adapter.submitReview(account: account, token: token, cr: cr, action: action);
    track('pr_review_submit', {'type': action.type.name, 'platform': cr.platform.name});
    if (action.type == ReviewType.merge) {
      inbox = inbox.where((e) => e.id != cr.id).toList();
      await _cache.write(inbox);
      notifyListeners();
    }
  }

  /// 仓库级 Star。调用前应先在 UI 端校验 supportedCapabilities.star。
  /// 不在 AppStore 缓存 star 状态(本批不引入 isStarred)。
  Future<void> starRepo(Repo repo) async {
    final account = accounts.where((a) => a.id == repo.accountId).firstOrNull;
    if (account == null) throw AdapterException.http(404, 'Account not found');
    final token = await _accountsRepo.tokenFor(account.id);
    if (token == null) throw AdapterException.unauthorized();
    await _adapters.forPlatform(account.platform).starRepo(
          account: account,
          token: token,
          repo: repo,
        );
    track('repo_star', {'platform': repo.platform.name});
  }

  Future<void> unstarRepo(Repo repo) async {
    final account = accounts.where((a) => a.id == repo.accountId).firstOrNull;
    if (account == null) throw AdapterException.http(404, 'Account not found');
    final token = await _accountsRepo.tokenFor(account.id);
    if (token == null) throw AdapterException.unauthorized();
    await _adapters.forPlatform(account.platform).unstarRepo(
          account: account,
          token: token,
          repo: repo,
        );
    track('repo_unstar', {'platform': repo.platform.name});
  }

  String tokenCreateUrl(ForgePlatform platform, {String? baseUrl}) => switch (platform) {
        ForgePlatform.github => githubTokenCreateUrl,
        ForgePlatform.gitee => giteeTokenCreateUrl,
        ForgePlatform.gitlab => gitlabTokenSettingsUrl(baseUrl),
        ForgePlatform.codeup => codeupTokenSettingsUrl,
        ForgePlatform.gongfeng => gongfengTokenSettingsUrl(baseUrl),
        ForgePlatform.coding => codingTokenSettingsUrl(baseUrl),
      };

  String tokenRevokeUrl(ForgePlatform platform, {String? baseUrl}) => switch (platform) {
        ForgePlatform.github => githubRevokeUrl,
        ForgePlatform.gitee => giteeRevokeUrl,
        ForgePlatform.gitlab => gitlabTokenSettingsUrl(baseUrl),
        ForgePlatform.codeup => codeupTokenSettingsUrl,
        ForgePlatform.gongfeng => gongfengTokenSettingsUrl(baseUrl),
        ForgePlatform.coding => codingTokenSettingsUrl(baseUrl),
      };
}

class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({super.key, required AppStore store, required super.child}) : super(notifier: store);

  static AppStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope.of() called without AppScope');
    return scope!.notifier!;
  }
}
