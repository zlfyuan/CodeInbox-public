import 'models.dart';

enum AdapterErrorKind { unauthorized, rateLimited, unsupported, network, http }

class AdapterException implements Exception {
  AdapterException(this.kind, {this.message, this.resetAt, this.statusCode});

  final AdapterErrorKind kind;
  final String? message;
  final DateTime? resetAt;
  final int? statusCode;

  factory AdapterException.unauthorized() =>
      AdapterException(AdapterErrorKind.unauthorized, message: 'Token rejected');

  factory AdapterException.rateLimited({DateTime? resetAt}) => AdapterException(
        AdapterErrorKind.rateLimited,
        message: 'Rate limited',
        resetAt: resetAt,
      );

  factory AdapterException.unsupported(String what) =>
      AdapterException(AdapterErrorKind.unsupported, message: what);

  factory AdapterException.network(String message) =>
      AdapterException(AdapterErrorKind.network, message: message);

  factory AdapterException.http(int status, String snippet) => AdapterException(
        AdapterErrorKind.http,
        statusCode: status,
        message: 'HTTP $status${snippet.isEmpty ? '' : ': $snippet'}',
      );

  @override
  String toString() => message ?? kind.name;
}

abstract class ForgeAdapter {
  ForgePlatform get platform;

  Future<PlatformAccount> verifyAndProfile({
    required String token,
    String? displayName,
    String? baseUrl,
    String? orgId,
  });

  Future<List<ChangeRequest>> listInbox({
    required PlatformAccount account,
    required String token,
    int page = 1,
  });

  Future<List<NotificationItem>> listNotifications({
    required PlatformAccount account,
    required String token,
  });

  Future<List<Repo>> listRepos({
    required PlatformAccount account,
    required String token,
  });

  Future<List<ChangeRequest>> listOpenChangeRequests({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  });

  /// README markdown, or null when the repo has none.
  Future<String?> getReadme({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  });

  Set<ReviewType> get supportedReviews;

  /// 仓库级特性能力声明。缺失项 UI 应主动隐藏对应 Tab/按钮。
  Set<RepoCapability> get supportedCapabilities;

  Future<ChangeRequest> getChangeRequest({
    required PlatformAccount account,
    required String token,
    required ChangeRequest summary,
  });

  Future<List<ChangedFile>> listFiles({
    required PlatformAccount account,
    required String token,
    required ChangeRequest cr,
  });

  Future<List<ReviewComment>> listComments({
    required PlatformAccount account,
    required String token,
    required ChangeRequest cr,
  });

  Future<void> submitReview({
    required PlatformAccount account,
    required String token,
    required ChangeRequest cr,
    required ReviewAction action,
  });

  // ---- 仓库级特性 (Issues / 代码 / 贡献者 / Star) -----------------------
  // 6 平台必须全部声明 abstract；不支持的平台 throw AdapterException.unsupported。
  // UI 端通过 supportedCapabilities 判断是否渲染对应 Tab/按钮,不要 catch。

  Future<List<Issue>> listIssues({
    required PlatformAccount account,
    required String token,
    required Repo repo,
    IssueState state = IssueState.open,
  });

  Future<Issue> getIssue({
    required PlatformAccount account,
    required String token,
    required Issue summary,
  });

  Future<List<IssueComment>> listIssueComments({
    required PlatformAccount account,
    required String token,
    required Issue issue,
  });

  Future<List<Branch>> listBranches({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  });

  Future<List<GitCommit>> listCommits({
    required PlatformAccount account,
    required String token,
    required Repo repo,
    String? sha,
  });

  Future<List<Contributor>> listContributors({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  });

  Future<void> starRepo({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  });

  Future<void> unstarRepo({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  });
}
