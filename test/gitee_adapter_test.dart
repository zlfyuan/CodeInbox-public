import 'dart:convert';

import 'package:codeinbox/data/adapters/gitee_adapter.dart';
import 'package:codeinbox/data/http_client.dart';
import 'package:codeinbox/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

import 'support.dart';

void main() {
  test('parseGiteePull maps assignee PRs', () {
    final json = loadFixture('gitee_prs.json') as List<dynamic>;
    final pr = parseGiteePull(json.first as Map<String, dynamic>, accountId: 'b', repoFullName: 'acme/box');
    expect(pr.id, 'gitee:b:acme/box:7');
    expect(pr.title, 'Add adapter');
    expect(pr.webUrl, 'https://gitee.com/acme/box/pulls/7');
    expect(pr.sourceBranch, 'feat');
    expect(pr.reviewRequested, isTrue);
    expect(pr.assignedToMe, isTrue);
  });

  test('parseGiteeFile accepts diff field', () {
    final json = loadFixture('gitee_pr_files.json') as List<dynamic>;
    final file = parseGiteeFile(json.first as Map<String, dynamic>);
    expect(file.path, 'lib/store.dart');
    expect(file.hasPatch, isTrue);
    expect(file.patch, contains('void refresh()'));
  });

  test('listInbox fans out to at most 20 repos', () async {
    final pullPaths = <String>[];
    final repos = List.generate(25, (i) {
      return {
        'id': i,
        'full_name': 'org/repo$i',
        'html_url': 'https://gitee.com/org/repo$i',
        'private': false,
        'default_branch': 'master',
        'updated_at': '2026-09-01T00:00:00Z',
      };
    });
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/user/repos')) {
        return Response(jsonEncode(repos), 200, headers: {'content-type': 'application/json'});
      }
      if (req.url.path.contains('/pulls')) {
        pullPaths.add(req.url.path);
        return Response('[]', 200, headers: {'content-type': 'application/json'});
      }
      return Response('nope', 404);
    });
    final adapter = GiteeAdapter(http: ForgeHttp(client: client));
    final account = sampleAccount(id: 'b', platform: ForgePlatform.gitee, login: 'coder');
    await adapter.listInbox(account: account, token: 'ghs_test_***');
    expect(pullPaths, hasLength(giteeInboxRepoLimit));
  });

  test('parseGiteeRepo maps description language stars', () {
    final repo = parseGiteeRepo({
      'id': 7,
      'full_name': 'acme/box',
      'html_url': 'https://gitee.com/acme/box',
      'https_url': 'https://gitee.com/acme/box.git',
      'ssh_url': 'git@gitee.com:acme/box.git',
      'private': false,
      'default_branch': 'master',
      'updated_at': '2026-09-14T00:00:00Z',
      'description': 'Inbox for reviews',
      'language': 'Dart',
      'stargazers_count': 3,
      'forks_count': 1,
      'open_issues_count': 4,
      'watchers_count': 5,
      'subscribers_count': 2,
      'license': 'MIT',
      'homepage': 'https://example.com',
      'created_at': '2026-09-01T00:00:00Z',
    }, 'b');
    expect(repo.description, 'Inbox for reviews');
    expect(repo.language, 'Dart');
    expect(repo.starCount, 3);
    expect(repo.forkCount, 1);
    expect(repo.openIssueCount, 4);
    expect(repo.license, 'MIT');
    expect(repo.cloneUrl, 'https://gitee.com/acme/box.git');
    expect(repo.sshUrl, 'git@gitee.com:acme/box.git');
    expect(repo.watchersCount, 5);
    expect(repo.subscribersCount, 2);
  });

  test('submitReview comment sends path and position', () async {
    Map<String, dynamic>? body;
    final client = MockClient((req) async {
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return Response('{}', 201, headers: {'content-type': 'application/json'});
    });
    final adapter = GiteeAdapter(http: ForgeHttp(client: client));
    await adapter.submitReview(
      account: sampleAccount(id: 'b', platform: ForgePlatform.gitee, login: 'coder'),
      token: 'tok',
      cr: samplePr(id: 'gitee:b:acme/box:7', number: 7, platform: ForgePlatform.gitee, accountId: 'b'),
      action: const ReviewAction(
        type: ReviewType.comment,
        body: 'nits',
        path: 'lib/store.dart',
        line: 8,
      ),
    );
    expect(body?['path'], 'lib/store.dart');
    expect(body?['position'], 8);
    expect(body?['body'], 'nits');
  });
}
