import 'package:uuid/uuid.dart';

import '../../domain/forge_adapter.dart';
import '../../domain/inbox.dart';
import '../../domain/models.dart';
import '../../domain/refs.dart';
import '../http_client.dart';
import '../patch_codec.dart';
import '../readme_codec.dart';

const codingInboxProjectLimit = 20;

String codingTokenSettingsUrl(String? baseUrl) {
  final base = codingTeamBase(baseUrl);
  if (base.isEmpty) return 'https://coding.net/help/docs/member/tokens.html';
  return '$base/user/account';
}

String codingTeamBase(String? raw) {
  var s = normalizeForgeBaseUrl(raw) ?? '';
  if (s.endsWith('/open-api')) s = s.substring(0, s.length - 9);
  return s;
}

String? codingTeamSlug(String? baseUrl) {
  final host = Uri.tryParse(codingTeamBase(baseUrl))?.host;
  if (host == null || !host.endsWith('.coding.net')) return null;
  final slug = host.substring(0, host.length - '.coding.net'.length);
  if (slug.isEmpty || slug == 'e' || slug == 'www') return null;
  return slug;
}

Uri codingApiUri(String? baseUrl, String action) {
  final base = codingTeamBase(baseUrl);
  return Uri.parse('$base/open-api').replace(queryParameters: {'Action': action});
}

class CodingAdapter implements ForgeAdapter {
  CodingAdapter({ForgeHttp? http, Uuid? uuid})
      : _http = http ?? ForgeHttp(),
        _uuid = uuid ?? const Uuid();

  final ForgeHttp _http;
  final Uuid _uuid;

  @override
  ForgePlatform get platform => ForgePlatform.coding;

  @override
  Set<ReviewType> get supportedReviews => const {
        ReviewType.comment,
        ReviewType.approve,
        ReviewType.requestChanges,
        ReviewType.merge,
      };

  @override
  Set<RepoCapability> get supportedCapabilities => const {
        // CODING has no separate Issue tracker; merge requests cover most of
        // the review surface. B-batch only fills out PR/MR for CODING.
      };

  Map<String, String> _headers(String token) => {'Authorization': 'token $token'};

  Future<Map<String, dynamic>> _action(
    PlatformAccount account,
    String token,
    String action, [
    Map<String, dynamic> body = const {},
  ]) {
    return _actionAt(account.baseUrl, token, action, body);
  }

  Future<Map<String, dynamic>> _actionAt(
    String? baseUrl,
    String token,
    String action, [
    Map<String, dynamic> body = const {},
  ]) async {
    final json = await _http.postJson(
      codingApiUri(baseUrl, action),
      token: token,
      headers: _headers(token),
      body: {'Action': action, ...body},
    );
    return unwrapCoding(json);
  }

