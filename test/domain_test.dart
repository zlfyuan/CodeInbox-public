import 'package:codeinbox/domain/models.dart';
import 'package:codeinbox/domain/refs.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  test('ChangeRequest JSON roundtrip', () {
    final original = samplePr();
    final copy = ChangeRequest.fromJson(original.toJson());
    expect(copy.id, original.id);
    expect(copy.localNumber, 12);
    expect(copy.webUrl, 'https://github.com/acme/box/pull/12');
    expect(copy.reviewRequested, isTrue);
    expect(copy.platform, ForgePlatform.github);
  });

  test('PlatformAccount JSON roundtrip omits nothing essential', () {
    final original = sampleAccount();
    final copy = PlatformAccount.fromJson(original.toJson());
    expect(copy.id, original.id);
    expect(copy.login, 'octocat');
    expect(copy.toJson().containsKey('token'), isFalse);
  });

  test('parseChangeRequestRef reads github issue and pull urls', () {
    expect(parseChangeRequestRef('https://api.github.com/repos/acme/box/issues/12')?.localNumber, 12);
    expect(parseChangeRequestRef('https://github.com/acme/box/pull/12')?.repoFullName, 'acme/box');
    expect(parseChangeRequestRef('https://gitee.com/api/v5/repos/acme/box/pulls/7')?.localNumber, 7);
    expect(parseChangeRequestRef('https://gitlab.com/team/app/-/merge_requests/3')?.repoFullName, 'team/app');
    expect(parseChangeRequestRef('https://codeup.aliyun.com/acme/box/change/12')?.repoFullName, 'acme/box');
    expect(parseChangeRequestRef('https://git.code.tencent.com/acme/box/merge_requests/12')?.localNumber, 12);
    expect(parseChangeRequestRef('https://acme.coding.net/p/box/d/inbox/git/merge/12')?.repoFullName, 'box/inbox');
  });

  test('normalizeForgeBaseUrl adds https and strips slash', () {
    expect(normalizeForgeBaseUrl('gitlab.example.com/'), 'https://gitlab.example.com');
    expect(normalizeForgeBaseUrl('https://gitlab.com'), 'https://gitlab.com');
  });

  test('clipPatch truncates long diffs', () {
    final long = '+' * (kMaxPatchChars + 50);
    final clipped = clipPatch(long);
    expect(clipped.$2, isTrue);
    expect(clipped.$1!.length, lessThan(long.length));
    expect(clipPatch('short').$2, isFalse);
  });

  test('NotificationItem.fromChangeRequest opens detail', () {
    final item = NotificationItem.fromChangeRequest(samplePr());
    expect(item.opensDetail, isTrue);
    expect(item.toChangeRequest()?.id, samplePr().id);
  });

  test('Repo JSON roundtrip keeps list-API metadata', () {
    final original = sampleRepo();
    final copy = Repo.fromJson(original.toJson());
    expect(copy.fullName, 'acme/box');
    expect(copy.description, 'Inbox for reviews');
    expect(copy.language, 'Dart');
    expect(copy.starCount, 3);
    expect(copy.forkCount, 1);
    expect(copy.openIssueCount, 4);
    expect(copy.license, 'MIT');
    expect(copy.homepage, 'https://example.com');
    expect(copy.topics, ['inbox', 'flutter']);
    expect(copy.visibility, RepoVisibility.public);
    expect(copy.defaultBranch, 'main');
  });

  test('parseLicense skips NOASSERTION', () {
    expect(parseLicense({'spdx_id': 'MIT'}), 'MIT');
    expect(parseLicense({'spdx_id': 'NOASSERTION'}), isNull);
    expect(parseLicense('BSD-3-Clause'), 'BSD-3-Clause');
  });

  test('parseRepoVisibility maps GitLab v3 levels', () {
    expect(parseRepoVisibility(level: 20), RepoVisibility.public);
    expect(parseRepoVisibility(level: 10), RepoVisibility.internal);
    expect(parseRepoVisibility(level: 0), RepoVisibility.private);
    expect(parseRepoVisibility(raw: 'internal'), RepoVisibility.internal);
  });

  test('jsonAsList unwraps Codeup diffs without taking commits', () {
    final rows = jsonAsList({
      'commits': [
        {'id': 'aaa'},
      ],
      'diffs': [
        {'newPath': 'a.dart', 'diff': '@@\n+ok\n'},
      ],
    });
    expect(rows, hasLength(1));
    expect((rows.single as Map)['newPath'], 'a.dart');
  });

  test('blankToNull trims empty strings', () {
    expect(blankToNull(null), isNull);
    expect(blankToNull('  '), isNull);
    expect(blankToNull(' Dart '), 'Dart');
  });

  test('ReviewAction.isInline needs a path', () {
    expect(const ReviewAction(type: ReviewType.comment, path: 'a.dart', line: 1).isInline, isTrue);
    expect(const ReviewAction(type: ReviewType.comment, body: 'ok').isInline, isFalse);
  });

  test('makeId is stable', () {
    expect(
      ChangeRequest.makeId(
        platform: ForgePlatform.github,
        accountId: 'a',
        repoFullName: 'acme/box',
        localNumber: 12,
      ),
      'github:a:acme/box:12',
    );
  });
}
