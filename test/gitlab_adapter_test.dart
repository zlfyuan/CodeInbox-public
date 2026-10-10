import 'dart:convert';

import 'package:codeinbox/data/adapters/gitlab_adapter.dart';
import 'package:codeinbox/data/http_client.dart';
import 'package:codeinbox/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

import 'support.dart';

void main() {
  test('gitlabApiUri uses gitlab.com by default', () {
    expect(gitlabApiUri(null, '/user').toString(), 'https://gitlab.com/api/v4/user');
  });

  test('gitlabApiUri keeps a self-hosted path prefix', () {
    expect(
      gitlabApiUri('https://git.corp.example/gitlab/', '/user').toString(),
      'https://git.corp.example/gitlab/api/v4/user',
    );
  });

  test('parseGitlabMr maps iid, repo, branches, CI', () {
    final json = loadFixture('gitlab_mr.json') as Map<String, dynamic>;
    final mr = parseGitlabMr(json, accountId: 'a', reviewRequested: true, assignedToMe: false);
    expect(mr.localNumber, 12);
    expect(mr.repoFullName, 'acme/box');
    expect(mr.sourceBranch, 'feat-inbox');
    expect(mr.targetBranch, 'main');
    expect(mr.ciStatus, 'success');
    expect(mr.mergeable, isTrue);
    expect(mr.webUrl, 'https://gitlab.com/acme/box/-/merge_requests/12');
    expect(mr.reviewRequested, isTrue);
    expect(mr.headSha, 'ccc333');
    expect(mr.startSha, 'bbb222');
    expect(mr.baseSha, 'aaa111');
  });

  test('repoFullNameFromGitlabMr falls back to web_url', () {
    expect(
      repoFullNameFromGitlabMr({
        'web_url': 'https://git.corp.example/team/app/-/merge_requests/3',
      }),
      'team/app',
    );
  });

  test('parseGitlabDiff maps patch', () {
    final json = loadFixture('gitlab_diffs.json') as List<dynamic>;
    final file = parseGitlabDiff(json.first as Map<String, dynamic>);
    expect(file.path, 'lib/domain/inbox.dart');
    expect(file.hasPatch, isTrue);
    expect(file.status, 'modified');
  });

  test('parseGitlabTodo maps merge request target', () {
    final item = parseGitlabTodo({
      'id': 9,
      'action_name': 'assigned',
      'target_type': 'MergeRequest',
      'target_url': 'https://gitlab.com/acme/box/-/merge_requests/12',
      'created_at': '2026-09-14T08:00:00Z',
      'target': {
        'iid': 12,
        'title': 'Fix inbox merge',
        'web_url': 'https://gitlab.com/acme/box/-/merge_requests/12',
        'references': {'full': 'acme/box!12'},
      },
    }, 'a');
    expect(item.opensDetail, isTrue);
    expect(item.localNumber, 12);
    expect(item.repoFullName, 'acme/box');
  });

  test('gitlabProjectPath encodes slashes', () {
    expect(gitlabProjectPath('acme/box'), 'acme%2Fbox');
  });

  test('parseGitlabProject maps description and star_count', () {
    final repo = parseGitlabProject({
      'id': 9,
      'path_with_namespace': 'acme/box',
      'web_url': 'https://gitlab.com/acme/box',
      'http_url_to_repo': 'https://gitlab.com/acme/box.git',
      'ssh_url_to_repo': 'git@gitlab.com:acme/box.git',
      'visibility': 'public',
      'default_branch': 'main',
      'last_activity_at': '2026-09-14T00:00:00Z',
      'description': 'Inbox for reviews',
      'star_count': 3,
      'forks_count': 1,
      'open_issues_count': 4,
      'created_at': '2026-09-01T00:00:00Z',
      'topics': ['inbox'],
    }, 'a');
    expect(repo.description, 'Inbox for reviews');
    expect(repo.language, isNull);
    expect(repo.starCount, 3);
    expect(repo.forkCount, 1);
    expect(repo.openIssueCount, 4);
    expect(repo.topics, ['inbox']);
    expect(repo.private, isFalse);
    expect(repo.visibility, RepoVisibility.public);
    expect(repo.cloneUrl, 'https://gitlab.com/acme/box.git');
    expect(repo.sshUrl, 'git@gitlab.com:acme/box.git');
    expect(repo.watchersCount, 3);
    // GitLab list response has no independent subscribers field.
    expect(repo.subscribersCount, isNull);
  });

  test('submitReview posts inline discussion with diff_refs', () async {
    Map<String, dynamic>? body;
    String? path;
    final client = MockClient((req) async {
      if (req.method == 'POST' && req.url.path.endsWith('/discussions')) {
        path = req.url.path;
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return Response('{}', 201, headers: {'content-type': 'application/json'});
      }
      return Response('nope', 404);
    });
    final adapter = GitlabAdapter(http: ForgeHttp(client: client));
    final cr = parseGitlabMr(
      loadFixture('gitlab_mr.json') as Map<String, dynamic>,
      accountId: 'a',
      reviewRequested: true,
      assignedToMe: false,
    );
    await adapter.submitReview(
      account: sampleAccount(platform: ForgePlatform.gitlab),
      token: 'glpat',
      cr: cr,
      action: const ReviewAction(
        type: ReviewType.comment,
        body: 'nits',
        path: 'lib/domain/inbox.dart',
        line: 12,
      ),
    );
    expect(path, contains('/merge_requests/12/discussions'));
    expect(body?['body'], 'nits');
    final position = body?['position'] as Map<String, dynamic>?;
    expect(position?['new_path'], 'lib/domain/inbox.dart');
    expect(position?['new_line'], 12);
    expect(position?['head_sha'], 'ccc333');
  });
}