  @override
  Future<PlatformAccount> verifyAndProfile({
    required String token,
    String? displayName,
    String? baseUrl,
    String? orgId,
  }) async {
    final normalized = codingTeamBase(baseUrl);
    if (normalized.isEmpty || !normalized.contains('coding.net')) {
      throw AdapterException.http(422, 'Set your team URL (https://your-team.coding.net)');
    }
    final json = await _actionAt(normalized, token, 'DescribeCodingCurrentUser');
    final user = json['User'] as Map<String, dynamic>? ?? json;
    final login = user['GlobalKey'] as String? ?? user['Name'] as String? ?? '';
    final name = user['Name'] as String?;
    return PlatformAccount(
      id: _uuid.v4(),
      platform: ForgePlatform.coding,
      login: login,
      displayName: (displayName != null && displayName.trim().isNotEmpty)
          ? displayName.trim()
          : (name?.trim().isNotEmpty == true ? name!.trim() : login),
      avatarUrl: user['Avatar'] as String? ?? user['AvatarUrl'] as String?,
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
    final user = await _action(account, token, 'DescribeCodingCurrentUser');
    final me = user['User'] as Map<String, dynamic>? ?? user;
    final userId = _asInt(me['Id']);
    final projects = await _listProjects(account, token);
    final chunks = await Future.wait(projects.map((project) async {
      try {
        final json = await _action(account, token, 'DescribeProjectMergeRequests', {
          'ProjectName': project.name,
          'Status': 'open',
          'PageNumber': page,
          'PageSize': 20,
        });
        return parseCodingMrs(
          codingList(json, const ['MergeRequestList', 'MergeRequestInfoList', 'List']),
          accountId: account.id,
          projectName: project.name,
          webBase: codingTeamBase(account.baseUrl),
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
    // No notification inbox; AppStore synthesizes Alerts from open MRs.
    return const [];
  }

  @override
  Future<List<Repo>> listRepos({
    required PlatformAccount account,
    required String token,
  }) async {
    final projects = await _listProjects(account, token);
    final repos = <Repo>[];
    for (final project in projects) {
      if (repos.length >= codingInboxProjectLimit) break;
      try {
        final json = await _action(account, token, 'DescribeProjectDepots', {
          'ProjectId': project.id,
          'DepotType': 'CODING',
        });
        final depots = codingList(json, const ['DepotList', 'List']);
        for (final raw in depots) {
          if (raw is! Map<String, dynamic>) continue;
          repos.add(parseCodingDepot(raw, account.id, project.name));
          if (repos.length >= codingInboxProjectLimit) break;
        }
      } on AdapterException {
        continue;
      }
    }
    return repos;
  }

  @override
  Future<String?> getReadme({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) {
    final team = codingTeamSlug(account.baseUrl) ?? '';
    final depotPath = '$team/${repo.fullName}';
    return firstReadme((name) {
      return _action(account, token, 'DescribeGitFile', {
        'DepotPath': depotPath,
        'Path': name,
        'Ref': repo.defaultBranch,
      });
    });
  }

  @override
  Future<List<ChangeRequest>> listOpenChangeRequests({
    required PlatformAccount account,
    required String token,
    required Repo repo,
  }) async {
    final parts = repo.fullName.split('/');
    final projectName = parts.isNotEmpty ? parts.first : repo.fullName;
    final depotName = parts.length > 1 ? parts.sublist(1).join('/') : repo.fullName;
    final json = await _action(account, token, 'DescribeProjectMergeRequests', {
      'ProjectName': projectName,
      'DepotName': depotName,
      'Status': 'open',
      'PageNumber': 1,
      'PageSize': 50,
    });
    return parseCodingMrs(
      codingList(json, const ['MergeRequestList', 'MergeRequestInfoList', 'List']),
      accountId: account.id,
      projectName: projectName,
      fallbackDepotName: depotName,
      fallbackDepotId: _depotIdFromRepo(repo),
      webBase: codingTeamBase(account.baseUrl),
    );
  }

  @override
  Future<ChangeRequest> getChangeRequest({
    required PlatformAccount account,
    required String token,
    required ChangeRequest summary,
  }) async {
    final ids = _ids(summary);
    final json = await _action(account, token, 'DescribeMergeRequest', {
      'DepotId': ids.depotId,
      'IId': summary.localNumber,
    });
    final raw = json['MergeRequest'] as Map<String, dynamic>? ?? json;
    return parseCodingMr(
      raw,
      accountId: account.id,
      projectName: _projectName(summary.repoFullName),
      fallbackDepotName: _depotName(summary.repoFullName),
      fallbackDepotId: ids.depotId,
      webBase: codingTeamBase(account.baseUrl),
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
      final ids = _ids(cr);
      final json = await _action(account, token, 'DescribeMergeRequestFileDiff', {
        'DepotId': ids.depotId,
        'MergeId': ids.mergeId,
      });
      final files = codingList(json, const ['Files', 'Diffs', 'FileDiffs', 'List'])
          .whereType<Map<String, dynamic>>()
          .map(parseCodingDiff)
          .toList();
      if (cr.webUrl.isEmpty) return files;
      return recoverPatches(
        files: files,
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
      final path = _depotPath(account, cr);
      final json = await _action(account, token, 'DescribeSingeMergeRequestNotes', {
        'DepotPath': path,
        'MergeId': cr.localNumber,
      });
      final comments = codingList(json, const ['Notes', 'NoteList', 'List'])
          .whereType<Map<String, dynamic>>()
          .map(parseCodingNote)
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
    final ids = _ids(cr);
    switch (action.type) {
      case ReviewType.merge:
        await _action(account, token, 'ModifyMergeMR', {
          'DepotId': ids.depotId,
          'MergeId': ids.mergeId,
          'CommitMessage':
              (action.body?.trim().isNotEmpty == true) ? action.body!.trim() : 'Merged via CodeInbox',
        });
      case ReviewType.comment:
        final text = action.body?.trim() ?? '';
        if (text.isEmpty) {
          throw AdapterException.http(422, 'Comment body is required');
        }
        await _action(account, token, 'CreateMergeRequestNote', {
          'DepotPath': _depotPath(account, cr),
          'MergeId': cr.localNumber,
          'Content': text,
          'ParentId': 0,
          if (action.isInline) 'Path': action.path,
          if (action.line != null) 'Line': action.line,
        });
      case ReviewType.approve:
      case ReviewType.requestChanges:
        // Code-hosting OpenAPI; Action name not live-verified with a real token.
        await _action(account, token, 'ModifyGitMergeRequestReview', {
          'DepotId': ids.depotId,
          'MergeId': ids.mergeId,
          'ReviewerState': action.type == ReviewType.approve ? 'ACCEPT' : 'REJECT',
          if (action.body?.trim().isNotEmpty == true) 'Content': action.body!.trim(),
        });
    }
  }

  Future<List<_CodingProject>> _listProjects(PlatformAccount account, String token) async {
    final json = await _action(account, token, 'DescribeCodingProjects', {
      'PageNumber': 1,
      'PageSize': codingInboxProjectLimit,
    });
    return codingList(json, const ['ProjectList', 'Projects', 'List'])
        .whereType<Map<String, dynamic>>()
        .map(_CodingProject.fromJson)
        .where((p) => p.id > 0 && p.name.isNotEmpty)
        .take(codingInboxProjectLimit)
        .toList();
  }

  _CodingIds _ids(ChangeRequest cr) {
    final parts = cr.id.split(':');
    if (parts.length >= 4 && parts[0] == 'coding') {
      return _CodingIds(depotId: int.tryParse(parts[2]) ?? 0, mergeId: int.tryParse(parts[3]) ?? 0);
    }
    return _CodingIds(depotId: 0, mergeId: 0);
  }

  int _depotIdFromRepo(Repo repo) {
    final parts = repo.id.split(':');
    if (parts.length >= 3) return int.tryParse(parts.last) ?? 0;
    return 0;
  }

  String _projectName(String fullName) {
    final i = fullName.indexOf('/');
    return i <= 0 ? fullName : fullName.substring(0, i);
  }

  String _depotName(String fullName) {
    final i = fullName.indexOf('/');
    return i < 0 ? fullName : fullName.substring(i + 1);
  }

  String _depotPath(PlatformAccount account, ChangeRequest cr) {
    final team = codingTeamSlug(account.baseUrl) ?? '';
    return '$team/${cr.repoFullName}';
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
      throw AdapterException.unsupported('CODING adapter does not implement $what yet');
}

class _CodingProject {
  const _CodingProject({required this.id, required this.name});

  final int id;
  final String name;

  factory _CodingProject.fromJson(Map<String, dynamic> json) => _CodingProject(
        id: _asInt(json['Id'] ?? json['id'] ?? json['ProjectId']),
        name: json['Name'] as String? ?? json['ProjectName'] as String? ?? '',
      );
}

class _CodingIds {
  const _CodingIds({required this.depotId, required this.mergeId});

  final int depotId;
  final int mergeId;
}

Map<String, dynamic> unwrapCoding(dynamic json) {
  if (json is! Map<String, dynamic>) {
    throw const FormatException('Expected object from CODING');
  }
  final response = json['Response'] as Map<String, dynamic>? ?? json;
  final error = response['Error'];
  if (error is Map) {
    final code = error['Code']?.toString() ?? '';
    final message = error['Message']?.toString() ?? code;
    if (code.contains('Auth') || code.contains('Unauthorized') || code == '401') {
      throw AdapterException.unauthorized();
    }
    throw AdapterException.http(400, message);
  }
  return response;
}

List<dynamic> codingList(Map<String, dynamic> response, List<String> keys) {
  for (final key in keys) {
    final v = response[key];
    if (v is List) return v;
  }
  final data = response['Data'];
  if (data is Map<String, dynamic>) {
    for (final key in keys) {
      final v = data[key];
      if (v is List) return v;
    }
    try {
      return jsonAsList(data);
    } on FormatException {
      return const [];
    }
  }
  if (data is List) return data;
  try {
    return jsonAsList(response);
  } on FormatException {
    return const [];
  }
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

int? _userId(dynamic raw) {
  if (raw is Map) return _asInt(raw['Id'] ?? raw['id'] ?? raw['UserId']);
  return null;
}

List<int> _userIds(dynamic raw) {
  if (raw is Map) {
    final id = _userId(raw);
    return id != null && id > 0 ? [id] : const [];
  }
  if (raw is List) {
    return [for (final item in raw) ..._userIds(item)];
  }
  return const [];
}

List<ChangeRequest> parseCodingMrs(
  List<dynamic> items, {
  required String accountId,
  required String projectName,
  required String webBase,
  String? fallbackDepotName,
  int? fallbackDepotId,
  int? currentUserId,
}) {
  return items
      .map((e) => parseCodingMr(
            e as Map<String, dynamic>,
            accountId: accountId,
            projectName: projectName,
            webBase: webBase,
            fallbackDepotName: fallbackDepotName,
            fallbackDepotId: fallbackDepotId,
            currentUserId: currentUserId,
          ))
      .toList();
}

ChangeRequest parseCodingMr(
  Map<String, dynamic> json, {
  required String accountId,
  required String projectName,
  required String webBase,
  String? fallbackDepotName,
  int? fallbackDepotId,
  int? currentUserId,
  bool reviewRequested = false,
  bool assignedToMe = false,
  ChangeRequest? summary,
}) {
  final iid = _asInt(json['IId'] ?? json['Iid'] ?? json['iid'] ?? json['MergeIid']);
  final mergeId = _asInt(json['Id'] ?? json['id'] ?? json['MergeId']);
  final depotId = _asInt(json['DepotId'] ?? json['depot_id']) > 0
      ? _asInt(json['DepotId'] ?? json['depot_id'])
      : (fallbackDepotId ?? 0);
  final depotName = json['DepotName'] as String? ?? fallbackDepotName ?? summary?.repoFullName.split('/').last ?? '';
  final repoFullName = [
    projectName.isNotEmpty ? projectName : _projectFromSummary(summary),
    depotName,
  ].where((s) => s.isNotEmpty).join('/');
  final number = iid > 0 ? iid : (summary?.localNumber ?? mergeId);
  final status = (json['Status'] as String? ?? json['status'] as String? ?? 'open').toLowerCase();
  final state = switch (status) {
    'merged' || 'accepted' || 'accept' => CrState.merged,
    'closed' || 'refused' || 'refuse' || 'declined' => CrState.closed,
    _ => CrState.open,
  };
  final created = DateTime.tryParse(json['CreatedAt'] as String? ?? json['CreateTime'] as String? ?? '') ??
      summary?.createdAt ??
      DateTime.now().toUtc();
  final updated = DateTime.tryParse(json['UpdatedAt'] as String? ?? json['UpdateTime'] as String? ?? '') ?? created;
  final author = json['Author'] as Map<String, dynamic>? ?? json['author'] as Map<String, dynamic>?;
  final assigneeId = _userId(json['Assignee'] ?? json['acceptor'] ?? json['Acceptor']);
  final reviewerIds = [
    ..._userIds(json['Reviewers'] ?? json['reviewers']),
    ..._userIds(json['Reviewer'] ?? json['reviewer']),
  ];
  final assigned = currentUserId != null && currentUserId > 0 && assigneeId == currentUserId;
  final reviewing = currentUserId != null && currentUserId > 0 && reviewerIds.contains(currentUserId);
  final host = webBase.endsWith('/') ? webBase.substring(0, webBase.length - 1) : webBase;
  final fallbackUrl = repoFullName.isEmpty ? '' : '$host/p/${repoFullName.split('/').first}/d/$depotName/git/merge/$number';
  final mergeable = status == 'canmerge' || json['Mergeable'] == true;
  return ChangeRequest(
    id: 'coding:$accountId:$depotId:$mergeId',
    localNumber: number,
    platform: ForgePlatform.coding,
    accountId: accountId,
    repoFullName: repoFullName.isNotEmpty ? repoFullName : (summary?.repoFullName ?? ''),
    title: json['Title'] as String? ?? json['title'] as String? ?? summary?.title ?? '',
    body: json['Content'] as String? ?? json['Body'] as String? ?? json['body'] as String? ?? summary?.body,
    state: state,
    sourceBranch: json['SrcBranch'] as String? ?? json['SourceBranch'] as String? ?? summary?.sourceBranch ?? '',
    targetBranch: json['DestBranch'] as String? ?? json['TargetBranch'] as String? ?? summary?.targetBranch ?? '',
    authorLogin: author?['GlobalKey'] as String? ?? author?['Name'] as String? ?? summary?.authorLogin ?? '',
    webUrl: json['WebUrl'] as String? ?? json['Url'] as String? ?? summary?.webUrl ?? fallbackUrl,
    updatedAt: updated.toUtc(),
    createdAt: created.toUtc(),
    reviewRequested: reviewing || reviewRequested,
    assignedToMe: assigned || assignedToMe,
    mergeable: mergeable ? true : (json['Mergeable'] == false ? false : summary?.mergeable),
  );
}

String _projectFromSummary(ChangeRequest? summary) {
  final name = summary?.repoFullName ?? '';
  final i = name.indexOf('/');
  return i <= 0 ? name : name.substring(0, i);
}

ChangedFile parseCodingDiff(Map<String, dynamic> json) {
  final path = json['Path'] as String? ?? json['NewPath'] as String? ?? json['path'] as String? ?? '';
  final raw = json['Diff'] as String? ?? json['Patch'] as String? ?? json['diff'] as String?;
  final clipped = clipPatch(raw);
  final status = json['ChangeType'] as String? ?? json['Status'] as String? ?? '';
  final added = status.toLowerCase() == 'add' || json['NewFile'] == true;
  final deleted = status.toLowerCase() == 'delete' || json['DeletedFile'] == true;
  return ChangedFile(
    path: path,
    status: added
        ? 'added'
        : deleted
            ? 'removed'
            : 'modified',
    additions: _asInt(json['Additions'] ?? json['additions']),
    deletions: _asInt(json['Deletions'] ?? json['deletions']),
    patch: clipped.$1,
    truncated: clipped.$2 || raw == null,
  );
}

ReviewComment parseCodingNote(Map<String, dynamic> json) {
  final created = DateTime.tryParse(json['CreatedAt'] as String? ?? json['CreateTime'] as String? ?? '') ??
      DateTime.now().toUtc();
  final author = json['Author'] as Map<String, dynamic>? ?? json['User'] as Map<String, dynamic>?;
  return ReviewComment(
    id: '${json['Id'] ?? json['id'] ?? created.millisecondsSinceEpoch}',
    authorLogin: author?['GlobalKey'] as String? ?? author?['Name'] as String? ?? json['AuthorName'] as String? ?? '',
    body: json['Content'] as String? ?? json['Note'] as String? ?? json['body'] as String? ?? '',
    path: json['Path'] as String? ?? json['FilePath'] as String?,
    line: json['Line'] as int? ?? json['LineNumber'] as int?,
    createdAt: created.toUtc(),
  );
}

Repo parseCodingDepot(Map<String, dynamic> json, String accountId, String projectName) {
  final name = json['Name'] as String? ?? json['DepotName'] as String? ?? '';
  final updated = DateTime.tryParse(json['UpdatedAt'] as String? ?? json['LastPushAt'] as String? ?? '') ??
      DateTime.now().toUtc();
  final visibility = parseRepoVisibility(
    privateFlag: json['IsPrivate'] == true || json['Public'] == false,
  );
  final created = DateTime.tryParse(json['CreatedAt'] as String? ?? json['Created'] as String? ?? '');
  return Repo(
    id: 'coding:$accountId:${json['Id'] ?? json['DepotId']}',
    platform: ForgePlatform.coding,
    accountId: accountId,
    fullName: '$projectName/$name',
    webUrl: json['DepotHttpsUrl'] as String? ?? json['HttpsUrl'] as String? ?? json['WebUrl'] as String? ?? '',
    private: visibility != RepoVisibility.public,
    defaultBranch: json['DefaultBranch'] as String? ?? 'master',
    updatedAt: updated.toUtc(),
    description: blankToNull(json['Description'] as String?),
    language: blankToNull(json['Language'] as String?),
    starCount: _asInt(json['StarCount'] ?? json['StarsCount']),
    forkCount: _asInt(json['ForkCount'] ?? json['ForksCount']),
    // CODING list response: the only HTTPS clone URL is DepotHttpsUrl. WebUrl
    // is the project page (different from a clone URL). Don't reuse the web
    // URL as a clone URL — let the UI's "copy web URL" row handle that.
    cloneUrl: blankToNull(json['DepotHttpsUrl'] as String?),
    // sshUrl stays null — the CODING list response has no SSH field, and we
    // don't want to fake a git@... string without server confirmation.
    watchersCount: _asInt(json['StarCount'] ?? json['StarsCount']),
    createdAt: created?.toUtc(),
    archived: json['Archived'] == true,
    fork: json['IsFork'] == true,
    visibility: visibility,
  );
}
