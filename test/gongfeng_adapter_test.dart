import 'dart:convert';

import 'package:codeinbox/data/adapters/gongfeng_adapter.dart';
import 'package:codeinbox/data/http_client.dart';
import 'package:codeinbox/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

import 'support.dart';

void main() {
  test('gongfengApiUri uses git.code.tencent.com /api/v3', () {
    expect(
      gongfengApiUri(null, '/user').toString(),
      'https://git.code.tencent.com/api/v3/user',
    );
  });

  test('parseGongfengMr maps iid, global id, assignee', () {
    final json = (loadFixture('gongfeng_mrs.json') as List<dynamic>).first as Map<String, dynamic>;
    final cr = parseGongfengMr(
      json,
      accountId: 'a',
      repoFullName: 'acme/box',
      webBase: kGongfengDotCom,
      currentUserId: 42,
    );
    expect(cr.localNumber, 12);
    expect(cr.id, 'gongfeng:a:9001');
    expect(cr.sourceBranch, 'feat-inbox');
    expect(cr.assignedToMe, isTrue);
    expect(cr.reviewRequested, isTrue);
    expect(cr.mergeable, isTrue);
    expect(cr.webUrl, 'https://git.code.tencent.com/acme/box/merge_requests/12');
  });

  test('parseGongfengProject maps path and stars', () {
    final json = (loadFixture('gongfeng_projects.json') as List<dynamic>).first as Map<String, dynamic>;
    final repo = parseGongfengProject(json, 'a');
    expect(repo.fullName, 'acme/box');
    expect(repo.starCount, 3);
    expect(repo.forkCount, 1);
    expect(repo.openIssueCount, 4);
    expect(repo.private, isTrue);
    expect(repo.visibility, RepoVisibility.private);
    expect(repo.defaultBranch, 'master');
    expect(repo.cloneUrl, 'https://git.code.tencent.com/acme/box.git');
    expect(repo.sshUrl, 'git@git.code.tencent.com:acme/box.git');
    expect(repo.watchersCount, 3);
    expect(repo.subscribersCount, isNull);
  });

  test('parseGongfengDiff keeps a short patch', () {
    final json = loadFixture('gongfeng_changes.json') as Map<String, dynamic>;
    final file = parseGongfengDiff((json['files'] as List<dynamic>).first as Map<String, dynamic>);
    expect(file.path, 'lib/domain/inbox.dart');
    expect(file.hasPatch, isTrue);
    expect(file.additions, 4);
  });

  test('listInbox sends PRIVATE-TOKEN and fans out to projects', () async {
    final headers = <String>[];
    final client = MockClient((req) async {
      headers.add(req.headers['private-token'] ?? req.headers['PRIVATE-TOKEN'] ?? '');
      expect(req.headers.containsKey('authorization'), isFalse);
      final path = req.url.path;
      if (path.endsWith('/user')) {
        return Response(jsonEncode(loadFixture('gongfeng_user.json')), 200, headers: {'content-type': 'application/json'});
      }
      if (path.endsWith('/projects') && !path.contains('/merge')) {
        return Response(
          jsonEncode(loadFixture('gongfeng_projects.json')),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (path.contains('/merge_requests')) {
        return Response(jsonEncode(loadFixture('gongfeng_mrs.json')), 200, headers: {'content-type': 'application/json'});
      }
      return Response('nope', 404);
    });
    final adapter = GongfengAdapter(http: ForgeHttp(client: client));
    final account = PlatformAccount(
      id: 'a',
      platform: ForgePlatform.gongfeng,
      displayName: 'coder',
      login: 'coder',
      baseUrl: kGongfengDotCom,
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final items = await adapter.listInbox(account: account, token: 'gf-secret');
    expect(items, hasLength(1));
    expect(items.single.title, 'Fix inbox merge');
    expect(items.single.assignedToMe, isTrue);
    expect(headers, everyElement('gf-secret'));
  });

  test('getChangeRequest uses global merge_request id', () async {
    final paths = <String>[];
    final client = MockClient((req) async {
      paths.add(req.url.path);
      if (req.url.path.contains('/merge_request/9001') && !req.url.path.contains('/changes')) {
        return Response(
          jsonEncode((loadFixture('gongfeng_mrs.json') as List<dynamic>).first),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (req.url.path.endsWith('/changes')) {
        return Response(jsonEncode(loadFixture('gongfeng_changes.json')), 200, headers: {'content-type': 'application/json'});
      }
      return Response('nope', 404);
    });
    final adapter = GongfengAdapter(http: ForgeHttp(client: client));
    final account = PlatformAccount(
      id: 'a',
      platform: ForgePlatform.gongfeng,
      displayName: 'coder',
      login: 'coder',
      baseUrl: kGongfengDotCom,
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final summary = parseGongfengMr(
      (loadFixture('gongfeng_mrs.json') as List<dynamic>).first as Map<String, dynamic>,
      accountId: 'a',
      repoFullName: 'acme/box',
      webBase: kGongfengDotCom,
    );
    final cr = await adapter.getChangeRequest(account: account, token: 'gf', summary: summary);
    expect(cr.localNumber, 12);
    final files = await adapter.listFiles(account: account, token: 'gf', cr: cr);
    expect(files.single.path, 'lib/domain/inbox.dart');
    expect(paths.any((p) => p.contains('/merge_request/9001')), isTrue);
  });

  test('parseGongfengEvent maps merge request events only', () {
    final events = loadFixture('gongfeng_events.json') as List<dynamic>;
    final repo = parseGongfengProject(
      (loadFixture('gongfeng_projects.json') as List<dynamic>).first as Map<String, dynamic>,
      'a',
    );
    final mr = parseGongfengEvent(events[0] as Map<String, dynamic>, 'a', repo);
    expect(mr, isNotNull);
    expect(mr!.opensDetail, isTrue);
    expect(mr.localNumber, 12);
    expect(mr.reason, 'commented on');
    expect(parseGongfengEvent(events[1] as Map<String, dynamic>, 'a', repo), isNull);
  });

  test('listNotifications fans out to project events', () async {
    final client = MockClient((req) async {
      final path = req.url.path;
      if (path.endsWith('/projects') && !path.contains('/events')) {
        return Response(
          jsonEncode(loadFixture('gongfeng_projects.json')),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (path.contains('/events')) {
        return Response(jsonEncode(loadFixture('gongfeng_events.json')), 200, headers: {'content-type': 'application/json'});
      }
      return Response('nope', 404);
    });
    final adapter = GongfengAdapter(http: ForgeHttp(client: client));
    final account = PlatformAccount(
      id: 'a',
      platform: ForgePlatform.gongfeng,
      displayName: 'coder',
      login: 'coder',
      baseUrl: kGongfengDotCom,
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final items = await adapter.listNotifications(account: account, token: 'gf');
    expect(items, hasLength(1));
    expect(items.single.localNumber, 12);
  });

  test('submitReview sends path and line on comments', () async {
    Map<String, dynamic>? body;
    final client = MockClient((req) async {
      if (req.method == 'POST' && req.url.path.contains('/comments')) {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return Response('{}', 201, headers: {'content-type': 'application/json'});
      }
      return Response('nope', 404);
    });
    final adapter = GongfengAdapter(http: ForgeHttp(client: client));
    final cr = parseGongfengMr(
      (loadFixture('gongfeng_mrs.json') as List<dynamic>).first as Map<String, dynamic>,
      accountId: 'a',
      repoFullName: 'acme/box',
      webBase: kGongfengDotCom,
    );
    await adapter.submitReview(
      account: PlatformAccount(
        id: 'a',
        platform: ForgePlatform.gongfeng,
        displayName: 'coder',
        login: 'coder',
        baseUrl: kGongfengDotCom,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      token: 'gf',
      cr: cr,
      action: const ReviewAction(
        type: ReviewType.comment,
        body: 'nits',
        path: 'lib/domain/inbox.dart',
        line: 12,
      ),
    );
    expect(body?['path'], 'lib/domain/inbox.dart');
    expect(body?['line'], 12);
    expect(body?['body'], contains('lib/domain/inbox.dart:12'));
  });
}
