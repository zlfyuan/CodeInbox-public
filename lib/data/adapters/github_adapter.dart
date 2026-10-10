import 'package:uuid/uuid.dart';

import '../../domain/forge_adapter.dart';
import '../../domain/inbox.dart';
import '../../domain/models.dart';
import '../../domain/refs.dart';
import '../http_client.dart';
import '../patch_codec.dart';
import '../readme_codec.dart';

const githubTokenCreateUrl =
    'https://github.com/settings/tokens/new?description=CodeInbox&scopes=repo,notifications,read:user';

const githubRevokeUrl = 'https://github.com/settings/tokens';

class GithubAdapter implements ForgeAdapter {
  GithubAdapter({ForgeHttp? http, Uuid? uuid})
      : _http = http ?? ForgeHttp(),
        _uuid = uuid ?? const Uuid();

  static final _api = Uri.https('api.github.com');

  final ForgeHttp _http;
  final Uuid _uuid;

  @override
  ForgePlatform get platform => ForgePlatform.github;

  Map<String, String> get _headers => const {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      };

  Future<dynamic> _get(String path, String token, [Map<String, String>? query]) {
    return _http.getJson(
      _api.replace(path: path, queryParameters: query),
      token: token,
      headers: _headers,
    );
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
      platform: ForgePlatform.github,
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
    final review = await _search(token, 'is:pr is:open review-requested:@me', page: page);
    final assigned = await _search(token, 'is:pr is:open assignee:@me', page: page);
    return mergeInbox([
      ...parseGithubSearchItems(review, accountId: account.id, reviewRequested: true, assignedToMe: false),
      ...parseGithubSearchItems(assigned, accountId: account.id, reviewRequested: false, assignedToMe: true),
    ]);
  }

  Future<List<dynamic>> _search(String token, String q, {int page = 1}) async {
    final json = await _get('/search/issues', token, {
      'q': q,
      'per_page': '50',
      'page': '$page',
    }) as Map<String, dynamic>;
    return json['items'] as List<dynamic>? ?? [];
  }

  @override
  Future<List<NotificationItem>> listNotifications({
    required PlatformAccount account,
    required String token,
  }) async {
    final json = await _get('/notifications', token, {'all': 'false', 'per_page': '50'});
    if (json is! List) return [];
    return json.map((e) => parseGithubNotification(e as Map<String, dynamic>, account.id)).where((n) => n.webUrl.isNotEmpty).toList();
  }

