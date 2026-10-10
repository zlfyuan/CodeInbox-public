import 'package:uuid/uuid.dart';

import '../../domain/forge_adapter.dart';
import '../../domain/inbox.dart';
import '../../domain/models.dart';
import '../../domain/refs.dart';
import '../http_client.dart';
import '../patch_codec.dart';
import '../readme_codec.dart';

const gitlabDotComTokenUrl = '$kGitlabDotCom/-/user_settings/personal_access_tokens';

String gitlabTokenSettingsUrl(String? baseUrl) {
  final base = normalizeForgeBaseUrl(baseUrl) ?? kGitlabDotCom;
  return '$base/-/user_settings/personal_access_tokens';
}

Uri gitlabApiUri(String? baseUrl, String path, [Map<String, String>? query]) {
  final base = Uri.parse(normalizeForgeBaseUrl(baseUrl) ?? kGitlabDotCom);
  var prefix = base.path;
  if (prefix == '/' || prefix.isEmpty) {
    prefix = '';
  } else if (prefix.endsWith('/')) {
    prefix = prefix.substring(0, prefix.length - 1);
  }
  return base.replace(path: '$prefix/api/v4$path', queryParameters: query);
}

String gitlabProjectPath(String repoFullName) => Uri.encodeComponent(repoFullName);

class GitlabAdapter implements ForgeAdapter {
  GitlabAdapter({ForgeHttp? http, Uuid? uuid})
      : _http = http ?? ForgeHttp(),
        _uuid = uuid ?? const Uuid();

  final ForgeHttp _http;
  final Uuid _uuid;

  @override
  ForgePlatform get platform => ForgePlatform.gitlab;

  @override
  Set<ReviewType> get supportedReviews => const {
        ReviewType.comment,
        ReviewType.approve,
        ReviewType.merge,
      };

  @override
  Set<RepoCapability> get supportedCapabilities => const {
        // GitLab v4 API: issues, branches, commits, contributors, star.
        RepoCapability.issues,
        RepoCapability.branches,
        RepoCapability.commits,
        RepoCapability.contributors,
        RepoCapability.star,
      };

  Future<dynamic> _get(String? baseUrl, String path, String token, [Map<String, String>? query]) {
    return _http.getJson(gitlabApiUri(baseUrl, path, query), token: token);
  }

  String _mrApi(ChangeRequest cr, [String suffix = '']) =>
      '/projects/${gitlabProjectPath(cr.repoFullName)}/merge_requests/${cr.localNumber}$suffix';

