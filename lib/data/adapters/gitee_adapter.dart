import 'package:uuid/uuid.dart';

import '../../domain/forge_adapter.dart';
import '../../domain/models.dart';
import '../../domain/refs.dart';
import '../http_client.dart';
import '../patch_codec.dart';
import '../readme_codec.dart';

const giteeTokenCreateUrl = 'https://gitee.com/personal_access_tokens';
const giteeRevokeUrl = 'https://gitee.com/personal_access_tokens';
const giteeInboxRepoLimit = 20;

class GiteeAdapter implements ForgeAdapter {
  GiteeAdapter({ForgeHttp? http, Uuid? uuid})
      : _http = http ?? ForgeHttp(),
        _uuid = uuid ?? const Uuid();

  static final _api = Uri.https('gitee.com', '/api/v5');

  final ForgeHttp _http;
  final Uuid _uuid;

  @override
  ForgePlatform get platform => ForgePlatform.gitee;

  Uri _uri(String path, [Map<String, String>? query]) {
    final basePath = _api.path.endsWith('/') ? _api.path.substring(0, _api.path.length - 1) : _api.path;
    return _api.replace(path: '$basePath$path', queryParameters: query);
  }

  Future<dynamic> _get(String path, String token, [Map<String, String>? query]) {
    return _http.getJson(_uri(path, query), token: token);
  }

