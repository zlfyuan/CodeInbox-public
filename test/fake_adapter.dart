import 'dart:async';

import 'package:codeinbox/domain/forge_adapter.dart';
import 'package:codeinbox/domain/models.dart';

class FakeAdapter implements ForgeAdapter {
  FakeAdapter({
    required this.platform,
    this.profile,
    this.inbox = const [],
    this.inboxMore = const [],
    this.notifications = const [],
    this.repos = const [],
    this.detail,
    this.files = const [],
    this.comments = const [],
    this.repoPulls = const [],
    this.readme = '# Welcome\n\nThis is the README.',
    this.verifyError,
    this.detailError,
    this.detailGate,
    Set<ReviewType>? supportedReviews,
    Set<RepoCapability>? supportedCapabilities,
  }) : supportedReviews = supportedReviews ??
            {
              ReviewType.comment,
              ReviewType.approve,
              ReviewType.requestChanges,
              ReviewType.merge,
            },
       supportedCapabilities = supportedCapabilities ??
            {
              RepoCapability.issues,
              RepoCapability.branches,
              RepoCapability.commits,
              RepoCapability.contributors,
              RepoCapability.star,
            };

  @override
  final ForgePlatform platform;
  final PlatformAccount? profile;
  final List<ChangeRequest> inbox;
  // Returned for listInbox page > 1. Empty means last page.
  final List<ChangeRequest> inboxMore;
  final List<NotificationItem> notifications;
  final List<Repo> repos;
  final ChangeRequest? detail;
  final List<ChangedFile> files;
  final List<ReviewComment> comments;
  final List<ChangeRequest> repoPulls;
  final String? readme;
  final AdapterException? verifyError;
  AdapterException? detailError;
  Completer<void>? detailGate;
  int getChangeRequestCount = 0;
  final List<ReviewAction> submitted = [];

  @override
  final Set<ReviewType> supportedReviews;

  @override
  final Set<RepoCapability> supportedCapabilities;

  @override
  Future<PlatformAccount> verifyAndProfile({
    required String token,
    String? displayName,
    String? baseUrl,
    String? orgId,
  }) async {
    if (verifyError != null) throw verifyError!;
    return profile ??
        PlatformAccount(
          id: 'acct-${platform.name}',
          platform: platform,
          displayName: displayName ?? platform.name,
          login: platform.name,
          createdAt: DateTime.utc(2026, 1, 1),
        );
  }

  @override
  Future<List<ChangeRequest>> listInbox({
    required PlatformAccount account,
    required String token,
    int page = 1,
  }) async =>
      page <= 1 ? inbox : inboxMore;

  @override
  Future<List<NotificationItem>> listNotifications({
    required PlatformAccount account,
    required String token,
  }) async =>
      notifications;

  @override
  Future<List<Repo>> listRepos({required PlatformAccount account, required String token}) async => repos;

  @override
  Future<List<ChangeRequest>> listOpenChangeRequests({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async {
    if (repoPulls.isNotEmpty) return repoPulls;
    return inbox.where((e) => e.repoFullName == repo.fullName).toList();
  }

  @override
  Future<String?> getReadme({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async =>
      readme;

  @override
  Future<ChangeRequest> getChangeRequest({
    required PlatformAccount account,
    required String token,
    required ChangeRequest summary,
  }) async {
    getChangeRequestCount++;
    final gate = detailGate;
    if (gate != null) await gate.future;
    if (detailError != null) throw detailError!;
    return detail ??
        summary.copyWith(
          body: summary.body ?? 'Please review this change.',
          sourceBranch: summary.sourceBranch.isEmpty ? 'feat' : summary.sourceBranch,
          targetBranch: summary.targetBranch.isEmpty ? 'main' : summary.targetBranch,
        );
  }

  @override
  Future<List<ChangedFile>> listFiles({
    required PlatformAccount account,
    required String token,
    required ChangeRequest cr,
  }) async =>
      files;

  @override
  Future<List<ReviewComment>> listComments({
    required PlatformAccount account,
    required String token,
    required ChangeRequest cr,
  }) async =>
      comments;

  @override
  Future<void> submitReview({
    required PlatformAccount account,
    required String token,
    required ChangeRequest cr,
    required ReviewAction action,
  }) async {
    submitted.add(action);
  }

  // ---- B-batch 仓库级特性 stub -------------------------------------------
  // Widget tests don't exercise these yet (commit 1 保持 compile-through).
  // Default to empty; individual tests can override per scenario.

  @override
  Future<List<Issue>> listIssues({
    required PlatformAccount account,
    required String token,
    required Repo repo,
    IssueState state = IssueState.open,
  }) async =>
      const [];

  @override
  Future<Issue> getIssue({
    required PlatformAccount account,
    required String token,
    required Issue summary,
  }) async =>
      summary;

  @override
  Future<List<IssueComment>> listIssueComments({
    required PlatformAccount account,
    required String token,
    required Issue issue,
  }) async =>
      const [];

  @override
  Future<List<Branch>> listBranches({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async =>
      const [];

  @override
  Future<List<GitCommit>> listCommits({
    required PlatformAccount account,
    required String token,
    required Repo repo,
    String? sha,
  }) async =>
      const [];

  @override
  Future<List<Contributor>> listContributors({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async =>
      const [];

  @override
  Future<void> starRepo({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async {}

  @override
  Future<void> unstarRepo({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async {}
}
