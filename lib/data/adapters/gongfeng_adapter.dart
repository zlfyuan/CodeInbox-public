import 'package:uuid/uuid.dart';

import '../../domain/forge_adapter.dart';
import '../../domain/inbox.dart';
import '../../domain/models.dart';
import '../../domain/refs.dart';
import '../http_client.dart';
import '../patch_codec.dart';
import '../readme_codec.dart';

const gongfengInboxRepoLimit = 20;

String gongfengTokenSettingsUrl(String? baseUrl) {
  final base = normalizeForgeBaseUrl(baseUrl) ?? kGongfengDotCom;
  return '$base/profile/account';
}

Uri gongfengApiUri(String? baseUrl, String path, [Map<String, String>? query]) {
  final base = Uri.parse(normalizeForgeBaseUrl(baseUrl) ?? kGongfengDotCom);
  var prefix = base.path;
  if (prefix == '/' || prefix.isEmpty) {
    prefix = '';
  } else if (prefix.endsWith('/')) {
    prefix = prefix.substring(0, prefix.length - 1);
  }
  return base.replace(path: '$prefix/api/v3$path', queryParameters: query);
}

String gongfengProjectPath(String repoFullName) => Uri.encodeComponent(repoFullName);

class GongfengAdapter implements ForgeAdapter {
  GongfengAdapter({ForgeHttp? http, Uuid? uuid})
      : _http = http ?? ForgeHttp(),
        _uuid = uuid ?? const Uuid();

  final ForgeHttp _http;
  final Uuid _uuid;

  @override
  ForgePlatform get platform => ForgePlatform.gongfeng;

  @override
  Set<ReviewType> get supportedReviews => const {
        ReviewType.comment,
        ReviewType.approve,
        ReviewType.requestChanges,
        ReviewType.merge,
      };

  @override
  Set<RepoCapability> get supportedCapabilities => const {
        // Gongfeng is GitLab v3 compatible but the B-batch scope only covers
        // merge requests. Issues / branches / commits / contributors / star
        // are not yet validated against the Tencent GitLab v3 surface.
      };

  Map<String, String> _headers(String token) => {'PRIVATE-TOKEN': token};

  Future<dynamic> _get(String? baseUrl, String path, String token, [Map<String, String>? query]) {
    return _http.getJson(gongfengApiUri(baseUrl, path, query), token: token, headers: _headers(token));
  }

  Future<dynamic> _post(String? baseUrl, String path, String token, {Object? body}) {
    return _http.postJson(gongfengApiUri(baseUrl, path), token: token, headers: _headers(token), body: body);
  }

  Future<dynamic> _put(String? baseUrl, String path, String token, {Object? body}) {
    return _http.putJson(gongfengApiUri(baseUrl, path), token: token, headers: _headers(token), body: body);
  }

  String _webHost(PlatformAccount account) => normalizeForgeBaseUrl(account.baseUrl) ?? kGongfengDotCom;

