import 'package:uuid/uuid.dart';

import '../../domain/forge_adapter.dart';
import '../../domain/inbox.dart';
import '../../domain/models.dart';
import '../../domain/refs.dart';
import '../http_client.dart';
import '../patch_codec.dart';
import '../readme_codec.dart';

const codeupTokenSettingsUrl = 'https://devops.aliyun.com/user/setting';

Uri codeupApiUri(String? baseUrl, String path, [Map<String, String>? query]) {
  final base = Uri.parse(normalizeForgeBaseUrl(baseUrl) ?? kCodeupOpenApi);
  var prefix = base.path;
  if (prefix == '/' || prefix.isEmpty) {
    prefix = '';
  } else if (prefix.endsWith('/')) {
    prefix = prefix.substring(0, prefix.length - 1);
  }
  return base.replace(path: '$prefix$path', queryParameters: query);
}

String codeupRepoPath(String repoFullName) => Uri.encodeComponent(repoFullName);

class CodeupAdapter implements ForgeAdapter {
  CodeupAdapter({ForgeHttp? http, Uuid? uuid})
      : _http = http ?? ForgeHttp(),
        _uuid = uuid ?? const Uuid();

  final ForgeHttp _http;
  final Uuid _uuid;

  @override
  ForgePlatform get platform => ForgePlatform.codeup;

  @override
  Set<ReviewType> get supportedReviews => const {
        ReviewType.comment,
        ReviewType.approve,
        ReviewType.requestChanges,
        ReviewType.merge,
      };

  @override
  Set<RepoCapability> get supportedCapabilities => const {
        // Codeup has no public Issue / Star / Contributors API in B-batch scope.
        // Branches and commits are present but deferred to a later batch.
      };

  Map<String, String> _headers(String token) => {'x-yunxiao-token': token};

  String _orgPrefix(String? orgId) {
    final org = orgId?.trim();
    if (org == null || org.isEmpty) return '/oapi/v1/codeup';
    return '/oapi/v1/codeup/organizations/${Uri.encodeComponent(org)}';
  }

  String _crPath(PlatformAccount account, ChangeRequest cr, [String suffix = '']) =>
      '${_orgPrefix(account.orgId)}/repositories/${codeupRepoPath(cr.repoFullName)}/changeRequests/${cr.localNumber}$suffix';

  Future<dynamic> _get(PlatformAccount account, String path, String token, [Map<String, String>? query]) {
    return _http.getJson(codeupApiUri(account.baseUrl, path, query), token: token, headers: _headers(token));
  }

  Future<dynamic> _post(
    PlatformAccount account,
    String path,
    String token, {
    Object? body,
    Map<String, String>? query,
  }) {
    return _http.postJson(
      codeupApiUri(account.baseUrl, path, query),
      token: token,
      headers: _headers(token),
      body: body,
    );
  }

