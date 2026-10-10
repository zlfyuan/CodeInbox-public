import 'package:codeinbox/domain/local_search.dart';
import 'package:codeinbox/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  test('matchesQuery is case-insensitive contains', () {
    expect(matchesQuery('', ['Hello']), isTrue);
    expect(matchesQuery('ell', ['Hello']), isTrue);
    expect(matchesQuery('ELL', ['Hello']), isTrue);
    expect(matchesQuery('xyz', ['Hello']), isFalse);
  });

  test('groupRepos sections follow platform order', () {
    final github = sampleAccount();
    final gitee = sampleAccount(id: 'b', platform: ForgePlatform.gitee, login: 'coder');
    final groups = groupRepos(
      [
        sampleRepo(accountId: gitee.id, platform: ForgePlatform.gitee, fullName: 'acme/gitee'),
        sampleRepo(accountId: github.id, fullName: 'acme/box'),
      ],
      [github, gitee],
    );
    expect(groups.map((g) => g.title).toList(), ['GitHub (1)', 'Gitee (1)']);
  });

  test('groupRepos splits two accounts on the same platform', () {
    final a = sampleAccount(id: 'a', login: 'octocat');
    final b = sampleAccount(id: 'b', login: 'hubber');
    final groups = groupRepos(
      [
        sampleRepo(id: 'r1', accountId: 'a', fullName: 'octo/one'),
        sampleRepo(id: 'r2', accountId: 'b', fullName: 'hub/two'),
      ],
      [a, b],
    );
    expect(groups, hasLength(2));
    expect(groups.map((g) => g.title).toList(), ['GitHub · hubber (1)', 'GitHub · octocat (1)']);
  });

  test('groupRepos applies local query', () {
    final account = sampleAccount();
    final groups = groupRepos(
      [
        sampleRepo(id: 'r1', fullName: 'acme/box', language: 'Dart'),
        sampleRepo(id: 'r2', fullName: 'acme/other', language: 'Go', description: 'other', topics: const []),
      ],
      [account],
      query: 'dart',
    );
    expect(groups, hasLength(1));
    expect(groups.single.repos.single.fullName, 'acme/box');
  });
}