  @override
  Future<PlatformAccount> verifyAndProfile({
    required String token,
    String? displayName,
    String? baseUrl,
    String? orgId,
  }) async {
    final normalized = normalizeForgeBaseUrl(baseUrl) ?? kGitlabDotCom;
    final json = await _get(normalized, '/user', token) as Map<String, dynamic>;
    final login = json['username'] as String? ?? json['login'] as String? ?? '';
    final name = json['name'] as String?;
    return PlatformAccount(
      id: _uuid.v4(),
      platform: ForgePlatform.gitlab,
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
    final userId = '${user['id']}';
    final assignedRaw = await _get(account.baseUrl, '/merge_requests', token, {
      'state': 'opened',
      'scope': 'assigned_to_me',
      'per_page': '50',
      'page': '$page',
    });
    List<dynamic> reviewerRaw = const [];
    try {
      final raw = await _get(account.baseUrl, '/merge_requests', token, {
        'state': 'opened',
        'reviewer_id': userId,
        'per_page': '50',
        'page': '$page',
      });
      if (raw is List) reviewerRaw = raw;
    } on AdapterException {
      // Older GitLab without reviewer_id.
    }
    final assigned = assignedRaw is List ? assignedRaw : const <dynamic>[];
    return mergeInbox([
      ...parseGitlabMrs(assigned, accountId: account.id, reviewRequested: false, assignedToMe: true),
      ...parseGitlabMrs(reviewerRaw, accountId: account.id, reviewRequested: true, assignedToMe: false),
    ]);
  }

  @override
  Future<List<NotificationItem>> listNotifications({
    required PlatformAccount account,
    required String token,
  }) async {
    final json = await _get(account.baseUrl, '/todos', token, {
      'state': 'pending',
      'per_page': '50',
    });
    if (json is! List) return [];
    return json.map((e) => parseGitlabTodo(e as Map<String, dynamic>, account.id)).where((n) => n.webUrl.isNotEmpty).toList();
  }

  @override
  Future<List<Repo>> listRepos({
    required PlatformAccount account,
    required String token,
  }) async {
    final json = await _get(account.baseUrl, '/projects', token, {
      'membership': 'true',
      'order_by': 'updated_at',
      'per_page': '50',
    });
    if (json is! List) return [];
    return json.map((e) => parseGitlabProject(e as Map<String, dynamic>, account.id)).toList();
  }

  @override
  Future<List<ChangeRequest>> listOpenChangeRequests({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async {
    final json = await _get(
      account.baseUrl,
      '/projects/${gitlabProjectPath(repo.fullName)}/merge_requests',
      token,
      {'state': 'opened', 'per_page': '50'},
    );
    return parseGitlabMrs(jsonAsList(json), accountId: account.id, reviewRequested: false, assignedToMe: false);
  }

  @override
  Future<ChangeRequest> getChangeRequest({
    required PlatformAccount account,
    required String token,
    required ChangeRequest summary,
  }) async {
    final json = await _get(account.baseUrl, _mrApi(summary), token) as Map<String, dynamic>;
    return parseGitlabMr(json, accountId: account.id, reviewRequested: summary.reviewRequested, assignedToMe: summary.assignedToMe, summary: summary);
  }

  @override
  Future<String?> getReadme({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) {
    final project = gitlabProjectPath(repo.fullName);
    final ref = repo.defaultBranch;
    return firstReadme((name) {
      return _get(
        account.baseUrl,
        '/projects/$project/repository/files/${Uri.encodeComponent(name)}',
        token,
        {'ref': ref},
      );
    });
  }

  @override
  Future<List<ChangedFile>> listFiles({
    required PlatformAccount account,
    required String token,
    required ChangeRequest cr,
  }) async {
    final json = await _get(account.baseUrl, _mrApi(cr, '/diffs'), token, {'per_page': '100'});
    if (json is! List) return [];
    final files = json.map((e) => parseGitlabDiff(e as Map<String, dynamic>)).toList();
    // Collapsed / too-large diffs come back with an empty `diff` field.
    return recoverPatches(
      files: files,
      fetchDiff: () => _http.getText(gitlabApiUri(account.baseUrl, _mrApi(cr, '.diff')), token: token),
    );
  }

  @override
  Future<List<ReviewComment>> listComments({
    required PlatformAccount account,
    required String token,
    required ChangeRequest cr,
  }) async {
    final json = await _get(account.baseUrl, _mrApi(cr, '/notes'), token, {'per_page': '50'});
    if (json is! List) return [];
    final comments = json
        .whereType<Map<String, dynamic>>()
        .where((e) => e['system'] != true)
        .map(parseGitlabNote)
        .toList();
    comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return comments;
  }

  @override
  Future<void> submitReview({
    required PlatformAccount account,
    required String token,
    required ChangeRequest cr,
    required ReviewAction action,
  }) async {
    final base = account.baseUrl;
    switch (action.type) {
      case ReviewType.merge:
        await _http.putJson(gitlabApiUri(base, _mrApi(cr, '/merge')), token: token, body: const <String, dynamic>{});
      case ReviewType.approve:
        await _http.postJson(gitlabApiUri(base, _mrApi(cr, '/approve')), token: token, body: const <String, dynamic>{});
        final text = action.body?.trim();
        if (text != null && text.isNotEmpty) {
          await _http.postJson(gitlabApiUri(base, _mrApi(cr, '/notes')), token: token, body: {'body': text});
        }
      case ReviewType.comment:
        final text = action.body?.trim() ?? '';
        if (text.isEmpty) {
          throw AdapterException.http(422, 'Comment body is required');
        }
        if (action.isInline && cr.headSha != null && cr.startSha != null && cr.baseSha != null) {
          await _http.postJson(gitlabApiUri(base, _mrApi(cr, '/discussions')), token: token, body: {
            'body': text,
            'position': {
              'position_type': 'text',
              'base_sha': cr.baseSha,
              'start_sha': cr.startSha,
              'head_sha': cr.headSha,
              'new_path': action.path,
              'old_path': action.path,
              'new_line': action.line,
            },
          });
        } else {
          await _http.postJson(gitlabApiUri(base, _mrApi(cr, '/notes')), token: token, body: {
            'body': action.isInline ? '`${action.path}:${action.line ?? ''}`\n\n$text' : text,
          });
        }
      case ReviewType.requestChanges:
        throw AdapterException.unsupported('GitLab does not support request changes');
    }
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
  }) async {
    final path = '/projects/${gitlabProjectPath(repo.fullName)}/star';
    await _http.postJson(gitlabApiUri(account.baseUrl, path), token: token);
  }

  @override
  Future<void> unstarRepo({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async {
    final path = '/projects/${gitlabProjectPath(repo.fullName)}/star';
    await _http.deleteJson(gitlabApiUri(account.baseUrl, path), token: token);
  }

  Never _unsupported(String what) =>
      throw AdapterException.unsupported('GitLab adapter does not implement $what yet');
}

List<ChangeRequest> parseGitlabMrs(
  List<dynamic> items, {
  required String accountId,
  required bool reviewRequested,
  required bool assignedToMe,
}) {
  return items
      .map((e) => parseGitlabMr(
            e as Map<String, dynamic>,
            accountId: accountId,
            reviewRequested: reviewRequested,
            assignedToMe: assignedToMe,
          ))
      .toList();
}

String? repoFullNameFromGitlabMr(Map<String, dynamic> json) {
  final refs = json['references'] as Map<String, dynamic>?;
  final full = refs?['full'] as String?;
  if (full != null) {
    final bang = full.lastIndexOf('!');
    if (bang > 0) return full.substring(0, bang);
  }
  final web = json['web_url'] as String? ?? '';
  const marker = '/-/merge_requests/';
  final i = web.indexOf(marker);
  if (i > 0) {
    final prefix = web.substring(0, i);
    return prefix.replaceFirst(RegExp(r'^https?://[^/]+/'), '');
  }
  return null;
}

ChangeRequest parseGitlabMr(
  Map<String, dynamic> json, {
  required String accountId,
  required bool reviewRequested,
  required bool assignedToMe,
  ChangeRequest? summary,
}) {
  final iid = json['iid'] as int? ?? summary?.localNumber ?? 0;
  final repoFullName = repoFullNameFromGitlabMr(json) ?? summary?.repoFullName ?? '';
  final stateStr = json['state'] as String? ?? 'opened';
  final state = switch (stateStr) {
    'merged' => CrState.merged,
    'closed' => CrState.closed,
    _ => CrState.open,
  };
  final created = DateTime.tryParse(json['created_at'] as String? ?? '') ?? summary?.createdAt ?? DateTime.now().toUtc();
  final updated = DateTime.tryParse(json['updated_at'] as String? ?? '') ?? created;
  final pipeline = json['head_pipeline'] as Map<String, dynamic>? ?? json['pipeline'] as Map<String, dynamic>?;
  final refs = json['diff_refs'] as Map<String, dynamic>?;
  final mergeStatus = json['detailed_merge_status'] as String? ?? json['merge_status'] as String?;
  final mergeable = mergeStatus == 'mergeable' || mergeStatus == 'can_be_merged';
  return ChangeRequest(
    id: ChangeRequest.makeId(
      platform: ForgePlatform.gitlab,
      accountId: accountId,
      repoFullName: repoFullName,
      localNumber: iid,
    ),
    localNumber: iid,
    platform: ForgePlatform.gitlab,
    accountId: accountId,
    repoFullName: repoFullName,
    title: json['title'] as String? ?? summary?.title ?? '',
    body: json['description'] as String? ?? summary?.body,
    state: state,
    sourceBranch: json['source_branch'] as String? ?? summary?.sourceBranch ?? '',
    targetBranch: json['target_branch'] as String? ?? summary?.targetBranch ?? '',
    authorLogin: (json['author'] as Map<String, dynamic>?)?['username'] as String? ?? summary?.authorLogin ?? '',
    draft: json['draft'] as bool? ?? json['work_in_progress'] as bool? ?? summary?.draft ?? false,
    webUrl: json['web_url'] as String? ?? summary?.webUrl ?? '',
    updatedAt: updated.toUtc(),
    createdAt: created.toUtc(),
    reviewRequested: reviewRequested,
    assignedToMe: assignedToMe,
    ciStatus: pipeline?['status'] as String?,
    mergeable: mergeable ? true : (mergeStatus == null ? summary?.mergeable : false),
    headSha: refs?['head_sha'] as String? ?? summary?.headSha,
    startSha: refs?['start_sha'] as String? ?? summary?.startSha,
    baseSha: refs?['base_sha'] as String? ?? summary?.baseSha,
  );
}

ChangedFile parseGitlabDiff(Map<String, dynamic> json) {
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
    additions: 0,
    deletions: 0,
    patch: clipped.$1,
    truncated: clipped.$2 || raw == null,
  );
}

ReviewComment parseGitlabNote(Map<String, dynamic> json) {
  final created = DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now().toUtc();
  final position = json['position'] as Map<String, dynamic>?;
  return ReviewComment(
    id: '${json['id']}',
    authorLogin: (json['author'] as Map<String, dynamic>?)?['username'] as String? ?? '',
    body: json['body'] as String? ?? '',
    path: position?['new_path'] as String? ?? json['file_path'] as String?,
    line: position?['new_line'] as int?,
    createdAt: created.toUtc(),
  );
}

NotificationItem parseGitlabTodo(Map<String, dynamic> json, String accountId) {
  final target = json['target'] as Map<String, dynamic>? ?? {};
  final webUrl = json['target_url'] as String? ?? target['web_url'] as String? ?? '';
  final created = DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now().toUtc();
  final targetType = (json['target_type'] as String? ?? '').toLowerCase();
  var relatedType = targetType.contains('mergerequest')
      ? RelatedType.changeRequest
      : (targetType.contains('issue') ? RelatedType.issue : RelatedType.other);
  final ref = firstChangeRequestRef([
    webUrl,
    target['web_url'] as String?,
    json['target_url'] as String?,
  ]);
  if (ref != null) relatedType = RelatedType.changeRequest;
  final iid = (target['iid'] as num?)?.toInt() ?? ref?.localNumber;
  final repoFullName = ref?.repoFullName ??
      (relatedType == RelatedType.changeRequest ? repoFullNameFromGitlabMr({...target, 'web_url': webUrl}) : null);
  return NotificationItem(
    id: 'gitlab:$accountId:${json['id']}',
    platform: ForgePlatform.gitlab,
    accountId: accountId,
    title: target['title'] as String? ?? json['body'] as String? ?? 'To-do',
    reason: json['action_name'] as String?,
    unread: true,
    webUrl: webUrl,
    updatedAt: created.toUtc(),
    relatedType: relatedType,
    repoFullName: repoFullName,
    localNumber: iid,
  );
}

Repo parseGitlabProject(Map<String, dynamic> json, String accountId) {
  final updated = DateTime.tryParse(json['last_activity_at'] as String? ?? json['updated_at'] as String? ?? '') ??
      DateTime.now().toUtc();
  final visibility = parseRepoVisibility(raw: json['visibility'] as String?);
  final created = DateTime.tryParse(json['created_at'] as String? ?? '');
  return Repo(
    id: 'gitlab:$accountId:${json['id']}',
    platform: ForgePlatform.gitlab,
    accountId: accountId,
    fullName: json['path_with_namespace'] as String? ?? '',
    webUrl: json['web_url'] as String? ?? '',
    private: visibility != RepoVisibility.public,
    defaultBranch: json['default_branch'] as String? ?? 'main',
    updatedAt: updated.toUtc(),
    description: blankToNull(json['description'] as String?),
    // GitLab project list has no primary language; skip extra /languages call.
    language: null,
    starCount: jsonInt(json['star_count']),
    forkCount: jsonInt(json['forks_count']),
    openIssueCount: jsonInt(json['open_issues_count']),
    cloneUrl: blankToNull(json['http_url_to_repo'] as String?),
    sshUrl: blankToNull(json['ssh_url_to_repo'] as String?),
    // GitLab star_count is the closest thing to watchers here.
    watchersCount: jsonInt(json['star_count']),
    // No independent subscribers count on GitLab list response.
    license: parseLicense(json['license']),
    homepage: blankToNull(json['homepage'] as String?),
    createdAt: created?.toUtc(),
    archived: json['archived'] == true,
    fork: json['forked_from_project'] != null,
    topics: parseTopics(json['topics'] ?? json['tag_list']),
    visibility: visibility,
  );
}