  @override
  Future<PlatformAccount> verifyAndProfile({
    required String token,
    String? displayName,
    String? baseUrl,
    String? orgId,
  }) async {
    final json = await _get('/user', token) as Map<String, dynamic>;
    final login = json['login'] as String? ?? '';
    final name = json['name'] as String?;
    return PlatformAccount(
      id: _uuid.v4(),
      platform: ForgePlatform.gitee,
      login: login,
      displayName: (displayName != null && displayName.trim().isNotEmpty) ? displayName.trim() : (name?.trim().isNotEmpty == true ? name!.trim() : login),
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<List<ChangeRequest>> listInbox({
    required PlatformAccount account,
    required String token,
    int page = 1,
  }) async {
    final repos = await listRepos(account: account, token: token);
    final limited = repos.take(giteeInboxRepoLimit).toList();
    final chunks = await Future.wait(limited.map((repo) async {
      final parts = repo.fullName.split('/');
      if (parts.length < 2) return <ChangeRequest>[];
      final owner = parts[0];
      final name = parts.sublist(1).join('/');
      final json = await _get('/repos/$owner/$name/pulls', token, {
        'state': 'open',
        'assignee': account.login,
        'per_page': '20',
        'page': '$page',
      });
      if (json is! List) return <ChangeRequest>[];
      return json
          .map((e) => parseGiteePull(e as Map<String, dynamic>, accountId: account.id, repoFullName: repo.fullName))
          .toList();
    }));
    return [for (final chunk in chunks) ...chunk];
  }

  @override
  Future<List<NotificationItem>> listNotifications({
    required PlatformAccount account,
    required String token,
  }) async {
    try {
      final json = await _get('/notifications/threads', token, {
        'unread': 'true',
        'per_page': '50',
      });
      if (json is! List) return [];
      return json
          .map((e) => parseGiteeNotification(e as Map<String, dynamic>, account.id))
          .where((n) => n.webUrl.isNotEmpty)
          .toList();
    } on AdapterException catch (e) {
      if (e.kind == AdapterErrorKind.unsupported) rethrow;
      rethrow;
    }
  }

  @override
  Future<List<Repo>> listRepos({
    required PlatformAccount account,
    required String token,
  }) async {
    final json = await _get('/user/repos', token, {
      'sort': 'updated',
      'per_page': '$giteeInboxRepoLimit',
      'type': 'all',
    });
    if (json is! List) return [];
    return json.take(giteeInboxRepoLimit).map((e) => parseGiteeRepo(e as Map<String, dynamic>, account.id)).toList();
  }

  @override
  Future<List<ChangeRequest>> listOpenChangeRequests({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async {
    final parts = repo.fullName.split('/');
    if (parts.length < 2) return [];
    final owner = parts[0];
    final name = parts.sublist(1).join('/');
    final json = await _get('/repos/$owner/$name/pulls', token, {
      'state': 'open',
      'per_page': '20',
    });
    return jsonAsList(json)
        .map((e) => parseGiteePull(e as Map<String, dynamic>, accountId: account.id, repoFullName: repo.fullName))
        .toList();
  }

  @override
  Future<String?> getReadme({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async {
    try {
      final json = await _get('/repos/${repo.fullName}/readme', token);
      final text = decodeRepoFileContent(json);
      if (text == null || text.trim().isEmpty) return null;
      return clipReadme(text).$1;
    } on AdapterException catch (e) {
      if (isMissingFile(e)) return null;
      rethrow;
    }
  }

  @override
  Set<ReviewType> get supportedReviews => const {
        ReviewType.comment,
        ReviewType.approve,
        ReviewType.merge,
      };

  @override
  Set<RepoCapability> get supportedCapabilities => const {
        // Gitee has issues / branches / commits / contributors endpoints.
        RepoCapability.issues,
        RepoCapability.branches,
        RepoCapability.commits,
        RepoCapability.contributors,
        RepoCapability.star,
      };

  String _prPath(ChangeRequest cr) => '/repos/${cr.owner}/${cr.repoName}/pulls/${cr.localNumber}';

  @override
  Future<ChangeRequest> getChangeRequest({
    required PlatformAccount account,
    required String token,
    required ChangeRequest summary,
  }) async {
    final json = await _get(_prPath(summary), token) as Map<String, dynamic>;
    return parseGiteePull(
      json,
      accountId: account.id,
      repoFullName: summary.repoFullName,
      summary: summary,
    );
  }

  @override
  Future<List<ChangedFile>> listFiles({
    required PlatformAccount account,
    required String token,
    required ChangeRequest cr,
  }) async {
    final json = await _get('${_prPath(cr)}/files', token);
    if (json is! List) return [];
    final files = json.map((e) => parseGiteeFile(e as Map<String, dynamic>)).toList();
    final diffUri = cr.webUrl.isNotEmpty ? Uri.parse('${cr.webUrl}.diff') : _uri('${_prPath(cr)}.diff');
    return recoverPatches(
      files: files,
      fetchDiff: () => _http.getText(diffUri, token: token),
    );
  }

  @override
  Future<List<ReviewComment>> listComments({
    required PlatformAccount account,
    required String token,
    required ChangeRequest cr,
  }) async {
    final json = await _get('${_prPath(cr)}/comments', token, {'per_page': '50'});
    if (json is! List) return [];
    final comments = json.map((e) => parseGiteeComment(e as Map<String, dynamic>)).toList();
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
    final base = _prPath(cr);
    switch (action.type) {
      case ReviewType.merge:
        await _http.putJson(_uri('$base/merge'), token: token, body: const <String, dynamic>{});
      case ReviewType.approve:
        await _http.postJson(_uri('$base/review'), token: token, body: const <String, dynamic>{});
        final text = action.body?.trim();
        if (text != null && text.isNotEmpty) {
          await _http.postJson(_uri('$base/comments'), token: token, body: {'body': text});
        }
      case ReviewType.comment:
        final text = action.body?.trim() ?? '';
        if (text.isEmpty) {
          throw AdapterException.http(422, 'Comment body is required');
        }
        await _http.postJson(_uri('$base/comments'), token: token, body: {
          'body': text,
          if (action.isInline) 'path': action.path,
          if (action.line != null) 'position': action.line,
        });
      case ReviewType.requestChanges:
        throw AdapterException.unsupported('Gitee does not support request changes');
    }
  }

  // ---- 仓库级特性 stub (commit 1) ----------------------------------------
  // 真实实现在 commit 2/3/4/5 替换。stub 仅抛 unsupported,UI 通过
  // supportedCapabilities 显隐,不会触达这里。

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
    final uri = _uri('/user/stars/${repo.owner}/${repo.repoName}');
    try {
      await _http.putJson(uri, token: token);
    } on AdapterException catch (e) {
      if (e.kind == AdapterErrorKind.unsupported) rethrow;
      // Gitee 401/403 scope 错误全部走 _http.sendJson 翻译;不需特殊处理。
      rethrow;
    }
  }

  @override
  Future<void> unstarRepo({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async {
    final uri = _uri('/user/stars/${repo.owner}/${repo.repoName}');
    await _http.deleteJson(uri, token: token);
  }

  Never _unsupported(String what) =>
      throw AdapterException.unsupported('Gitee adapter does not implement $what yet');
}

ChangeRequest parseGiteePull(
  Map<String, dynamic> json, {
  required String accountId,
  required String repoFullName,
  ChangeRequest? summary,
}) {
  final number = json['number'] as int;
  final created = DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now().toUtc();
  final updated = DateTime.tryParse(json['updated_at'] as String? ?? '') ?? created;
  final head = json['head'] as Map<String, dynamic>?;
  final base = json['base'] as Map<String, dynamic>?;
  final merged = json['merged'] == true || json['state'] == 'merged';
  final stateStr = json['state'] as String? ?? 'open';
  final state = merged
      ? CrState.merged
      : (stateStr == 'closed' ? CrState.closed : CrState.open);
  return ChangeRequest(
    id: ChangeRequest.makeId(
      platform: ForgePlatform.gitee,
      accountId: accountId,
      repoFullName: repoFullName,
      localNumber: number,
    ),
    localNumber: number,
    platform: ForgePlatform.gitee,
    accountId: accountId,
    repoFullName: repoFullName,
    title: json['title'] as String? ?? summary?.title ?? '',
    body: json['body'] as String? ?? json['body_html'] as String? ?? summary?.body,
    state: state,
    sourceBranch: head?['ref'] as String? ?? summary?.sourceBranch ?? '',
    targetBranch: base?['ref'] as String? ?? summary?.targetBranch ?? '',
    authorLogin: (json['user'] as Map<String, dynamic>?)?['login'] as String? ?? summary?.authorLogin ?? '',
    draft: json['draft'] as bool? ?? summary?.draft ?? false,
    webUrl: json['html_url'] as String? ?? summary?.webUrl ?? '',
    updatedAt: updated.toUtc(),
    createdAt: created.toUtc(),
    reviewRequested: summary?.reviewRequested ?? true,
    assignedToMe: summary?.assignedToMe ?? true,
    mergeable: json['mergeable'] as bool?,
  );
}

ChangedFile parseGiteeFile(Map<String, dynamic> json) {
  final path = json['filename'] as String? ?? json['file_path'] as String? ?? json['path'] as String? ?? '';
  final raw = json['patch'] as String? ?? json['diff'] as String?;
  final clipped = clipPatch(raw);
  return ChangedFile(
    path: path,
    status: json['status'] as String? ?? 'modified',
    additions: json['additions'] as int? ?? 0,
    deletions: json['deletions'] as int? ?? 0,
    patch: clipped.$1,
    truncated: clipped.$2 || raw == null,
  );
}

ReviewComment parseGiteeComment(Map<String, dynamic> json) {
  final created = DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now().toUtc();
  return ReviewComment(
    id: '${json['id']}',
    authorLogin: (json['user'] as Map<String, dynamic>?)?['login'] as String? ?? '',
    body: json['body'] as String? ?? '',
    path: json['path'] as String?,
    line: json['position'] as int? ?? json['line'] as int?,
    createdAt: created.toUtc(),
  );
}

NotificationItem parseGiteeNotification(Map<String, dynamic> json, String accountId) {
  final subject = json['subject'] as Map<String, dynamic>? ?? {};
  final repo = json['repository'] as Map<String, dynamic>? ?? json['project'] as Map<String, dynamic>? ?? {};
  final webUrl = (subject['html_url'] as String?) ??
      (json['html_url'] as String?) ??
      (repo['html_url'] as String?) ??
      '';
  final type = (subject['type'] ?? json['type'])?.toString().toLowerCase();
  var relatedType = (type != null && type.contains('pull'))
      ? RelatedType.changeRequest
      : (type != null && type.contains('issue') ? RelatedType.issue : RelatedType.other);
  final ref = firstChangeRequestRef([
    subject['url'] as String?,
    subject['html_url'] as String?,
    json['html_url'] as String?,
    json['url'] as String?,
    webUrl,
  ]);
  if (ref != null) relatedType = RelatedType.changeRequest;
  final repoFullName = ref?.repoFullName ?? repo['full_name'] as String? ?? repo['path_with_namespace'] as String?;
  final localNumber = ref?.localNumber;
  final updated = DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now().toUtc();
  return NotificationItem(
    id: 'gitee:$accountId:${json['id']}',
    platform: ForgePlatform.gitee,
    accountId: accountId,
    title: subject['title'] as String? ?? json['content'] as String? ?? 'Notification',
    reason: (json['type'] ?? subject['type'])?.toString(),
    unread: json['unread'] as bool? ?? true,
    webUrl: webUrl,
    updatedAt: updated.toUtc(),
    relatedType: relatedType,
    repoFullName: repoFullName,
    localNumber: localNumber,
  );
}

Repo parseGiteeRepo(Map<String, dynamic> json, String accountId) {
  final namespace = json['namespace'] as Map<String, dynamic>?;
  final path = json['path'] as String?;
  final nsPath = namespace?['path'] as String?;
  final fullName = (json['full_name'] as String?) ?? ((nsPath != null && path != null) ? '$nsPath/$path' : '');
  final updated = DateTime.tryParse(json['updated_at'] as String? ?? json['pushed_at'] as String? ?? '') ??
      DateTime.now().toUtc();
  final visibility = parseRepoVisibility(
    raw: json['visibility'] as String?,
    privateFlag: json['private'] as bool? ?? (json['public'] == false),
  );
  final created = DateTime.tryParse(json['created_at'] as String? ?? '');
  // Gitee list responses don't always carry an https clone URL; fall back to
  // appending .git to the web URL so the copy row still has something useful.
  final htmlUrl = json['html_url'] as String?;
  final explicitHttps = blankToNull(json['https_url'] as String?);
  final derivedHttps = (htmlUrl == null || htmlUrl.isEmpty) ? null : '${htmlUrl.replaceFirst(RegExp(r'\.git$'), '')}.git';
  return Repo(
    id: 'gitee:$accountId:${json['id']}',
    platform: ForgePlatform.gitee,
    accountId: accountId,
    fullName: fullName,
    webUrl: htmlUrl ?? (fullName.isEmpty ? '' : 'https://gitee.com/$fullName'),
    private: visibility != RepoVisibility.public,
    defaultBranch: json['default_branch'] as String? ?? 'master',
    updatedAt: updated.toUtc(),
    description: blankToNull(json['description'] as String?),
    language: blankToNull(json['language'] as String?),
    starCount: jsonInt(json['stargazers_count'] ?? json['stars_count']),
    forkCount: jsonInt(json['forks_count']),
    openIssueCount: jsonInt(json['open_issues_count'] ?? json['open_issues']),
    cloneUrl: explicitHttps ?? derivedHttps,
    sshUrl: blankToNull(json['ssh_url'] as String?),
    watchersCount: jsonInt(json['watchers_count']),
    subscribersCount: jsonInt(json['subscribers_count']),
    license: parseLicense(json['license']),
    homepage: blankToNull(json['homepage'] as String?),
    createdAt: created?.toUtc(),
    archived: json['archived'] == true,
    fork: json['fork'] == true,
    topics: parseTopics(json['topics'] ?? json['project_labels']),
    visibility: visibility,
  );
}