  @override
  Future<PlatformAccount> verifyAndProfile({
    required String token,
    String? displayName,
    String? baseUrl,
    String? orgId,
  }) async {
    final normalized = normalizeForgeBaseUrl(baseUrl) ?? kCodeupOpenApi;
    final org = blankToNull(orgId);
    if (org == null && _isCentralDomain(normalized)) {
      throw AdapterException.http(422, 'Organization ID is required for Codeup 中心版');
    }
    final json = await _http.getJson(
      codeupApiUri(normalized, '/oapi/v1/platform/user'),
      token: token,
      headers: _headers(token),
    ) as Map<String, dynamic>;
    final login = json['username'] as String? ?? json['id'] as String? ?? '';
    final name = json['name'] as String? ?? json['nickName'] as String?;
    return PlatformAccount(
      id: _uuid.v4(),
      platform: ForgePlatform.codeup,
      login: login,
      displayName: (displayName != null && displayName.trim().isNotEmpty)
          ? displayName.trim()
          : (name?.trim().isNotEmpty == true ? name!.trim() : login),
      avatarUrl: null,
      baseUrl: normalized,
      orgId: org,
      createdAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<List<ChangeRequest>> listInbox({
    required PlatformAccount account,
    required String token,
    int page = 1,
  }) async {
    final user = await _http.getJson(
      codeupApiUri(account.baseUrl, '/oapi/v1/platform/user'),
      token: token,
      headers: _headers(token),
    ) as Map<String, dynamic>;
    final userId = '${user['id'] ?? ''}';
    final raw = await _get(account, '${_orgPrefix(account.orgId)}/changeRequests', token, {
      'state': 'opened',
      if (userId.isNotEmpty) 'reviewerIds': userId,
      'orderBy': 'updated_at',
      'sort': 'desc',
      'perPage': '50',
      'page': '$page',
    });
    final repos = await listRepos(account: account, token: token);
    final byProjectId = <String, String>{
      for (final repo in repos) _projectIdFromRepo(repo): repo.fullName,
    };
    return mergeInbox(
      parseCodeupChangeRequests(
        jsonAsList(raw),
        accountId: account.id,
        reviewRequested: true,
        assignedToMe: false,
        projectIdToName: byProjectId,
      ),
    );
  }

  @override
  Future<List<NotificationItem>> listNotifications({
    required PlatformAccount account,
    required String token,
  }) async {
    // No notification inbox; AppStore synthesizes Alerts from open CRs.
    return const [];
  }

  @override
  Future<List<Repo>> listRepos({
    required PlatformAccount account,
    required String token,
  }) async {
    final json = await _get(account, '${_orgPrefix(account.orgId)}/repositories', token, {
      'orderBy': 'last_activity_at',
      'sort': 'desc',
      'perPage': '50',
      'page': '1',
      'archived': 'false',
    });
    return jsonAsList(json).map((e) => parseCodeupRepo(e as Map<String, dynamic>, account.id)).toList();
  }

  @override
  Future<String?> getReadme({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) {
    final prefix = '${_orgPrefix(account.orgId)}/repositories/${codeupRepoPath(repo.fullName)}';
    return firstReadme((name) {
      return _get(account, '$prefix/files', token, {
        'filePath': name,
        'ref': repo.defaultBranch,
      });
    });
  }

  @override
  Future<List<ChangeRequest>> listOpenChangeRequests({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async {
    final identity = _projectIdFromRepo(repo);
    final json = await _get(account, '${_orgPrefix(account.orgId)}/changeRequests', token, {
      'state': 'opened',
      'projectIds': identity,
      'orderBy': 'updated_at',
      'sort': 'desc',
      'perPage': '50',
      'page': '1',
    });
    return parseCodeupChangeRequests(
      jsonAsList(json),
      accountId: account.id,
      reviewRequested: false,
      assignedToMe: false,
      fallbackRepoFullName: repo.fullName,
    );
  }

  @override
  Future<ChangeRequest> getChangeRequest({
    required PlatformAccount account,
    required String token,
    required ChangeRequest summary,
  }) async {
    final json = await _get(account, _crPath(account, summary), token) as Map<String, dynamic>;
    return parseCodeupChangeRequest(
      json,
      accountId: account.id,
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
    var files = <ChangedFile>[];
    try {
      final patchesRaw = await _get(account, _crPath(account, cr, '/diffs/patches'), token);
      final (fromId, toId) = _patchSetIds(jsonAsList(patchesRaw).whereType<Map<String, dynamic>>());
      if (fromId != null && toId != null) {
        try {
          final diffs = await _get(account, _crPath(account, cr, '/diffs'), token, {
            'fromPatchSetId': fromId,
            'toPatchSetId': toId,
          });
          files = jsonAsList(diffs).whereType<Map<String, dynamic>>().map(parseCodeupChangedFile).toList();
        } on AdapterException {
          // Fall through to the path-only tree.
        } on FormatException {
          // Wrapped payloads are handled by jsonAsList; odd shapes go to the tree.
        }
        if (files.isEmpty) {
          final tree = await _get(account, _crPath(account, cr, '/diffs/changeTree'), token, {
            'fromPatchSetId': fromId,
            'toPatchSetId': toId,
          });
          files = jsonAsList(tree).whereType<Map<String, dynamic>>().map(parseCodeupChangedFile).toList();
        }
      }
    } on AdapterException {
      // Missing patch-sets; still try /compares below.
    } on FormatException {
      // Same: compare can still fill the file list.
    }
    if (files.isNotEmpty && files.every((f) => f.hasPatch)) return files;
    final compared = await _compareChangedFiles(account, token, cr);
    if (files.isEmpty) return compared;
    return applyRecoveredPatches(files, {
      for (final f in compared)
        if (f.hasPatch) f.path: f.patch!,
    });
  }

  /// MERGE_TARGET = from (base), MERGE_SOURCE = to (head). Official examples
  /// sometimes omit TARGET; then we skip CR diffs and use /compares.
  (String? fromId, String? toId) _patchSetIds(Iterable<Map<String, dynamic>> patches) {
    String? fromId;
    String? toId;
    var toVersion = -1;
    for (final patch in patches) {
      final type = patch['relatedMergeItemType'] as String? ?? '';
      final id = patch['patchSetBizId'] as String?;
      if (id == null || id.isEmpty) continue;
      if (type == 'MERGE_TARGET') fromId = id;
      if (type == 'MERGE_SOURCE') {
        final version = jsonInt(patch['versionNo']);
        if (version >= toVersion) {
          toVersion = version;
          toId = id;
        }
      }
    }
    return (fromId, toId);
  }

  /// GetCompare is JSON `{commits, diffs:[{newPath, diff}]}`, not a raw `diff --git` body.
  Future<List<ChangedFile>> _compareChangedFiles(
    PlatformAccount account,
    String token,
    ChangeRequest cr,
  ) async {
    if (cr.sourceBranch.isEmpty || cr.targetBranch.isEmpty) return const [];
    try {
      final json = await _get(
        account,
        '${_orgPrefix(account.orgId)}/repositories/${codeupRepoPath(cr.repoFullName)}/compares',
        token,
        {
          'from': cr.targetBranch,
          'to': cr.sourceBranch,
          'sourceType': 'branch',
          'targetType': 'branch',
          'straight': 'false',
        },
      );
      return jsonAsList(json).whereType<Map<String, dynamic>>().map(parseCodeupChangedFile).toList();
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
      final json = await _post(
        account,
        _crPath(account, cr, '/comments/list'),
        token,
        body: const {
          'comment_type': 'GLOBAL_COMMENT,INLINE_COMMENT',
          'state': 'OPENED',
        },
      );
      final comments = jsonAsList(json)
          .whereType<Map<String, dynamic>>()
          .where((e) => e['is_deleted'] != true)
          .map(parseCodeupComment)
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
    switch (action.type) {
      case ReviewType.merge:
        await _post(
          account,
          _crPath(account, cr, '/merge'),
          token,
          body: {
            'mergeMessage': (action.body?.trim().isNotEmpty == true) ? action.body!.trim() : 'Merged via CodeInbox',
          },
        );
      case ReviewType.approve:
        await _post(
          account,
          _crPath(account, cr, '/review'),
          token,
          body: {
            'reviewOpinion': 'PASS',
            if (action.body?.trim().isNotEmpty == true) 'reviewComment': action.body!.trim(),
          },
        );
      case ReviewType.requestChanges:
        final text = action.body?.trim() ?? '';
        if (text.isEmpty) {
          throw AdapterException.http(422, 'Comment body is required');
        }
        await _post(
          account,
          _crPath(account, cr, '/review'),
          token,
          body: {'reviewOpinion': 'NOT_PASS', 'reviewComment': text},
        );
      case ReviewType.comment:
        final text = action.body?.trim() ?? '';
        if (text.isEmpty) {
          throw AdapterException.http(422, 'Comment body is required');
        }
        final body = <String, dynamic>{
          'comment_type': action.isInline ? 'INLINE_COMMENT' : 'GLOBAL_COMMENT',
          'content': text,
          'draft': false,
        };
        if (action.isInline) {
          body['file_path'] = action.path;
          if (action.line != null) body['line_number'] = action.line;
        }
        await _post(account, _crPath(account, cr, '/comments'), token, body: body);
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
      throw AdapterException.unsupported('Codeup adapter does not implement $what yet');
}

bool _isCentralDomain(String baseUrl) {
  final host = Uri.tryParse(baseUrl)?.host ?? baseUrl;
  return host == 'openapi-rdc.aliyuncs.com';
}

String _projectIdFromRepo(Repo repo) {
  final parts = repo.id.split(':');
  if (parts.length >= 3 && parts.last.isNotEmpty) return parts.last;
  return repo.fullName;
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

bool _truthy(dynamic v) => v == true || v == 'true' || v == 'TRUE';

String? repoFullNameFromCodeupUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  var path = uri.path;
  if (path.startsWith('/')) path = path.substring(1);
  final cut = RegExp(r'/(?:change|merge_request)/(\d+)/?$');
  final match = cut.firstMatch(path);
  if (match == null) return null;
  final repo = path.substring(0, match.start);
  return repo.isEmpty ? null : repo;
}

List<ChangeRequest> parseCodeupChangeRequests(
  List<dynamic> items, {
  required String accountId,
  required bool reviewRequested,
  required bool assignedToMe,
  Map<String, String> projectIdToName = const {},
  String? fallbackRepoFullName,
}) {
  return items
      .map((e) => parseCodeupChangeRequest(
            e as Map<String, dynamic>,
            accountId: accountId,
            reviewRequested: reviewRequested,
            assignedToMe: assignedToMe,
            projectIdToName: projectIdToName,
            fallbackRepoFullName: fallbackRepoFullName,
          ))
      .toList();
}

ChangeRequest parseCodeupChangeRequest(
  Map<String, dynamic> json, {
  required String accountId,
  required bool reviewRequested,
  required bool assignedToMe,
  ChangeRequest? summary,
  Map<String, String> projectIdToName = const {},
  String? fallbackRepoFullName,
}) {
  final localId = _asInt(json['localId'] ?? json['local_id']);
  final projectId = '${json['projectId'] ?? json['targetProjectId'] ?? ''}';
  final fromUrl = repoFullNameFromCodeupUrl(json['webUrl'] as String? ?? json['detailUrl'] as String?);
  final repoFullName = blankToNull(json['targetProjectPathWithNamespace'] as String?) ??
      fromUrl ??
      projectIdToName[projectId] ??
      fallbackRepoFullName ??
      summary?.repoFullName ??
      '';
  final stateRaw = (json['state'] as String? ?? json['status'] as String? ?? 'opened').toUpperCase();
  final state = switch (stateRaw) {
    'MERGED' => CrState.merged,
    'CLOSED' => CrState.closed,
    _ => CrState.open,
  };
  final created = DateTime.tryParse(json['createdAt'] as String? ?? json['createTime'] as String? ?? '') ??
      summary?.createdAt ??
      DateTime.now().toUtc();
  final updated = DateTime.tryParse(json['updatedAt'] as String? ?? json['updateTime'] as String? ?? '') ?? created;
  final author = json['author'] as Map<String, dynamic>?;
  final conflict = json['hasConflict'] == true || json['conflictCheckStatus'] == 'HAS_CONFLICT';
  final number = localId == 0 ? (summary?.localNumber ?? 0) : localId;
  return ChangeRequest(
    id: ChangeRequest.makeId(
      platform: ForgePlatform.codeup,
      accountId: accountId,
      repoFullName: repoFullName,
      localNumber: number,
    ),
    localNumber: number,
    platform: ForgePlatform.codeup,
    accountId: accountId,
    repoFullName: repoFullName,
    title: json['title'] as String? ?? summary?.title ?? '',
    body: json['description'] as String? ?? summary?.body,
    state: state,
    sourceBranch: json['sourceBranch'] as String? ?? summary?.sourceBranch ?? '',
    targetBranch: json['targetBranch'] as String? ?? summary?.targetBranch ?? '',
    authorLogin: author?['username'] as String? ?? author?['name'] as String? ?? summary?.authorLogin ?? '',
    draft: json['workInProgress'] as bool? ?? summary?.draft ?? false,
    webUrl: json['webUrl'] as String? ?? json['detailUrl'] as String? ?? summary?.webUrl ?? '',
    updatedAt: updated.toUtc(),
    createdAt: created.toUtc(),
    reviewRequested: reviewRequested,
    assignedToMe: assignedToMe,
    mergeable: conflict ? false : (json['allRequirementsPass'] as bool? ?? (conflict ? false : summary?.mergeable)),
  );
}

ChangedFile parseCodeupChangedFile(Map<String, dynamic> json) {
  final path = json['newPath'] as String? ?? json['oldPath'] as String? ?? json['path'] as String? ?? '';
  final added = _truthy(json['newFile']);
  final deleted = _truthy(json['deletedFile']);
  final raw = json['diff'] as String? ?? json['patch'] as String?;
  final clipped = clipPatch(raw);
  return ChangedFile(
    path: path,
    status: added
        ? 'added'
        : deleted
            ? 'removed'
            : 'modified',
    additions: _asInt(json['addLines'] ?? json['additions']),
    deletions: _asInt(json['delLines'] ?? json['deletions']),
    patch: clipped.$1,
    truncated: clipped.$2 || raw == null,
  );
}

ReviewComment parseCodeupComment(Map<String, dynamic> json) {
  final created = DateTime.tryParse(json['comment_time'] as String? ?? json['last_edit_time'] as String? ?? '') ??
      DateTime.now().toUtc();
  final author = json['author'] as Map<String, dynamic>?;
  final location = json['location'] as Map<String, dynamic>?;
  return ReviewComment(
    id: json['comment_biz_id'] as String? ?? '${json['id'] ?? created.millisecondsSinceEpoch}',
    authorLogin: author?['username'] as String? ?? author?['name'] as String? ?? '',
    body: json['content'] as String? ?? '',
    path: json['filePath'] as String? ?? location?['located_file_path'] as String?,
    line: json['line_number'] as int? ?? location?['located_line_number'] as int?,
    createdAt: created.toUtc(),
  );
}

Repo parseCodeupRepo(Map<String, dynamic> json, String accountId) {
  final updated = DateTime.tryParse(json['lastActivityAt'] as String? ?? json['updatedAt'] as String? ?? '') ??
      DateTime.now().toUtc();
  final visibility = parseRepoVisibility(raw: json['visibility'] as String? ?? 'private');
  final created = DateTime.tryParse(json['createdAt'] as String? ?? json['gmtCreate'] as String? ?? '');
  return Repo(
    id: 'codeup:$accountId:${json['id']}',
    platform: ForgePlatform.codeup,
    accountId: accountId,
    fullName: json['pathWithNamespace'] as String? ?? json['path'] as String? ?? '',
    webUrl: json['webUrl'] as String? ?? '',
    private: visibility != RepoVisibility.public,
    // ListRepositories has no default branch; Codeup orgs often still use master.
    defaultBranch: json['defaultBranch'] as String? ?? 'master',
    updatedAt: updated.toUtc(),
    description: blankToNull(json['description'] as String?),
    language: null,
    starCount: _asInt(json['starCount']),
    forkCount: _asInt(json['forkCount']),
    openIssueCount: 0,
    // Codeup ListRepositories payload only carries webUrl; clone URLs aren't
    // returned in the list call and would require a per-repo fetch. Leave null
    // so the UI hides the copy row.
    cloneUrl: blankToNull(json['httpsUrl'] as String?),
    sshUrl: blankToNull(json['sshUrl'] as String?),
    watchersCount: _asInt(json['starCount']),
    createdAt: created?.toUtc(),
    archived: json['archived'] == true,
    fork: json['isFork'] == true || json['fork'] == true,
    visibility: visibility,
  );
}
