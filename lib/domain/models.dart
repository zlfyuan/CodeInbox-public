import '../l10n/gen/app_localizations.dart';

enum ForgePlatform { github, gitee, gitlab, codeup, gongfeng, coding }

enum AuthType { pat }

enum CrState { open, merged, closed }

/// Issue 状态。GitHub 实际还有 'reopened' 之类的，但接口只取 open/closed 两态。
enum IssueState { open, closed }

/// 仓库级特性能力声明。ForgeAdapter.supportedCapabilities 决定 UI 显隐。
enum RepoCapability { issues, branches, commits, contributors, star }

class PlatformAccount {
  const PlatformAccount({
    required this.id,
    required this.platform,
    required this.displayName,
    required this.login,
    this.avatarUrl,
    this.baseUrl,
    this.orgId,
    this.authType = AuthType.pat,
    required this.createdAt,
  });

  final String id;
  final ForgePlatform platform;
  final String displayName;
  final String login;
  final String? avatarUrl;
  final String? baseUrl;
  // Codeup 中心版必填；Region 版可空。
  final String? orgId;
  final AuthType authType;
  final DateTime createdAt;

  String get label => displayName.isEmpty ? login : displayName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'platform': platform.name,
        'displayName': displayName,
        'login': login,
        'avatarUrl': avatarUrl,
        'baseUrl': baseUrl,
        'orgId': orgId,
        'authType': authType.name,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory PlatformAccount.fromJson(Map<String, dynamic> json) => PlatformAccount(
        id: json['id'] as String,
        platform: ForgePlatform.values.byName(json['platform'] as String),
        displayName: json['displayName'] as String? ?? '',
        login: json['login'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        baseUrl: json['baseUrl'] as String?,
        orgId: json['orgId'] as String?,
        authType: AuthType.values.byName(json['authType'] as String? ?? 'pat'),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  bool sameIdentity(PlatformAccount other) =>
      platform == other.platform &&
      login == other.login &&
      (baseUrl ?? '') == (other.baseUrl ?? '') &&
      (orgId ?? '') == (other.orgId ?? '');

  PlatformAccount copyWith({String? displayName, String? avatarUrl, String? baseUrl, String? orgId}) => PlatformAccount(
        id: id,
        platform: platform,
        displayName: displayName ?? this.displayName,
        login: login,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        baseUrl: baseUrl ?? this.baseUrl,
        orgId: orgId ?? this.orgId,
        authType: authType,
        createdAt: createdAt,
      );
}

class ChangeRequest {
  const ChangeRequest({
    required this.id,
    required this.localNumber,
    required this.platform,
    required this.accountId,
    required this.repoFullName,
    required this.title,
    this.body,
    this.state = CrState.open,
    this.sourceBranch = '',
    this.targetBranch = '',
    required this.authorLogin,
    this.draft = false,
    required this.webUrl,
    required this.updatedAt,
    required this.createdAt,
    this.reviewRequested = false,
    this.assignedToMe = false,
    this.ciStatus,
    this.mergeable,
    this.headSha,
    this.startSha,
    this.baseSha,
  });

  final String id;
  final int localNumber;
  final ForgePlatform platform;
  final String accountId;
  final String repoFullName;
  final String title;
  final String? body;
  final CrState state;
  final String sourceBranch;
  final String targetBranch;
  final String authorLogin;
  final bool draft;
  final String webUrl;
  final DateTime updatedAt;
  final DateTime createdAt;
  final bool reviewRequested;
  final bool assignedToMe;
  final String? ciStatus;
  final bool? mergeable;
  // SHAs for inline comments (GitHub commit_id / GitLab diff_refs).
  final String? headSha;
  final String? startSha;
  final String? baseSha;

  String get owner {
    final i = repoFullName.indexOf('/');
    return i <= 0 ? repoFullName : repoFullName.substring(0, i);
  }

  String get repoName {
    final i = repoFullName.indexOf('/');
    return i <= 0 ? '' : repoFullName.substring(i + 1);
  }

  static String makeId({
    required ForgePlatform platform,
    required String accountId,
    required String repoFullName,
    required int localNumber,
  }) =>
      '${platform.name}:$accountId:$repoFullName:$localNumber';

  ChangeRequest copyWith({
    String? title,
    String? body,
    CrState? state,
    String? sourceBranch,
    String? targetBranch,
    String? authorLogin,
    bool? draft,
    String? webUrl,
    DateTime? updatedAt,
    bool? reviewRequested,
    bool? assignedToMe,
    String? ciStatus,
    bool? mergeable,
    String? headSha,
    String? startSha,
    String? baseSha,
  }) =>
      ChangeRequest(
        id: id,
        localNumber: localNumber,
        platform: platform,
        accountId: accountId,
        repoFullName: repoFullName,
        title: title ?? this.title,
        body: body ?? this.body,
        state: state ?? this.state,
        sourceBranch: sourceBranch ?? this.sourceBranch,
        targetBranch: targetBranch ?? this.targetBranch,
        authorLogin: authorLogin ?? this.authorLogin,
        draft: draft ?? this.draft,
        webUrl: webUrl ?? this.webUrl,
        updatedAt: updatedAt ?? this.updatedAt,
        createdAt: createdAt,
        reviewRequested: reviewRequested ?? this.reviewRequested,
        assignedToMe: assignedToMe ?? this.assignedToMe,
        ciStatus: ciStatus ?? this.ciStatus,
        mergeable: mergeable ?? this.mergeable,
        headSha: headSha ?? this.headSha,
        startSha: startSha ?? this.startSha,
        baseSha: baseSha ?? this.baseSha,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'localNumber': localNumber,
        'platform': platform.name,
        'accountId': accountId,
        'repoFullName': repoFullName,
        'title': title,
        'body': body,
        'state': state.name,
        'sourceBranch': sourceBranch,
        'targetBranch': targetBranch,
        'authorLogin': authorLogin,
        'draft': draft,
        'webUrl': webUrl,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'reviewRequested': reviewRequested,
        'assignedToMe': assignedToMe,
        'ciStatus': ciStatus,
        'mergeable': mergeable,
        'headSha': headSha,
        'startSha': startSha,
        'baseSha': baseSha,
      };

  factory ChangeRequest.fromJson(Map<String, dynamic> json) => ChangeRequest(
        id: json['id'] as String,
        localNumber: json['localNumber'] as int,
        platform: ForgePlatform.values.byName(json['platform'] as String),
        accountId: json['accountId'] as String,
        repoFullName: json['repoFullName'] as String,
        title: json['title'] as String,
        body: json['body'] as String?,
        state: CrState.values.byName(json['state'] as String? ?? 'open'),
        sourceBranch: json['sourceBranch'] as String? ?? '',
        targetBranch: json['targetBranch'] as String? ?? '',
        authorLogin: json['authorLogin'] as String,
        draft: json['draft'] as bool? ?? false,
        webUrl: json['webUrl'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        reviewRequested: json['reviewRequested'] as bool? ?? false,
        assignedToMe: json['assignedToMe'] as bool? ?? false,
        ciStatus: json['ciStatus'] as String?,
        mergeable: json['mergeable'] as bool?,
        headSha: json['headSha'] as String?,
        startSha: json['startSha'] as String?,
        baseSha: json['baseSha'] as String?,
      );
}

enum ReviewType { comment, approve, requestChanges, merge }

class ReviewAction {
  const ReviewAction({required this.type, this.body, this.path, this.line});

  final ReviewType type;
  final String? body;
  final String? path;
  final int? line;

  bool get isInline => path != null && path!.isNotEmpty;
}

class ChangedFile {
  const ChangedFile({
    required this.path,
    this.status = 'modified',
    this.additions = 0,
    this.deletions = 0,
    this.patch,
    this.truncated = false,
  });

  final String path;
  final String status;
  final int additions;
  final int deletions;
  final String? patch;
  final bool truncated;

  bool get hasPatch => patch != null && patch!.isNotEmpty;
}

class ReviewComment {
  const ReviewComment({
    required this.id,
    required this.authorLogin,
    required this.body,
    this.path,
    this.line,
    required this.createdAt,
  });

  final String id;
  final String authorLogin;
  final String body;
  final String? path;
  final int? line;
  final DateTime createdAt;
}

class CrDetail {
  const CrDetail({
    required this.changeRequest,
    required this.files,
    required this.comments,
    required this.supportedReviews,
  });

  final ChangeRequest changeRequest;
  final List<ChangedFile> files;
  final List<ReviewComment> comments;
  final Set<ReviewType> supportedReviews;
}

enum RepoVisibility { public, internal, private }

class Repo {
  const Repo({
    required this.id,
    required this.platform,
    required this.accountId,
    required this.fullName,
    required this.webUrl,
    required this.private,
    required this.defaultBranch,
    required this.updatedAt,
    this.description,
    this.language,
    this.starCount = 0,
    this.forkCount = 0,
    this.openIssueCount = 0,
    this.cloneUrl,
    this.sshUrl,
    this.watchersCount = 0,
    this.subscribersCount,
    this.license,
    this.homepage,
    this.createdAt,
    this.archived = false,
    this.fork = false,
    this.topics = const [],
    this.visibility = RepoVisibility.private,
  });

  final String id;
  final ForgePlatform platform;
  final String accountId;
  final String fullName;
  final String webUrl;
  final bool private;
  final String defaultBranch;
  final DateTime updatedAt;
  // List-API fields only. No extra get-repo / README fetch.
  final String? description;
  final String? language;
  final int starCount;
  final int forkCount;
  final int openIssueCount;
  // HTTPS / SSH clone URLs come straight from each forge's repo list response.
  // Null when the platform didn't return them; UI hides the copy row.
  final String? cloneUrl;
  final String? sshUrl;
  // Parse-time fallback for platforms that don't separate watchers from stars.
  // Not surfaced in UI yet.
  final int watchersCount;
  // Only GitHub / Gitee return an independent subscribers count. Null means
  // "platform doesn't expose this" — UI uses that to hide the stat.
  final int? subscribersCount;
  final String? license;
  final String? homepage;
  final DateTime? createdAt;
  final bool archived;
  final bool fork;
  final List<String> topics;
  final RepoVisibility visibility;

  String get owner {
    final i = fullName.indexOf('/');
    return i <= 0 ? fullName : fullName.substring(0, i);
  }

  String get repoName {
    final i = fullName.indexOf('/');
    return i <= 0 ? fullName : fullName.substring(i + 1);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'platform': platform.name,
        'accountId': accountId,
        'fullName': fullName,
        'webUrl': webUrl,
        'private': private,
        'defaultBranch': defaultBranch,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'description': description,
        'language': language,
        'starCount': starCount,
        'forkCount': forkCount,
        'openIssueCount': openIssueCount,
        'cloneUrl': cloneUrl,
        'sshUrl': sshUrl,
        'watchersCount': watchersCount,
        'subscribersCount': subscribersCount,
        'license': license,
        'homepage': homepage,
        'createdAt': createdAt?.toUtc().toIso8601String(),
        'archived': archived,
        'fork': fork,
        'topics': topics,
        'visibility': visibility.name,
      };

  factory Repo.fromJson(Map<String, dynamic> json) => Repo(
        id: json['id'] as String,
        platform: ForgePlatform.values.byName(json['platform'] as String),
        accountId: json['accountId'] as String,
        fullName: json['fullName'] as String,
        webUrl: json['webUrl'] as String,
        private: json['private'] as bool? ?? false,
        defaultBranch: json['defaultBranch'] as String? ?? 'main',
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        description: json['description'] as String?,
        language: json['language'] as String?,
        starCount: json['starCount'] as int? ?? 0,
        forkCount: json['forkCount'] as int? ?? 0,
        openIssueCount: json['openIssueCount'] as int? ?? 0,
        cloneUrl: blankToNull(json['cloneUrl'] as String?),
        sshUrl: blankToNull(json['sshUrl'] as String?),
        watchersCount: json['watchersCount'] as int? ?? 0,
        subscribersCount: json['subscribersCount'] as int?,
        license: json['license'] as String?,
        homepage: json['homepage'] as String?,
        createdAt: json['createdAt'] == null ? null : DateTime.tryParse(json['createdAt'] as String),
        archived: json['archived'] as bool? ?? false,
        fork: json['fork'] as bool? ?? false,
        topics: (json['topics'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        visibility: RepoVisibility.values.asNameMap()[json['visibility'] as String?] ??
            ((json['private'] as bool? ?? false) ? RepoVisibility.private : RepoVisibility.public),
      );
}

/// Issue 列表/详情项。无 PR 的 draft/sourceBranch/targetBranch/SHAs。
class Issue {
  const Issue({
    required this.id,
    required this.localNumber,
    required this.platform,
    required this.accountId,
    required this.repoFullName,
    required this.title,
    required this.authorLogin,
    required this.webUrl,
    required this.updatedAt,
    required this.createdAt,
    required this.state,
    this.body,
    this.labels = const [],
    this.assignees = const [],
    this.commentCount = 0,
  });

  final String id;
  final int localNumber;
  final ForgePlatform platform;
  final String accountId;
  final String repoFullName;
  final String title;
  final String? body;
  final IssueState state;
  final String authorLogin;
  final String webUrl;
  final DateTime updatedAt;
  final DateTime createdAt;
  final List<String> labels;
  final List<String> assignees;
  final int commentCount;

  String get owner {
    final i = repoFullName.indexOf('/');
    return i <= 0 ? repoFullName : repoFullName.substring(0, i);
  }

  String get repoName {
    final i = repoFullName.indexOf('/');
    return i <= 0 ? '' : repoFullName.substring(i + 1);
  }

  static String makeId({
    required ForgePlatform platform,
    required String accountId,
    required String repoFullName,
    required int localNumber,
  }) =>
      '${platform.name}:$accountId:$repoFullName:$localNumber';
}

/// Issue 顶部评论（与 PR review comment 不同：无 path/line）。
class IssueComment {
  const IssueComment({
    required this.id,
    required this.authorLogin,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String authorLogin;
  final String body;
  final DateTime createdAt;
}

class IssueDetail {
  const IssueDetail({required this.issue, required this.comments});

  final Issue issue;
  final List<IssueComment> comments;
}

/// Git 分支最小集。
class Branch {
  const Branch({required this.name, required this.commitSha, this.protected = false});

  final String name;
  final String commitSha;
  final bool protected;
}

/// 单次提交（仓库级 list_commits 响应）。
class GitCommit {
  const GitCommit({
    required this.sha,
    required this.messageFirstLine,
    required this.authorName,
    required this.authoredAt,
    required this.webUrl,
  });

  final String sha;
  final String messageFirstLine;
  final String authorName;
  final DateTime authoredAt;
  final String webUrl;

  String get shortSha => sha.length <= 7 ? sha : sha.substring(0, 7);
}

/// 仓库贡献者（带累计贡献数）。
class Contributor {
  const Contributor({
    required this.login,
    required this.contributionCount,
    this.avatarUrl,
    this.profileUrl = '',
  });

  final String login;
  final String? avatarUrl;
  final int contributionCount;
  final String profileUrl;
}

enum RelatedType { changeRequest, issue, other }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.platform,
    required this.accountId,
    required this.title,
    this.reason,
    required this.unread,
    required this.webUrl,
    required this.updatedAt,
    this.relatedType = RelatedType.other,
    this.repoFullName,
    this.localNumber,
  });

  final String id;
  final ForgePlatform platform;
  final String accountId;
  final String title;
  final String? reason;
  final bool unread;
  final String webUrl;
  final DateTime updatedAt;
  final RelatedType relatedType;
  final String? repoFullName;
  final int? localNumber;

  bool get opensDetail =>
      repoFullName != null && repoFullName!.isNotEmpty && localNumber != null && localNumber! > 0;

  factory NotificationItem.fromChangeRequest(ChangeRequest cr) => NotificationItem(
        id: 'inbox:${cr.id}',
        platform: cr.platform,
        accountId: cr.accountId,
        title: cr.title,
        reason: cr.reviewRequested ? 'review_requested' : 'assigned',
        unread: true,
        webUrl: cr.webUrl,
        updatedAt: cr.updatedAt,
        relatedType: RelatedType.changeRequest,
        repoFullName: cr.repoFullName,
        localNumber: cr.localNumber,
      );

  ChangeRequest? toChangeRequest() {
    if (!opensDetail) return null;
    return ChangeRequest(
      id: ChangeRequest.makeId(
        platform: platform,
        accountId: accountId,
        repoFullName: repoFullName!,
        localNumber: localNumber!,
      ),
      localNumber: localNumber!,
      platform: platform,
      accountId: accountId,
      repoFullName: repoFullName!,
      title: title,
      authorLogin: '',
      webUrl: webUrl,
      updatedAt: updatedAt,
      createdAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'platform': platform.name,
        'accountId': accountId,
        'title': title,
        'reason': reason,
        'unread': unread,
        'webUrl': webUrl,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'relatedType': relatedType.name,
        'repoFullName': repoFullName,
        'localNumber': localNumber,
      };

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id'] as String,
        platform: ForgePlatform.values.byName(json['platform'] as String),
        accountId: json['accountId'] as String,
        title: json['title'] as String,
        reason: json['reason'] as String?,
        unread: json['unread'] as bool? ?? true,
        webUrl: json['webUrl'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        relatedType: RelatedType.values.asNameMap()[json['relatedType'] as String?] ?? RelatedType.other,
        repoFullName: json['repoFullName'] as String?,
        localNumber: json['localNumber'] as int?,
      );
}

class InboxFilter {
  const InboxFilter({this.platform, this.onlyReviewRequested = false});

  final ForgePlatform? platform;
  final bool onlyReviewRequested;

  InboxFilter copyWith({ForgePlatform? platform, bool? onlyReviewRequested, bool clearPlatform = false}) =>
      InboxFilter(
        platform: clearPlatform ? null : (platform ?? this.platform),
        onlyReviewRequested: onlyReviewRequested ?? this.onlyReviewRequested,
      );
}

String platformLabel(AppLocalizations l10n, ForgePlatform platform) => switch (platform) {
      ForgePlatform.github => l10n.platformGithub,
      ForgePlatform.gitee => l10n.platformGitee,
      ForgePlatform.gitlab => l10n.platformGitlab,
      ForgePlatform.codeup => l10n.platformCodeup,
      ForgePlatform.gongfeng => l10n.platformGongfeng,
      ForgePlatform.coding => l10n.platformCoding,
    };

/// Context-free fallback used by search matching and store error templates.
/// 搜索匹配和 store 错误模板需要稳定英文,不能依赖 locale。
String platformLabelEn(ForgePlatform platform) => switch (platform) {
      ForgePlatform.github => 'GitHub',
      ForgePlatform.gitee => 'Gitee',
      ForgePlatform.gitlab => 'GitLab',
      ForgePlatform.codeup => 'Codeup',
      ForgePlatform.gongfeng => 'Gongfeng',
      ForgePlatform.coding => 'CODING',
    };

/// Locale-aware PR state chip label.
String crStateLabel(AppLocalizations l10n, CrState state) => switch (state) {
      CrState.open => l10n.crStateOpen,
      CrState.merged => l10n.crStateMerged,
      CrState.closed => l10n.crStateClosed,
    };

/// Locale-aware repo visibility chip label.
String repoVisibilityLabel(AppLocalizations l10n, RepoVisibility visibility) =>
    switch (visibility) {
      RepoVisibility.public => l10n.repoVisibilityPublic,
      RepoVisibility.internal => l10n.repoVisibilityInternal,
      RepoVisibility.private => l10n.repoVisibilityPrivate,
    };

const kGitlabDotCom = 'https://gitlab.com';
const kCodeupOpenApi = 'https://openapi-rdc.aliyuncs.com';
const kGongfengDotCom = 'https://git.code.tencent.com';
const kCodingHintHost = 'https://your-team.coding.net';

String? normalizeForgeBaseUrl(String? raw) {
  if (raw == null) return null;
  var s = raw.trim();
  if (s.isEmpty) return null;
  if (!s.contains('://')) s = 'https://$s';
  while (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

const kMaxPatchChars = 20000;

(String? patch, bool truncated) clipPatch(String? patch) {
  if (patch == null || patch.isEmpty) return (null, false);
  if (patch.length <= kMaxPatchChars) return (patch, false);
  return ('${patch.substring(0, kMaxPatchChars)}\n… truncated', true);
}

String? blankToNull(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  return s.isEmpty ? null : s;
}

int jsonInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// GitHub sends `{spdx_id, name}`; Gitee often a string.
String? parseLicense(dynamic raw) {
  if (raw is String) {
    final s = blankToNull(raw);
    if (s == null || s == 'NOASSERTION' || s == 'Other') return null;
    return s;
  }
  if (raw is Map) {
    return parseLicense(raw['spdx_id'] ?? raw['key'] ?? raw['name']);
  }
  return null;
}

List<String> parseTopics(dynamic raw) {
  if (raw is! List) return const [];
  final out = <String>[];
  for (final item in raw) {
    final s = blankToNull(item.toString());
    if (s == null) continue;
    out.add(s);
    if (out.length >= 12) break;
  }
  return out;
}

RepoVisibility parseRepoVisibility({String? raw, bool? privateFlag, int? level}) {
  final s = raw?.toLowerCase().trim();
  if (s == 'public' || s == 'internal' || s == 'private') {
    return RepoVisibility.values.byName(s!);
  }
  // GitLab v3: 0 private, 10 internal, 20 public.
  if (level != null) {
    if (level >= 20) return RepoVisibility.public;
    if (level >= 10) return RepoVisibility.internal;
    return RepoVisibility.private;
  }
  if (privateFlag == false) return RepoVisibility.public;
  return RepoVisibility.private;
}
