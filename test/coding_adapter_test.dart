import 'dart:convert';

import 'package:codeinbox/data/adapters/coding_adapter.dart';
import 'package:codeinbox/data/http_client.dart';
import 'package:codeinbox/domain/forge_adapter.dart';
import 'package:codeinbox/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

import 'support.dart';

void main() {
  test('codingApiUri posts to team open-api Action', () {
    expect(
      codingApiUri('https://acme.coding.net', 'DescribeCodingCurrentUser').toString(),
      'https://acme.coding.net/open-api?Action=DescribeCodingCurrentUser',
    );
  });

  test('codingTeamSlug reads subdomain', () {
    expect(codingTeamSlug('https://acme.coding.net'), 'acme');
    expect(codingTeamSlug('https://e.coding.net'), isNull);
  });

  test('parseCodingMr maps iid, merge id, reviewers', () {
    final envelope = loadFixture('coding_mrs.json') as Map<String, dynamic>;
    final list = unwrapCoding(envelope)['MergeRequestList'] as List<dynamic>;
    final cr = parseCodingMr(
      list.first as Map<String, dynamic>,
      accountId: 'a',
      projectName: 'box',
      webBase: 'https://acme.coding.net',
      currentUserId: 42,
    );
    expect(cr.localNumber, 12);
    expect(cr.id, 'coding:a:200:9001');
    expect(cr.repoFullName, 'box/inbox');
    expect(cr.sourceBranch, 'feat-inbox');
    expect(cr.reviewRequested, isTrue);
    expect(cr.webUrl, contains('/git/merge/12'));
  });

  test('parseCodingDepot maps project/depot fullName', () {
    final envelope = loadFixture('coding_depots.json') as Map<String, dynamic>;
    final list = unwrapCoding(envelope)['DepotList'] as List<dynamic>;
    final repo = parseCodingDepot(list.first as Map<String, dynamic>, 'a', 'box');
    expect(repo.fullName, 'box/inbox');
    expect(repo.starCount, 3);
    expect(repo.forkCount, 1);
    expect(repo.language, 'Dart');
    expect(repo.defaultBranch, 'master');
    // CODING exposes only an HTTPS clone URL on the depot list.
    expect(repo.cloneUrl, 'https://e.coding.net/acme/box/inbox.git');
    expect(repo.sshUrl, isNull);
    expect(repo.watchersCount, 3);
    expect(repo.subscribersCount, isNull);
  });

  test('verifyAndProfile requires a team URL', () async {
    final adapter = CodingAdapter(http: ForgeHttp(client: MockClient((_) async => Response('{}', 200))));
    expect(
      () => adapter.verifyAndProfile(token: 'tok', baseUrl: null),
      throwsA(isA<AdapterException>()),
    );
  });

  test('listInbox sends token Authorization and Action query', () async {
    final actions = <String>[];
    final auths = <String>[];
    final client = MockClient((req) async {
      actions.add(req.url.queryParameters['Action'] ?? '');
      auths.add(req.headers['authorization'] ?? '');
      expect(req.method, 'POST');
      final action = req.url.queryParameters['Action'];
      if (action == 'DescribeCodingCurrentUser') {
        return Response(jsonEncode(loadFixture('coding_user.json')), 200, headers: {'content-type': 'application/json'});
      }
      if (action == 'DescribeCodingProjects') {
        return Response(jsonEncode(loadFixture('coding_projects.json')), 200, headers: {'content-type': 'application/json'});
      }
      if (action == 'DescribeProjectMergeRequests') {
        return Response(jsonEncode(loadFixture('coding_mrs.json')), 200, headers: {'content-type': 'application/json'});
      }
      return Response('nope', 404);
    });
    final adapter = CodingAdapter(http: ForgeHttp(client: client));
    final account = PlatformAccount(
      id: 'a',
      platform: ForgePlatform.coding,
      displayName: 'coder',
      login: 'coder',
      baseUrl: 'https://acme.coding.net',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final items = await adapter.listInbox(account: account, token: 'coding-secret');
    expect(items, hasLength(1));
    expect(items.single.title, 'Fix inbox merge');
    expect(items.single.reviewRequested, isTrue);
    expect(actions, contains('DescribeProjectMergeRequests'));
    expect(auths, everyElement('token coding-secret'));
  });

  test('getChangeRequest and files use DepotId + IId / MergeId', () async {
    final actions = <String>[];
    final client = MockClient((req) async {
      actions.add(req.url.queryParameters['Action'] ?? '');
      final action = req.url.queryParameters['Action'];
      if (action == 'DescribeMergeRequest') {
        return Response(jsonEncode(loadFixture('coding_mr.json')), 200, headers: {'content-type': 'application/json'});
      }
      if (action == 'DescribeMergeRequestFileDiff') {
        return Response(jsonEncode(loadFixture('coding_diffs.json')), 200, headers: {'content-type': 'application/json'});
      }
      return Response('nope', 404);
    });
    final adapter = CodingAdapter(http: ForgeHttp(client: client));
    final account = PlatformAccount(
      id: 'a',
      platform: ForgePlatform.coding,
      displayName: 'coder',
      login: 'coder',
      baseUrl: 'https://acme.coding.net',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final summary = parseCodingMr(
      (unwrapCoding(loadFixture('coding_mrs.json') as Map<String, dynamic>)['MergeRequestList'] as List<dynamic>).first
          as Map<String, dynamic>,
      accountId: 'a',
      projectName: 'box',
      webBase: 'https://acme.coding.net',
    );
    final cr = await adapter.getChangeRequest(account: account, token: 'tok', summary: summary);
    expect(cr.localNumber, 12);
    expect(cr.mergeable, isTrue);
    final files = await adapter.listFiles(account: account, token: 'tok', cr: cr);
    expect(files.single.path, 'lib/domain/inbox.dart');
    expect(files.single.hasPatch, isTrue);
    expect(actions, containsAll(['DescribeMergeRequest', 'DescribeMergeRequestFileDiff']));
  });

  test('submitReview approve posts ModifyGitMergeRequestReview ACCEPT', () async {
    String? action;
    Map<String, dynamic>? body;
    final client = MockClient((req) async {
      action = req.url.queryParameters['Action'];
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return Response(jsonEncode({'Response': {}}), 200, headers: {'content-type': 'application/json'});
    });
    final adapter = CodingAdapter(http: ForgeHttp(client: client));
    final summary = parseCodingMr(
      (unwrapCoding(loadFixture('coding_mrs.json') as Map<String, dynamic>)['MergeRequestList'] as List<dynamic>).first
          as Map<String, dynamic>,
      accountId: 'a',
      projectName: 'box',
      webBase: 'https://acme.coding.net',
    );
    await adapter.submitReview(
      account: PlatformAccount(
        id: 'a',
        platform: ForgePlatform.coding,
        displayName: 'coder',
        login: 'coder',
        baseUrl: 'https://acme.coding.net',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      token: 'tok',
      cr: summary,
      action: const ReviewAction(type: ReviewType.approve, body: 'lgtm'),
    );
    expect(action, 'ModifyGitMergeRequestReview');
    expect(body?['ReviewerState'], 'ACCEPT');
    expect(body?['Content'], 'lgtm');
  });

  test('submitReview comment sends Path and Line', () async {
    Map<String, dynamic>? body;
    final client = MockClient((req) async {
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return Response(jsonEncode({'Response': {}}), 200, headers: {'content-type': 'application/json'});
    });
    final adapter = CodingAdapter(http: ForgeHttp(client: client));
    final summary = parseCodingMr(
      (unwrapCoding(loadFixture('coding_mrs.json') as Map<String, dynamic>)['MergeRequestList'] as List<dynamic>).first
          as Map<String, dynamic>,
      accountId: 'a',
      projectName: 'box',
      webBase: 'https://acme.coding.net',
    );
    await adapter.submitReview(
      account: PlatformAccount(
        id: 'a',
        platform: ForgePlatform.coding,
        displayName: 'coder',
        login: 'coder',
        baseUrl: 'https://acme.coding.net',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      token: 'tok',
      cr: summary,
      action: const ReviewAction(
        type: ReviewType.comment,
        body: 'nits',
        path: 'lib/domain/inbox.dart',
        line: 12,
      ),
    );
    expect(body?['Path'], 'lib/domain/inbox.dart');
    expect(body?['Line'], 12);
    expect(body?['Content'], 'nits');
  });
}
