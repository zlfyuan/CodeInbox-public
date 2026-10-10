import 'dart:convert';

import 'package:codeinbox/data/adapters/github_adapter.dart';
import 'package:codeinbox/data/http_client.dart';
import 'package:codeinbox/data/patch_codec.dart';
import 'package:codeinbox/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

import 'support.dart';

void main() {
  test('parseGithubSearchItems maps review-requested PRs', () {
    final json = loadFixture('github_search_prs.json') as Map<String, dynamic>;
    final items = parseGithubSearchItems(
      json['items'] as List<dynamic>,
      accountId: 'a',
      reviewRequested: true,
      assignedToMe: false,
    );
    expect(items, hasLength(1));
    final pr = items.single;
    expect(pr.reviewRequested, isTrue);
    expect(pr.webUrl, 'https://github.com/acme/box/pull/12');
    expect(pr.id, 'github:a:acme/box:12');
    expect(pr.repoFullName, 'acme/box');
    expect(pr.title, 'Fix inbox merge');
    expect(pr.authorLogin, 'alice');
  });

  test('repoFullNameFromGithubApiUrl', () {
    expect(
      repoFullNameFromGithubApiUrl('https://api.github.com/repos/acme/box'),
      'acme/box',
    );
  });

  test('parseGithubPull maps detail fields', () {
    final json = loadFixture('github_pr.json') as Map<String, dynamic>;
    final pr = parseGithubPull(json, accountId: 'a');
    expect(pr.title, 'Fix inbox merge');
    expect(pr.body, 'Please review this change.');
    expect(pr.sourceBranch, 'feat-inbox');
    expect(pr.targetBranch, 'main');
    expect(pr.mergeable, isTrue);
    expect(pr.webUrl, 'https://github.com/acme/box/pull/12');
    expect(pr.owner, 'acme');
    expect(pr.repoName, 'box');
    expect(pr.headSha, 'abc123');
    expect(pr.baseSha, 'def456');
  });

  test('parseGithubFile keeps a short patch', () {
    final json = loadFixture('github_pr_files.json') as List<dynamic>;
    final file = parseGithubFile(json.first as Map<String, dynamic>);
    expect(file.path, 'lib/domain/inbox.dart');
    expect(file.hasPatch, isTrue);
    expect(file.additions, 4);
    expect(file.truncated, isFalse);
  });

  test('parseGithubComment maps line comments', () {
    final json = loadFixture('github_pr_comments.json') as List<dynamic>;
    final comment = parseGithubComment(json.first as Map<String, dynamic>);
    expect(comment.authorLogin, 'bob');
    expect(comment.path, 'lib/domain/inbox.dart');
    expect(comment.line, 12);
  });

  test('parseGithubNotification converts pulls API url to html', () {
    final item = parseGithubNotification({
      'id': 'n1',
      'unread': true,
      'reason': 'review_requested',
      'updated_at': '2026-09-14T08:00:00Z',
      'subject': {
        'title': 'Fix inbox merge',
        'url': 'https://api.github.com/repos/acme/box/pulls/12',
        'type': 'PullRequest',
      },
      'repository': {
        'full_name': 'acme/box',
        'html_url': 'https://github.com/acme/box',
      },
    }, 'a');
    expect(item.webUrl, 'https://github.com/acme/box/pull/12');
    expect(item.reason, 'review_requested');
    expect(item.opensDetail, isTrue);
    expect(item.repoFullName, 'acme/box');
    expect(item.localNumber, 12);
    expect(item.toChangeRequest()?.id, 'github:a:acme/box:12');
  });

  test('parseGithubNotification treats Issue urls as in-app PRs', () {
    final item = parseGithubNotification({
      'id': 'n2',
      'unread': true,
      'reason': 'comment',
      'updated_at': '2026-09-14T08:00:00Z',
      'subject': {
        'title': 'Please look',
        'url': 'https://api.github.com/repos/acme/box/issues/12',
        'type': 'Issue',
      },
      'repository': {
        'full_name': 'acme/box',
        'html_url': 'https://github.com/acme/box',
      },
    }, 'a');
    expect(item.opensDetail, isTrue);
    expect(item.localNumber, 12);
    expect(item.repoFullName, 'acme/box');
  });

  test('parseGithubRepo maps description language stars', () {
    final repo = parseGithubRepo({
      'id': 1,
      'full_name': 'acme/box',
      'html_url': 'https://github.com/acme/box',
      'clone_url': 'https://github.com/acme/box.git',
      'ssh_url': 'git@github.com:acme/box.git',
      'private': false,
      'default_branch': 'main',
      'updated_at': '2026-09-14T00:00:00Z',
      'description': 'Inbox for reviews',
      'language': 'Dart',
      'stargazers_count': 3,
      'forks_count': 1,
      'open_issues_count': 4,
      'watchers_count': 5,
      'subscribers_count': 2,
      'license': {'spdx_id': 'MIT'},
      'homepage': 'https://example.com',
      'created_at': '2026-09-01T00:00:00Z',
      'topics': ['inbox', 'flutter'],
      'visibility': 'public',
    }, 'a');
    expect(repo.description, 'Inbox for reviews');
    expect(repo.language, 'Dart');
    expect(repo.starCount, 3);
    expect(repo.forkCount, 1);
    expect(repo.openIssueCount, 4);
    expect(repo.license, 'MIT');
    expect(repo.topics, ['inbox', 'flutter']);
    expect(repo.private, isFalse);
    expect(repo.visibility, RepoVisibility.public);
    expect(repo.cloneUrl, 'https://github.com/acme/box.git');
    expect(repo.sshUrl, 'git@github.com:acme/box.git');
    expect(repo.watchersCount, 5);
    expect(repo.subscribersCount, 2);
  });

  test('getReadme decodes the GitHub readme payload', () async {
    final client = MockClient((req) async {
      expect(req.url.path, '/repos/acme/box/readme');
      return Response(
        jsonEncode({
          'encoding': 'base64',
          'content': base64.encode(utf8.encode('# Inbox\n')),
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final adapter = GithubAdapter(http: ForgeHttp(client: client));
    final text = await adapter.getReadme(account: sampleAccount(), token: 'ghs', repo: sampleRepo());
    expect(text, '# Inbox\n');
  });

  test('submitReview posts inline comment with path line commit_id', () async {
    Map<String, dynamic>? body;
    String? path;
    final client = MockClient((req) async {
      if (req.method == 'POST' && req.url.path.endsWith('/pulls/12/comments')) {
        path = req.url.path;
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return Response('{}', 201, headers: {'content-type': 'application/json'});
      }
      return Response('nope', 404);
    });
    final adapter = GithubAdapter(http: ForgeHttp(client: client));
    await adapter.submitReview(
      account: sampleAccount(),
      token: 'ghs',
      cr: samplePr().copyWith(headSha: 'abc123'),
      action: const ReviewAction(
        type: ReviewType.comment,
        body: 'nits',
        path: 'lib/domain/inbox.dart',
        line: 12,
      ),
    );
    expect(path, '/repos/acme/box/pulls/12/comments');
    expect(body?['path'], 'lib/domain/inbox.dart');
    expect(body?['line'], 12);
    expect(body?['side'], 'RIGHT');
    expect(body?['commit_id'], 'abc123');
    expect(body?['body'], 'nits');
  });

  test('parseRawDiffIntoPatches extracts hunks per file and skips binary', () {
    // Realistic `.diff` payload: small text file, large binary, rename.
    final raw = '''diff --git a/lib/a.dart b/lib/a.dart
index 111..222 100644
--- a/lib/a.dart
+++ b/lib/a.dart
@@ -1,3 +1,3 @@
 int x = 1;
-int y = 2;
+int y = 3;
 int z = 4;
diff --git a/assets/logo.png b/assets/logo.png
index aaa..bbb 100644
Binary files a/assets/logo.png and b/assets/logo.png differ
diff --git a/old/name.txt b/new/name.txt
similarity index 95%
rename from old/name.txt
rename to new/name.txt
--- a/old/name.txt
+++ b/new/name.txt
@@ -1,2 +1,2 @@
 keep
-change
+changes
''';
    final patches = parseRawDiffIntoPatches(raw);
    expect(patches.keys, containsAll(['lib/a.dart', 'new/name.txt']));
    expect(patches.containsKey('assets/logo.png'), isFalse);
    expect(patches['lib/a.dart'], contains('+int y = 3;'));
    expect(patches['lib/a.dart'], contains('-int y = 2;'));
    // 重命名用新路径 `new/name.txt`,不是旧路径。
    expect(patches['new/name.txt'], contains('+changes'));
  });

  test('listFiles recovers patches from .diff when API omits them', () async {
    // /files API 返回两条记录:大文件 patch=null,小文件 patch 正常。
    final mock = MockClient((req) async {
      if (req.url.path == '/repos/acme/box/pulls/12/files') {
        return Response(
          jsonEncode([
            {
              'filename': 'big/file.dart',
              'status': 'modified',
              'additions': 999,
              'deletions': 999,
              'patch': null,
            },
            {
              'filename': 'small/file.dart',
              'status': 'modified',
              'additions': 1,
              'deletions': 1,
              'patch': '@@ -1 +1 @@\n-old\n+new',
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (req.url.toString() == 'https://github.com/acme/box/pull/12.diff') {
        return Response(
          'diff --git a/big/file.dart b/big/file.dart\n--- a/big/file.dart\n+++ b/big/file.dart\n@@ -1,3 +1,3 @@\n a\n-b\n+B\n',
          200,
          headers: {'content-type': 'text/plain'},
        );
      }
      return Response('not found', 404);
    });
    final adapter = GithubAdapter(http: ForgeHttp(client: mock));
    final pr = ChangeRequest(
      id: 'github:a:acme/box:12',
      localNumber: 12,
      platform: ForgePlatform.github,
      accountId: 'a',
      repoFullName: 'acme/box',
      title: 'test',
      authorLogin: 'alice',
      webUrl: 'https://github.com/acme/box/pull/12',
      updatedAt: DateTime.utc(2026, 9, 14),
      createdAt: DateTime.utc(2026, 9, 1),
    );
    final files = await adapter.listFiles(
      account: sampleAccount(),
      token: 'ghs_test',
      cr: pr,
    );
    expect(files, hasLength(2));
    final big = files.firstWhere((f) => f.path == 'big/file.dart');
    expect(big.hasPatch, isTrue);
    expect(big.patch, contains('+B'));
    expect(big.truncated, isFalse);
    final small = files.firstWhere((f) => f.path == 'small/file.dart');
    // API patch 原样保留,没被 raw diff 覆盖(原 patch 已含 `@@` hunk header)。
    expect(small.patch, contains('+new'));
    expect(small.patch, contains('-old'));
  });

  test('listFiles keeps original null patch when .diff fetch fails', () async {
    final mock = MockClient((req) async {
      if (req.url.path == '/repos/acme/box/pulls/12/files') {
        return Response(
          jsonEncode([
            {
              'filename': 'big/file.dart',
              'status': 'modified',
              'additions': 1,
              'deletions': 1,
              'patch': null,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (req.url.toString() == 'https://github.com/acme/box/pull/12.diff') {
        return Response('boom', 500);
      }
      return Response('not found', 404);
    });
    final adapter = GithubAdapter(http: ForgeHttp(client: mock));
    final pr = ChangeRequest(
      id: 'github:a:acme/box:12',
      localNumber: 12,
      platform: ForgePlatform.github,
      accountId: 'a',
      repoFullName: 'acme/box',
      title: 'test',
      authorLogin: 'alice',
      webUrl: 'https://github.com/acme/box/pull/12',
      updatedAt: DateTime.utc(2026, 9, 14),
      createdAt: DateTime.utc(2026, 9, 1),
    );
    final files = await adapter.listFiles(
      account: sampleAccount(),
      token: 'ghs_test',
      cr: pr,
    );
    expect(files.single.hasPatch, isFalse);
  });
}