  @override
  Future<List<Repo>> listRepos({
    required PlatformAccount account,
    required String token,
  }) async {
    final json = await _get('/user/repos', token, {
      'sort': 'updated',
      'per_page': '50',
      'affiliation': 'owner,collaborator,organization_member',
    });
    if (json is! List) return [];
    return json.map((e) => parseGithubRepo(e as Map<String, dynamic>, account.id)).toList();
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
  Future<List<ChangeRequest>> listOpenChangeRequests({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async {
    final json = await _get('/repos/${repo.fullName}/pulls', token, {'state': 'open', 'per_page': '50'});
    final items = jsonAsList(json);
    return items
        .map((e) => parseGithubPull(
              e as Map<String, dynamic>,
              accountId: account.id,
              summary: ChangeRequest(
                id: ChangeRequest.makeId(
                  platform: ForgePlatform.github,
                  accountId: account.id,
                  repoFullName: repo.fullName,
                  localNumber: 0,
                ),
                localNumber: 0,
                platform: ForgePlatform.github,
                accountId: account.id,
                repoFullName: repo.fullName,
                title: '',
                authorLogin: '',
                webUrl: repo.webUrl,
                updatedAt: repo.updatedAt,
                createdAt: repo.updatedAt,
              ),
            ))
        .toList();
  }

  @override
  Set<ReviewType> get supportedReviews => const {
        ReviewType.comment,
        ReviewType.approve,
        ReviewType.requestChanges,
        ReviewType.merge,
      };

  @override
  Set<RepoCapability> get supportedCapabilities => const {
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
    var cr = parseGithubPull(json, accountId: account.id, summary: summary);
    final sha = (json['head'] as Map<String, dynamic>?)?['sha'] as String?;
    if (sha != null) {
      try {
        final status = await _get('/repos/${summary.owner}/${summary.repoName}/commits/$sha/status', token);
        if (status is Map<String, dynamic>) {
          cr = cr.copyWith(ciStatus: status['state'] as String?);
        }
      } on AdapterException {
        // Combined status is optional.
      }
    }
    return cr;
  }

  @override
  Future<List<ChangedFile>> listFiles({
    required PlatformAccount account,
    required String token,
    required ChangeRequest cr,
  }) async {
    final json = await _get('${_prPath(cr)}/files', token, {'per_page': '100'});
    if (json is! List) return [];
    final files = json.map((e) => parseGithubFile(e as Map<String, dynamic>)).toList();
    // /files omits patch for binaries and oversized files; recover from .diff.
    if (cr.webUrl.isEmpty) return files;
    return recoverPatches(
      files: files,
      fetchDiff: () => _http.getText(Uri.parse('${cr.webUrl}.diff'), token: token),
    );
  }

  @override
  Future<List<ReviewComment>> listComments({
    required PlatformAccount account,
    required String token,
    required ChangeRequest cr,
  }) async {
    final issuePath = '/repos/${cr.owner}/${cr.repoName}/issues/${cr.localNumber}/comments';
    final reviewPath = '${_prPath(cr)}/comments';
    final results = await Future.wait([
      _get(issuePath, token, {'per_page': '50'}),
      _get(reviewPath, token, {'per_page': '50'}),
    ]);
    final comments = <ReviewComment>[];
    for (final raw in results) {
      if (raw is! List) continue;
      comments.addAll(raw.map((e) => parseGithubComment(e as Map<String, dynamic>)));
    }
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
    final uri = _api.replace(path: '${_prPath(cr)}${action.type == ReviewType.merge ? '/merge' : '/reviews'}');
    if (action.type == ReviewType.merge) {
      await _http.putJson(uri, token: token, headers: _headers, body: const {'merge_method': 'merge'});
      return;
    }
    if (action.isInline && action.type == ReviewType.comment) {
      final text = action.body?.trim() ?? '';
      if (text.isEmpty) throw AdapterException.http(422, 'Comment body is required');
      final body = <String, dynamic>{
        'body': text,
        'path': action.path,
        'line': action.line,
        'side': 'RIGHT',
        if (cr.headSha != null) 'commit_id': cr.headSha,
      };
      await _http.postJson(
        _api.replace(path: '${_prPath(cr)}/comments'),
        token: token,
        headers: _headers,
        body: body,
      );
      return;
    }
    final event = switch (action.type) {
      ReviewType.approve => 'APPROVE',
      ReviewType.requestChanges => 'REQUEST_CHANGES',
      ReviewType.comment => 'COMMENT',
      ReviewType.merge => 'COMMENT',
    };
    final body = <String, dynamic>{'event': event};
    final text = action.body?.trim();
    if (text != null && text.isNotEmpty) body['body'] = text;
    await _http.postJson(uri, token: token, headers: _headers, body: body);
  }

  // ---- 仓库级特性 (commit 2/4/5 实现中) -----------------------------------

  @override
  Future<List<Issue>> listIssues({
    required PlatformAccount account,
    required String token,
    required Repo repo,
    IssueState state = IssueState.open,
  }) async {
    // GitHub /repos/{}/issues returns PRs as well — filter them out.
    final json = await _get('/repos/${repo.fullName}/issues', token, {
      'state': state == IssueState.open ? 'open' : 'closed',
      'per_page': '50',
    });
    final items = jsonAsList(json);
    return items
        .whereType<Map<String, dynamic>>()
        // pull_request object is present iff this is a PR.
        .where((e) => e['pull_request'] == null)
        .map((e) => parseGithubIssue(e, account.id, repo.fullName))
        .toList();
  }

  @override
  Future<Issue> getIssue({
    required PlatformAccount account,
    required String token,
    required Issue summary,
  }) async {
    final json = await _get('/repos/${summary.repoFullName}/issues/${summary.localNumber}', token)
        as Map<String, dynamic>;
    return parseGithubIssue(json, account.id, summary.repoFullName);
  }

  @override
  Future<List<IssueComment>> listIssueComments({
    required PlatformAccount account,
    required String token,
    required Issue issue,
  }) async {
    final json = await _get('/repos/${issue.repoFullName}/issues/${issue.localNumber}/comments', token,
        {'per_page': '50'});
    final items = jsonAsList(json);
    final comments = items
        .whereType<Map<String, dynamic>>()
        .map(parseGithubIssueComment)
        .toList();
    comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return comments;
  }

  @override
  Future<List<Branch>> listBranches({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async {
    final json = await _get('/repos/${repo.fullName}/branches', token, {'per_page': '30'});
    final items = jsonAsList(json);
    return items
        .whereType<Map<String, dynamic>>()
        .map(parseGithubBranch)
        .toList();
  }

  @override
  Future<List<GitCommit>> listCommits({
    required PlatformAccount account,
    required String token,
    required Repo repo,
    String? sha,
  }) async {
    final query = <String, String>{'per_page': '30'};
    if (sha != null && sha.isNotEmpty) query['sha'] = sha;
    final json = await _get('/repos/${repo.fullName}/commits', token, query);
    final items = jsonAsList(json);
    return items
        .whereType<Map<String, dynamic>>()
        .map(parseGithubCommit)
        .toList();
  }

  @override
  Future<List<Contributor>> listContributors({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async {
    final json = await _get('/repos/${repo.fullName}/contributors', token, {
      'per_page': '30',
      'anon': 'false',
    });
    final items = jsonAsList(json);
    return items
        .whereType<Map<String, dynamic>>()
        .map(parseGithubContributor)
        .toList();
  }

  @override
  Future<void> starRepo({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async {
    await _http.putJson(_api.replace(path: '/user/starred/${repo.fullName}'),
        token: token, headers: _headers);
  }

  @override
  Future<void> unstarRepo({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async {
    await _http.deleteJson(_api.replace(path: '/user/starred/${repo.fullName}'),
        token: token, headers: _headers);
  }
}

List<ChangeRequest> parseGithubSearchItems(
  List<dynamic> items, {
  required String accountId,
  required bool reviewRequested,
  required bool assignedToMe,
}) {
  return items.map((raw) {
    final json = raw as Map<String, dynamic>;
    final number = json['number'] as int;
    final repoFullName = repoFullNameFromGithubApiUrl(json['repository_url'] as String?);
    final pr = json['pull_request'] as Map<String, dynamic>?;
    final webUrl = (pr?['html_url'] as String?) ?? (json['html_url'] as String? ?? '');
    final created = DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now().toUtc();
    final updated = DateTime.tryParse(json['updated_at'] as String? ?? '') ?? created;
    return ChangeRequest(
      id: ChangeRequest.makeId(
        platform: ForgePlatform.github,
        accountId: accountId,
        repoFullName: repoFullName,
        localNumber: number,
      ),
      localNumber: number,
      platform: ForgePlatform.github,
      accountId: accountId,
      repoFullName: repoFullName,
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      state: CrState.open,
      authorLogin: (json['user'] as Map<String, dynamic>?)?['login'] as String? ?? '',
      draft: json['draft'] as bool? ?? false,
      webUrl: webUrl,
      updatedAt: updated.toUtc(),
      createdAt: created.toUtc(),
      reviewRequested: reviewRequested,
      assignedToMe: assignedToMe,
    );
  }).toList();
}

String repoFullNameFromGithubApiUrl(String? repositoryUrl) {
  const prefix = 'https://api.github.com/repos/';
  if (repositoryUrl == null || !repositoryUrl.startsWith(prefix)) return repositoryUrl ?? '';
  return repositoryUrl.substring(prefix.length);
}

NotificationItem parseGithubNotification(Map<String, dynamic> json, String accountId) {
  final subject = json['subject'] as Map<String, dynamic>? ?? {};
  final repo = json['repository'] as Map<String, dynamic>? ?? {};
  final apiUrl = subject['url'] as String?;
  var webUrl = '';
  if (apiUrl != null && apiUrl.startsWith('https://api.github.com/repos/')) {
    webUrl = apiUrl
        .replaceFirst('https://api.github.com/repos/', 'https://github.com/')
        .replaceFirst('/pulls/', '/pull/')
        .replaceFirst('/issues/', '/issues/');
  } else {
    webUrl = repo['html_url'] as String? ?? '';
  }
  final type = subject['type'] as String?;
  var relatedType = switch (type) {
    'PullRequest' => RelatedType.changeRequest,
    'Issue' => RelatedType.issue,
    _ => RelatedType.other,
  };
  final ref = firstChangeRequestRef([
    apiUrl,
    subject['latest_comment_url'] as String?,
    webUrl,
    json['url'] as String?,
  ]);
  if (ref != null) {
    relatedType = RelatedType.changeRequest;
  }
  final updated = DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now().toUtc();
  return NotificationItem(
    id: 'github:$accountId:${json['id']}',
    platform: ForgePlatform.github,
    accountId: accountId,
    title: subject['title'] as String? ?? 'Notification',
    reason: json['reason'] as String?,
    unread: json['unread'] as bool? ?? true,
    webUrl: ref == null
        ? webUrl
        : 'https://github.com/${ref.repoFullName}/pull/${ref.localNumber}',
    updatedAt: updated.toUtc(),
    relatedType: relatedType,
    repoFullName: ref?.repoFullName ?? repo['full_name'] as String?,
    localNumber: ref?.localNumber,
  );
}

ChangeRequest parseGithubPull(
  Map<String, dynamic> json, {
  required String accountId,
  ChangeRequest? summary,
}) {
  final number = json['number'] as int? ?? summary?.localNumber ?? 0;
  final base = json['base'] as Map<String, dynamic>?;
  final head = json['head'] as Map<String, dynamic>?;
  final repoFullName = summary?.repoFullName ??
      (base?['repo'] as Map<String, dynamic>?)?['full_name'] as String? ??
      '';
  final merged = json['merged'] == true;
  final stateStr = json['state'] as String? ?? 'open';
  final state = merged
      ? CrState.merged
      : (stateStr == 'closed' ? CrState.closed : CrState.open);
  final created = DateTime.tryParse(json['created_at'] as String? ?? '') ?? summary?.createdAt ?? DateTime.now().toUtc();
  final updated = DateTime.tryParse(json['updated_at'] as String? ?? '') ?? created;
  return ChangeRequest(
    id: ChangeRequest.makeId(
      platform: ForgePlatform.github,
      accountId: accountId,
      repoFullName: repoFullName,
      localNumber: number,
    ),
    localNumber: number,
    platform: ForgePlatform.github,
    accountId: accountId,
    repoFullName: repoFullName,
    title: json['title'] as String? ?? summary?.title ?? '',
    body: json['body'] as String? ?? summary?.body,
    state: state,
    sourceBranch: head?['ref'] as String? ?? summary?.sourceBranch ?? '',
    targetBranch: base?['ref'] as String? ?? summary?.targetBranch ?? '',
    authorLogin: (json['user'] as Map<String, dynamic>?)?['login'] as String? ?? summary?.authorLogin ?? '',
    draft: json['draft'] as bool? ?? summary?.draft ?? false,
    webUrl: json['html_url'] as String? ?? summary?.webUrl ?? '',
    updatedAt: updated.toUtc(),
    createdAt: created.toUtc(),
    reviewRequested: summary?.reviewRequested ?? false,
    assignedToMe: summary?.assignedToMe ?? false,
    mergeable: json['mergeable'] as bool?,
    headSha: head?['sha'] as String? ?? summary?.headSha,
    startSha: base?['sha'] as String? ?? summary?.startSha,
    baseSha: base?['sha'] as String? ?? summary?.baseSha,
  );
}

ChangedFile parseGithubFile(Map<String, dynamic> json) {
  final raw = json['patch'] as String?;
  final clipped = clipPatch(raw);
  return ChangedFile(
    path: json['filename'] as String? ?? '',
    status: json['status'] as String? ?? 'modified',
    additions: json['additions'] as int? ?? 0,
    deletions: json['deletions'] as int? ?? 0,
    patch: clipped.$1,
    truncated: clipped.$2 || raw == null,
  );
}

ReviewComment parseGithubComment(Map<String, dynamic> json) {
  final created = DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now().toUtc();
  return ReviewComment(
    id: '${json['id']}',
    authorLogin: (json['user'] as Map<String, dynamic>?)?['login'] as String? ?? '',
    body: json['body'] as String? ?? '',
    path: json['path'] as String?,
    line: json['line'] as int? ?? json['original_line'] as int?,
    createdAt: created.toUtc(),
  );
}

/// GitHub /repos/{}/issues 列表/详情项。callers 在 listIssues 已过滤掉 PR,
/// 但 getIssue 单条拉取也走这里(返回的 pull_request 字段会被忽略)。
Issue parseGithubIssue(Map<String, dynamic> json, String accountId, String repoFullName) {
  final number = jsonInt(json['number']);
  final updated = DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now().toUtc();
  final created = DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now().toUtc();
  final stateRaw = json['state'] as String? ?? 'open';
  final state = stateRaw == 'closed' ? IssueState.closed : IssueState.open;
  return Issue(
    id: Issue.makeId(
      platform: ForgePlatform.github,
      accountId: accountId,
      repoFullName: repoFullName,
      localNumber: number,
    ),
    localNumber: number,
    platform: ForgePlatform.github,
    accountId: accountId,
    repoFullName: repoFullName,
    title: json['title'] as String? ?? '',
    body: json['body'] as String?,
    state: state,
    authorLogin: (json['user'] as Map<String, dynamic>?)?['login'] as String? ?? '',
    webUrl: json['html_url'] as String? ?? '',
    updatedAt: updated.toUtc(),
    createdAt: created.toUtc(),
    labels: ((json['labels'] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((e) => (e['name'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toList(),
    assignees: ((json['assignees'] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((e) => (e['login'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toList(),
    commentCount: jsonInt(json['comments']),
  );
}

IssueComment parseGithubIssueComment(Map<String, dynamic> json) {
  final created = DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now().toUtc();
  return IssueComment(
    id: '${json['id']}',
    authorLogin: (json['user'] as Map<String, dynamic>?)?['login'] as String? ?? '',
    body: json['body'] as String? ?? '',
    createdAt: created.toUtc(),
  );
}

Branch parseGithubBranch(Map<String, dynamic> json) {
  final commit = json['commit'] as Map<String, dynamic>?;
  return Branch(
    name: json['name'] as String? ?? '',
    commitSha: (commit?['sha'] as String?) ?? '',
    protected: json['protected'] == true,
  );
}

GitCommit parseGithubCommit(Map<String, dynamic> json) {
  final commit = json['commit'] as Map<String, dynamic>?;
  final author = commit?['author'] as Map<String, dynamic>?;
  final message = (commit?['message'] as String?) ?? '';
  // first line of commit message,strip CR
  final firstLine = message.split('\n').first.trim();
  final authoredAt =
      DateTime.tryParse(author?['date'] as String? ?? '') ?? DateTime.now().toUtc();
  return GitCommit(
    sha: json['sha'] as String? ?? '',
    messageFirstLine: firstLine,
    authorName: (author?['name'] as String?) ?? '',
    authoredAt: authoredAt.toUtc(),
    webUrl: json['html_url'] as String? ?? '',
  );
}

Contributor parseGithubContributor(Map<String, dynamic> json) {
  return Contributor(
    login: json['login'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String?,
    contributionCount: jsonInt(json['contributions']),
    profileUrl: json['html_url'] as String? ?? '',
  );
}

Repo parseGithubRepo(Map<String, dynamic> json, String accountId) {
  final updated = DateTime.tryParse(json['updated_at'] as String? ?? json['pushed_at'] as String? ?? '') ??
      DateTime.now().toUtc();
  final created = DateTime.tryParse(json['created_at'] as String? ?? '');
  final visibility = parseRepoVisibility(
    raw: json['visibility'] as String?,
    privateFlag: json['private'] as bool?,
  );
  return Repo(
    id: 'github:$accountId:${json['id']}',
    platform: ForgePlatform.github,
    accountId: accountId,
    fullName: json['full_name'] as String? ?? '',
    webUrl: json['html_url'] as String? ?? '',
    private: visibility != RepoVisibility.public,
    defaultBranch: json['default_branch'] as String? ?? 'main',
    updatedAt: updated.toUtc(),
    description: blankToNull(json['description'] as String?),
    language: blankToNull(json['language'] as String?),
    starCount: jsonInt(json['stargazers_count']),
    forkCount: jsonInt(json['forks_count']),
    openIssueCount: jsonInt(json['open_issues_count']),
    cloneUrl: blankToNull(json['clone_url'] as String?),
    sshUrl: blankToNull(json['ssh_url'] as String?),
    watchersCount: jsonInt(json['watchers_count']),
    subscribersCount: jsonInt(json['subscribers_count']),
    license: parseLicense(json['license']),
    homepage: blankToNull(json['homepage'] as String?),
    createdAt: created?.toUtc(),
    archived: json['archived'] == true,
    fork: json['fork'] == true,
    topics: parseTopics(json['topics']),
    visibility: visibility,
  );
}