  @override
  Future<PlatformAccount> verifyAndProfile({
    required String token,
    String? displayName,
    String? baseUrl,
    String? orgId,
  }) async {
    final normalized = normalizeForgeBaseUrl(baseUrl) ?? kGongfengDotCom;
    final json = await _get(normalized, '/user', token) as Map<String, dynamic>;
    final login = json['username'] as String? ?? json['login'] as String? ?? '';
    final name = json['name'] as String?;
    return PlatformAccount(
      id: _uuid.v4(),
      platform: ForgePlatform.gongfeng,
      login: login,
      displayName: (displayName != null && displayName.trim().isNotEmpty)
          ? displayName.trim()
          : (name?.trim().isNotEmpty == true ? name!.trim() : login),
      avatarUrl: json['avatar_url'] as String?,
      baseUrl: normalized,
      createdAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<List<ChangeRequest>> listInbox({
    required PlatformAccount account,
    required String token,
    int page = 1,
  }) async {
    final user = await _get(account.baseUrl, '/user', token) as Map<String, dynamic>;
    final userId = _asInt(user['id']);
    final repos = await listRepos(account: account, token: token);
    final limited = repos.take(gongfengInboxRepoLimit).toList();
    final chunks = await Future.wait(limited.map((repo) async {
      try {
        final json = await _get(
          account.baseUrl,
          '/projects/${gongfengProjectPath(repo.fullName)}/merge_requests',
          token,
          {'state': 'opened', 'per_page': '20', 'page': '$page'},
        );
        return parseGongfengMrs(
          jsonAsList(json),
          accountId: account.id,
          repoFullName: repo.fullName,
          webBase: _webHost(account),
          currentUserId: userId,
        );
      } on AdapterException {
        return <ChangeRequest>[];
      }
    }));
    final all = [for (final chunk in chunks) ...chunk];
    final mine = all.where((e) => e.assignedToMe || e.reviewRequested).toList();
    return mergeInbox(mine.isNotEmpty ? mine : all);
  }

  @override
  Future<List<NotificationItem>> listNotifications({
    required PlatformAccount account,
    required String token,
  }) async {
    final repos = await listRepos(account: account, token: token);
    final limited = repos.take(gongfengInboxRepoLimit).toList();
    final chunks = await Future.wait(limited.map((repo) async {
      try {
        final json = await _get(
          account.baseUrl,
          '/projects/${gongfengProjectPath(repo.fullName)}/events',
          token,
          {'per_page': '20'},
        );
        return jsonAsList(json)
            .whereType<Map<String, dynamic>>()
            .map((e) => parseGongfengEvent(e, account.id, repo))
            .whereType<NotificationItem>()
            .toList();
      } on AdapterException {
        return <NotificationItem>[];
      }
    }));
    return [for (final chunk in chunks) ...chunk];
  }

  @override
  Future<List<Repo>> listRepos({
    required PlatformAccount account,
    required String token,
  }) async {
    final json = await _get(account.baseUrl, '/projects', token, {
      'order_by': 'last_activity_at',
      'sort': 'desc',
      'per_page': '$gongfengInboxRepoLimit',
      'archived': 'false',
    });
    return jsonAsList(json)
        .take(gongfengInboxRepoLimit)
        .map((e) => parseGongfengProject(e as Map<String, dynamic>, account.id))
        .toList();
  }

  @override
  Future<List<ChangeRequest>> listOpenChangeRequests({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async {
    final json = await _get(
      account.baseUrl,
      '/projects/${gongfengProjectPath(repo.fullName)}/merge_requests',
      token,
      {'state': 'opened', 'per_page': '50'},
    );
    return parseGongfengMrs(
      jsonAsList(json),
      accountId: account.id,
      repoFullName: repo.fullName,
      webBase: _webHost(account),
    );
  }

  @override
  Future<String?> getReadme({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) {
    final project = gongfengProjectPath(repo.fullName);
    return firstReadme((name) {
      return _get(account.baseUrl, '/projects/$project/repository/files', token, {
        'file_path': name,
        'ref': repo.defaultBranch,
      });
    });
  }

  @override
  Future<ChangeRequest> getChangeRequest({
    required PlatformAccount account,
    required String token,
    required ChangeRequest summary,
  }) async {
    final globalId = await _globalMrId(account, token, summary);
    final json = await _get(
      account.baseUrl,
      '/projects/${gongfengProjectPath(summary.repoFullName)}/merge_request/$globalId',
      token,
    ) as Map<String, dynamic>;
    return parseGongfengMr(
      json,
      accountId: account.id,
      repoFullName: summary.repoFullName,
      webBase: _webHost(account),
      reviewRequested: summary.reviewRequested,
      assignedToMe: summary.assignedToMe,
      summary: summary,
    );
  }

  @override
  Future<List<ChangedFile>> listFiles({
    required PlatformAccount account,
    required String token,
    required ChangeRequest cr,
  }) async {
    try {
      final globalId = await _globalMrId(account, token, cr);
      final json = await _get(
        account.baseUrl,
        '/projects/${gongfengProjectPath(cr.repoFullName)}/merge_request/$globalId/changes',
        token,
      );
      if (json is! Map<String, dynamic>) return const [];
      final files = json['files'] ?? json['changes'];
      if (files is! List) return const [];
      final parsed = files.whereType<Map<String, dynamic>>().map(parseGongfengDiff).toList();
      if (cr.webUrl.isEmpty) return parsed;
      return recoverPatches(
        files: parsed,
        fetchDiff: () => _http.getText(Uri.parse('${cr.webUrl}.diff'), token: token, headers: _headers(token)),
      );
    } on AdapterException {
      return const [];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<List<ReviewComment>> listComments({
    required PlatformAccount account,
    required String token,
    required ChangeRequest cr,
  }) async {
    try {
      final globalId = await _globalMrId(account, token, cr);
      final json = await _get(
        account.baseUrl,
        '/projects/${gongfengProjectPath(cr.repoFullName)}/merge_request/$globalId/comments',
        token,
        {'per_page': '50'},
      );
      final comments = jsonAsList(json)
          .whereType<Map<String, dynamic>>()
          .where((e) => e['system'] != true)
          .map(parseGongfengComment)
          .toList();
      comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return comments;
    } on AdapterException {
      return const [];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> submitReview({
    required PlatformAccount account,
    required String token,
    required ChangeRequest cr,
    required ReviewAction action,
  }) async {
    final globalId = await _globalMrId(account, token, cr);
    final base = account.baseUrl;
    final root = '/projects/${gongfengProjectPath(cr.repoFullName)}/merge_request/$globalId';
    switch (action.type) {
      case ReviewType.merge:
        await _put(base, '$root/merge', token, body: {
          'merge_commit_message':
              (action.body?.trim().isNotEmpty == true) ? action.body!.trim() : 'Merged via CodeInbox',
        });
      case ReviewType.approve:
        await _put(base, '$root/reviewer/summary', token, body: {
          'reviewer_event': 'approved',
          if (action.body?.trim().isNotEmpty == true) 'summary': action.body!.trim(),
        });
      case ReviewType.requestChanges:
        final text = action.body?.trim() ?? '';
        if (text.isEmpty) {
          throw AdapterException.http(422, 'Comment body is required');
        }
        await _put(base, '$root/reviewer/summary', token, body: {
          'reviewer_event': 'change_required',
          'summary': text,
        });
      case ReviewType.comment:
        final text = action.body?.trim() ?? '';
        if (text.isEmpty) {
          throw AdapterException.http(422, 'Comment body is required');
        }
        final body = action.isInline ? '`${action.path}:${action.line ?? ''}`\n\n$text' : text;
        await _post(base, '$root/comments', token, body: {
          'body': body,
          if (action.isInline) 'path': action.path,
          if (action.line != null) 'line': action.line,
        });
    }
  }

  /// v3 paths use the global MR id; inbox items store it in `ChangeRequest.id`.
  Future<int> _globalMrId(PlatformAccount account, String token, ChangeRequest cr) async {
    final parts = cr.id.split(':');
    if (parts.length == 3 && parts[0] == 'gongfeng') {
      final parsed = int.tryParse(parts[2]);
      if (parsed != null && parsed > 0) return parsed;
    }
    final json = await _get(
      account.baseUrl,
      '/projects/${gongfengProjectPath(cr.repoFullName)}/merge_requests',
      token,
      {'iid': '${cr.localNumber}', 'per_page': '1'},
    );
    final first = jsonAsList(json).whereType<Map<String, dynamic>>().firstOrNull;
    final id = _asInt(first?['id']);
    if (id <= 0) {
      throw AdapterException.http(404, 'Merge request !${cr.localNumber} not found');
    }
    return id;
  }

  // ---- 仓库级特性 stub (commit 1) ----------------------------------------

  @override
  Future<List<Issue>> listIssues({
    required PlatformAccount account,
    required String token,
    required Repo repo,
    IssueState state = IssueState.open,
  }) async =>
      throw _unsupported('issues');

  @override
  Future<Issue> getIssue({
    required PlatformAccount account,
    required String token,
    required Issue summary,
  }) async =>
      throw _unsupported('issues');

  @override
  Future<List<IssueComment>> listIssueComments({
    required PlatformAccount account,
    required String token,
    required Issue issue,
  }) async =>
      throw _unsupported('issues');

  @override
  Future<List<Branch>> listBranches({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async =>
      throw _unsupported('branches');

  @override
  Future<List<GitCommit>> listCommits({
    required PlatformAccount account,
    required String token,
    required Repo repo,
    String? sha,
  }) async =>
      throw _unsupported('commits');

  @override
  Future<List<Contributor>> listContributors({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async =>
      throw _unsupported('contributors');

  @override
  Future<void> starRepo({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async =>
      throw _unsupported('star');

  @override
  Future<void> unstarRepo({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async =>
      throw _unsupported('star');

  Never _unsupported(String what) =>
      throw AdapterException.unsupported('Gongfeng adapter does not implement $what yet');
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

int? _userId(dynamic raw) {
  if (raw is Map<String, dynamic>) return _asInt(raw['id']);
  if (raw is List) {
    for (final item in raw) {
      final id = _userId(item);
      if (id != null && id > 0) return id;
    }
  }
  return null;
}

List<int> _userIds(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    final id = _asInt(raw['id']);
    return id > 0 ? [id] : const [];
  }
  if (raw is List) {
    return [for (final item in raw) ..._userIds(item)];
  }
  return const [];
}

NotificationItem? parseGongfengEvent(Map<String, dynamic> json, String accountId, Repo repo) {
  final type = json['target_type'] as String? ?? '';
  if (type != 'MergeRequest') return null;
  final title = json['target_title'] as String? ?? json['title'] as String? ?? 'Merge request';
  final iid = _asInt(json['target_iid'] ?? json['target_id']);
  final created = DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now().toUtc();
  final web = iid > 0 ? '${repo.webUrl}/merge_requests/$iid' : repo.webUrl;
  return NotificationItem(
    id: 'gongfeng:$accountId:event:${json['id'] ?? '${repo.id}:$iid'}',
    platform: ForgePlatform.gongfeng,
    accountId: accountId,
    title: title,
    reason: json['action_name'] as String?,
    unread: true,
    webUrl: web,
    updatedAt: created.toUtc(),
    relatedType: RelatedType.changeRequest,
    repoFullName: repo.fullName,
    localNumber: iid > 0 ? iid : null,
  );
}

List<ChangeRequest> parseGongfengMrs(
  List<dynamic> items, {
  required String accountId,
  required String repoFullName,
  required String webBase,
  int? currentUserId,
}) {
  return items
      .map((e) => parseGongfengMr(
            e as Map<String, dynamic>,
            accountId: accountId,
            repoFullName: repoFullName,
            webBase: webBase,
            currentUserId: currentUserId,
          ))
      .toList();
}

ChangeRequest parseGongfengMr(
  Map<String, dynamic> json, {
  required String accountId,
  required String repoFullName,
  required String webBase,
  int? currentUserId,
  bool reviewRequested = false,
  bool assignedToMe = false,
  ChangeRequest? summary,
}) {
  final iid = _asInt(json['iid']);
  final globalId = _asInt(json['id']);
  final number = iid > 0 ? iid : (summary?.localNumber ?? globalId);
  final stateStr = json['state'] as String? ?? 'opened';
  final state = switch (stateStr) {
    'merged' => CrState.merged,
    'closed' => CrState.closed,
    _ => CrState.open,
  };
  final created = DateTime.tryParse(json['created_at'] as String? ?? '') ?? summary?.createdAt ?? DateTime.now().toUtc();
  final updated = DateTime.tryParse(json['updated_at'] as String? ?? '') ?? created;
  final mergeStatus = json['merge_status'] as String?;
  final mergeable = mergeStatus == 'can_be_merged';
  final assigneeId = _userId(json['assignee']);
  final reviewerIds = [
    ..._userIds(json['reviewers']),
    ..._userIds(json['necessary_reviewers']),
  ];
  final assigned = currentUserId != null && currentUserId > 0 && assigneeId == currentUserId;
  final reviewing = currentUserId != null && currentUserId > 0 && reviewerIds.contains(currentUserId);
  final host = webBase.endsWith('/') ? webBase.substring(0, webBase.length - 1) : webBase;
  final fallbackUrl = repoFullName.isEmpty ? '' : '$host/$repoFullName/merge_requests/$number';
  return ChangeRequest(
    // 3-part id stores the v3 global MR id used by /merge_request/:id paths.
    id: 'gongfeng:$accountId:$globalId',
    localNumber: number,
    platform: ForgePlatform.gongfeng,
    accountId: accountId,
    repoFullName: repoFullName.isNotEmpty ? repoFullName : (summary?.repoFullName ?? ''),
    title: json['title'] as String? ?? summary?.title ?? '',
    body: json['description'] as String? ?? summary?.body,
    state: state,
    sourceBranch: json['source_branch'] as String? ?? summary?.sourceBranch ?? '',
    targetBranch: json['target_branch'] as String? ?? summary?.targetBranch ?? '',
    authorLogin: (json['author'] as Map<String, dynamic>?)?['username'] as String? ?? summary?.authorLogin ?? '',
    draft: json['work_in_progress'] as bool? ?? summary?.draft ?? false,
    webUrl: json['web_url'] as String? ?? summary?.webUrl ?? fallbackUrl,
    updatedAt: updated.toUtc(),
    createdAt: created.toUtc(),
    reviewRequested: reviewing || reviewRequested,
    assignedToMe: assigned || assignedToMe,
    mergeable: mergeStatus == null ? summary?.mergeable : mergeable,
  );
}

ChangedFile parseGongfengDiff(Map<String, dynamic> json) {
  final path = json['new_path'] as String? ?? json['old_path'] as String? ?? '';
  final raw = json['diff'] as String?;
  final clipped = clipPatch(raw);
  final deleted = json['deleted_file'] == true;
  final added = json['new_file'] == true;
  return ChangedFile(
    path: path,
    status: added
        ? 'added'
        : deleted
            ? 'removed'
            : 'modified',
    additions: _asInt(json['additions']),
    deletions: _asInt(json['deletions']),
    patch: clipped.$1,
    truncated: clipped.$2 || raw == null || json['is_too_large'] == true,
  );
}

ReviewComment parseGongfengComment(Map<String, dynamic> json) {
  final created = DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now().toUtc();
  return ReviewComment(
    id: '${json['id']}',
    authorLogin: (json['author'] as Map<String, dynamic>?)?['username'] as String? ?? '',
    body: json['body'] as String? ?? '',
    createdAt: created.toUtc(),
  );
}

Repo parseGongfengProject(Map<String, dynamic> json, String accountId) {
  final updated = DateTime.tryParse(json['last_activity_at'] as String? ?? json['created_at'] as String? ?? '') ??
      DateTime.now().toUtc();
  final vis = parseRepoVisibility(
    privateFlag: !(json['public'] == true || json['visibility_level'] == 20),
    level: json['visibility_level'] == null ? null : jsonInt(json['visibility_level']),
  );
  final created = DateTime.tryParse(json['created_at'] as String? ?? '');
  return Repo(
    id: 'gongfeng:$accountId:${json['id']}',
    platform: ForgePlatform.gongfeng,
    accountId: accountId,
    fullName: json['path_with_namespace'] as String? ?? '',
    webUrl: json['web_url'] as String? ?? '',
    private: vis != RepoVisibility.public,
    defaultBranch: json['default_branch'] as String? ?? 'master',
    updatedAt: updated.toUtc(),
    description: blankToNull(json['description'] as String?),
    language: null,
    starCount: _asInt(json['stars_count']),
    forkCount: _asInt(json['forks_count']),
    openIssueCount: _asInt(json['open_issues_count']),
    cloneUrl: blankToNull(json['http_url_to_repo'] as String?),
    sshUrl: blankToNull(json['ssh_url_to_repo'] as String?),
    watchersCount: _asInt(json['stars_count']),
    createdAt: created?.toUtc(),
    archived: json['archived'] == true,
    fork: json['forked_from_project'] != null,
    visibility: vis,
  );
}
