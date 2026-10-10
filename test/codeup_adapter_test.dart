import 'dart:convert';

import 'package:codeinbox/data/adapters/codeup_adapter.dart';
import 'package:codeinbox/data/http_client.dart';
import 'package:codeinbox/domain/forge_adapter.dart';
import 'package:codeinbox/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

import 'support.dart';

void main() {
  test('codeupApiUri uses openapi-rdc by default', () {
    expect(
      codeupApiUri(null, '/oapi/v1/platform/user').toString(),
      'https://openapi-rdc.aliyuncs.com/oapi/v1/platform/user',
    );
  });

  test('parseCodeupChangeRequest maps localId, branches, webUrl', () {
    final json = loadFixture('codeup_cr.json') as Map<String, dynamic>;
    final cr = parseCodeupChangeRequest(json, accountId: 'a', reviewRequested: true, assignedToMe: false);
    expect(cr.localNumber, 12);
    expect(cr.repoFullName, 'acme/box');
    expect(cr.sourceBranch, 'feat-inbox');
    expect(cr.targetBranch, 'master');
    expect(cr.mergeable, isTrue);
    expect(cr.webUrl, 'https://codeup.aliyun.com/acme/box/change/12');
    expect(cr.reviewRequested, isTrue);
    expect(cr.platform, ForgePlatform.codeup);
  });

  test('parseCodeupRepo maps path, stars, visibility', () {
    final json = (loadFixture('codeup_repos.json') as List<dynamic>).first as Map<String, dynamic>;
    final repo = parseCodeupRepo(json, 'a');
    expect(repo.fullName, 'acme/box');
    expect(repo.starCount, 3);
    expect(repo.private, isTrue);
    expect(repo.visibility, RepoVisibility.private);
    expect(repo.description, 'Inbox for reviews');
    // codeup_repos.json list response has no httpsUrl/sshUrl — UI must hide the
    // copy rows. Don't synthesize fake URLs from webUrl.
    expect(repo.cloneUrl, isNull);
    expect(repo.sshUrl, isNull);
    expect(repo.watchersCount, 3);
    expect(repo.subscribersCount, isNull);
  });

  test('parseCodeupChangedFile treats string deletedFile as bool', () {
    final json = loadFixture('codeup_tree.json') as Map<String, dynamic>;
    final item = (json['changedTreeItems'] as List<dynamic>).first as Map<String, dynamic>;
    final file = parseCodeupChangedFile(item);
    expect(file.path, 'lib/domain/inbox.dart');
    expect(file.additions, 4);
    expect(file.deletions, 1);
    expect(file.hasPatch, isFalse);
    final withDiff = parseCodeupChangedFile({
      ...item,
      'diff': '@@\n+ok\n',
    });
    expect(withDiff.hasPatch, isTrue);
  });

  test('parseCodeupComment maps inline line', () {
    final json = (loadFixture('codeup_comments.json') as List<dynamic>).first as Map<String, dynamic>;
    final comment = parseCodeupComment(json);
    expect(comment.authorLogin, 'bob');
    expect(comment.path, 'lib/domain/inbox.dart');
    expect(comment.line, 12);
  });

  test('repoFullNameFromCodeupUrl strips /change/N', () {
    expect(repoFullNameFromCodeupUrl('https://codeup.aliyun.com/acme/box/change/12'), 'acme/box');
  });

  test('verifyAndProfile requires orgId on 中心版', () async {
    final adapter = CodeupAdapter(http: ForgeHttp(client: MockClient((_) async => Response('{}', 200))));
    expect(
      () => adapter.verifyAndProfile(token: 'pt-test', baseUrl: kCodeupOpenApi),
      throwsA(isA<AdapterException>()),
    );
  });

  test('listInbox sends x-yunxiao-token and reviewerIds', () async {
    final headers = <String>[];
    final paths = <String>[];
    final client = MockClient((req) async {
      headers.add(req.headers['x-yunxiao-token'] ?? '');
      expect(req.headers.containsKey('authorization'), isFalse);
      paths.add(req.url.path);
      if (req.url.path.endsWith('/platform/user')) {
        return Response(jsonEncode(loadFixture('codeup_user.json')), 200, headers: {'content-type': 'application/json'});
      }
      if (req.url.path.endsWith('/changeRequests')) {
        expect(req.url.queryParameters['reviewerIds'], '62c795xxxb468af8');
        expect(req.url.queryParameters['state'], 'opened');
        return Response(jsonEncode(loadFixture('codeup_crs.json')), 200, headers: {'content-type': 'application/json'});
      }
      if (req.url.path.endsWith('/repositories')) {
        return Response(jsonEncode(loadFixture('codeup_repos.json')), 200, headers: {'content-type': 'application/json'});
      }
      return Response('nope', 404);
    });
    final adapter = CodeupAdapter(http: ForgeHttp(client: client));
    final account = PlatformAccount(
      id: 'a',
      platform: ForgePlatform.codeup,
      displayName: 'coder',
      login: 'coder',
      baseUrl: kCodeupOpenApi,
      orgId: '60d54f3daccf2bbd6659f3ad',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final items = await adapter.listInbox(account: account, token: 'pt-secret');
    expect(items, hasLength(1));
    expect(items.single.title, 'Fix inbox merge');
    expect(items.single.repoFullName, 'acme/box');
    expect(headers, everyElement('pt-secret'));
    expect(paths.any((p) => p.contains('/organizations/60d54f3daccf2bbd6659f3ad/changeRequests')), isTrue);
  });

  test('getChangeRequest and files use patch sets then tree', () async {
    final client = MockClient((req) async {
      final path = req.url.path;
      if (path.endsWith('/changeRequests/12') && !path.contains('/diffs') && !path.contains('/comments')) {
        return Response(jsonEncode(loadFixture('codeup_cr.json')), 200, headers: {'content-type': 'application/json'});
      }
      if (path.endsWith('/diffs/patches')) {
        return Response(jsonEncode(loadFixture('codeup_patches.json')), 200, headers: {'content-type': 'application/json'});
      }
      if (path.endsWith('/diffs/changeTree')) {
        expect(req.url.queryParameters['fromPatchSetId'], 'from-target');
        expect(req.url.queryParameters['toPatchSetId'], 'to-source');
        return Response(jsonEncode(loadFixture('codeup_tree.json')), 200, headers: {'content-type': 'application/json'});
      }
      return Response('nope', 404);
    });
    final adapter = CodeupAdapter(http: ForgeHttp(client: client));
    final account = PlatformAccount(
      id: 'a',
      platform: ForgePlatform.codeup,
      displayName: 'coder',
      login: 'coder',
      baseUrl: kCodeupOpenApi,
      orgId: 'org1',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final summary = samplePr(platform: ForgePlatform.codeup, webUrl: 'https://codeup.aliyun.com/acme/box/change/12');
    final cr = await adapter.getChangeRequest(account: account, token: 'pt', summary: summary);
    expect(cr.repoFullName, 'acme/box');
    final files = await adapter.listFiles(account: account, token: 'pt', cr: cr);
    expect(files.single.path, 'lib/domain/inbox.dart');
  });

  test('listFiles prefers /diffs patch over changeTree', () async {
    final paths = <String>[];
    final client = MockClient((req) async {
      paths.add(req.url.path);
      if (req.url.path.endsWith('/diffs/patches')) {
        return Response(jsonEncode(loadFixture('codeup_patches.json')), 200, headers: {'content-type': 'application/json'});
      }
      if (req.url.path.endsWith('/diffs') && !req.url.path.contains('changeTree') && !req.url.path.contains('patches')) {
        return Response(jsonEncode(loadFixture('codeup_diffs.json')), 200, headers: {'content-type': 'application/json'});
      }
      return Response('nope', 404);
    });
    final adapter = CodeupAdapter(http: ForgeHttp(client: client));
    final account = PlatformAccount(
      id: 'a',
      platform: ForgePlatform.codeup,
      displayName: 'coder',
      login: 'coder',
      baseUrl: kCodeupOpenApi,
      orgId: 'org1',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final cr = samplePr(platform: ForgePlatform.codeup, webUrl: 'https://codeup.aliyun.com/acme/box/change/12');
    final files = await adapter.listFiles(account: account, token: 'pt', cr: cr);
    expect(files.single.hasPatch, isTrue);
    expect(files.single.patch, contains('void refresh()'));
    expect(paths.any((p) => p.endsWith('/diffs/changeTree')), isFalse);
  });

  test('listFiles recovers missing diff from /compares JSON diffs', () async {
    // GetCompare is JSON {diffs:[{newPath, diff}]}, not a raw diff --git body.
    final paths = <String>[];
    final client = MockClient((req) async {
      paths.add(req.url.path);
      if (req.url.path.endsWith('/diffs/patches')) {
        return Response(jsonEncode(loadFixture('codeup_patches.json')), 200,
            headers: {'content-type': 'application/json'});
      }
      if (req.url.path.endsWith('/diffs') && !req.url.path.contains('changeTree') && !req.url.path.contains('patches')) {
        return Response(
          jsonEncode([
            {
              'newPath': 'big/file.dart',
              'oldPath': 'big/file.dart',
              'newFile': false,
              'deletedFile': false,
              'addLines': 1,
              'delLines': 1,
              'diff': null,
              'patch': null,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (req.url.path.endsWith('/compares')) {
        expect(req.url.path.contains('/changeRequests/'), isFalse);
        expect(req.url.queryParameters['from'], 'master');
        expect(req.url.queryParameters['to'], 'feat-inbox');
        expect(req.url.queryParameters['sourceType'], 'branch');
        return Response(
          jsonEncode(loadFixture('codeup_compares.json')),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return Response('nope', 404);
    });
    final adapter = CodeupAdapter(http: ForgeHttp(client: client));
    final account = PlatformAccount(
      id: 'a',
      platform: ForgePlatform.codeup,
      displayName: 'coder',
      login: 'coder',
      baseUrl: kCodeupOpenApi,
      orgId: 'org1',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final cr = samplePr(
      platform: ForgePlatform.codeup,
      webUrl: 'https://codeup.aliyun.com/acme/box/change/12',
    ).copyWith(sourceBranch: 'feat-inbox', targetBranch: 'master');
    final files = await adapter.listFiles(account: account, token: 'pt', cr: cr);
    expect(files, hasLength(1));
    expect(files.single.hasPatch, isTrue);
    expect(files.single.patch, contains('+void recovered()'));
    expect(files.single.truncated, isFalse);
    expect(paths.any((p) => p.endsWith('/compares')), isTrue);
  });

  test('listFiles keeps null patch when /compares also omits it', () async {
    // /diffs 与 /compares 都缺 diff,恢复失败,保留原状态走 fallback。
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/diffs/patches')) {
        return Response(jsonEncode(loadFixture('codeup_patches.json')), 200,
            headers: {'content-type': 'application/json'});
      }
      if (req.url.path.endsWith('/diffs') && !req.url.path.contains('changeTree') && !req.url.path.contains('patches')) {
        return Response(
          jsonEncode([
            {
              'newPath': 'big/file.dart',
              'oldPath': 'big/file.dart',
              'addLines': 1,
              'delLines': 1,
              'diff': null,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (req.url.path.endsWith('/compares')) {
        return Response(jsonEncode({'commits': [], 'diffs': []}), 200, headers: {'content-type': 'application/json'});
      }
      return Response('nope', 404);
    });
    final adapter = CodeupAdapter(http: ForgeHttp(client: client));
    final account = PlatformAccount(
      id: 'a',
      platform: ForgePlatform.codeup,
      displayName: 'coder',
      login: 'coder',
      baseUrl: kCodeupOpenApi,
      orgId: 'org1',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final cr = samplePr(
      platform: ForgePlatform.codeup,
      webUrl: 'https://codeup.aliyun.com/acme/box/change/12',
    ).copyWith(sourceBranch: 'feat-inbox', targetBranch: 'master');
    final files = await adapter.listFiles(account: account, token: 'pt', cr: cr);
    expect(files.single.hasPatch, isFalse);
  });

  test('listFiles skips /compares when sourceBranch or targetBranch is empty', () async {
    // 没有分支名就走不了 /compares,不要发请求。
    final paths = <String>[];
    final client = MockClient((req) async {
      paths.add(req.url.path);
      if (req.url.path.endsWith('/diffs/patches')) {
        return Response(jsonEncode(loadFixture('codeup_patches.json')), 200,
            headers: {'content-type': 'application/json'});
      }
      if (req.url.path.endsWith('/diffs') && !req.url.path.contains('changeTree') && !req.url.path.contains('patches')) {
        return Response(
          jsonEncode([
            {
              'newPath': 'big/file.dart',
              'oldPath': 'big/file.dart',
              'addLines': 1,
              'delLines': 1,
              'diff': null,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (req.url.path.endsWith('/compares')) {
        return Response('should not be called', 500);
      }
      return Response('nope', 404);
    });
    final adapter = CodeupAdapter(http: ForgeHttp(client: client));
    final account = PlatformAccount(
      id: 'a',
      platform: ForgePlatform.codeup,
      displayName: 'coder',
      login: 'coder',
      baseUrl: kCodeupOpenApi,
      orgId: 'org1',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    // 故意把 sourceBranch 留空,模拟某些 PR 详情不返回分支名的极端情况。
    final cr = samplePr(
      platform: ForgePlatform.codeup,
      webUrl: 'https://codeup.aliyun.com/acme/box/change/12',
    ).copyWith(sourceBranch: '', targetBranch: 'master');
    final files = await adapter.listFiles(account: account, token: 'pt', cr: cr);
    expect(files.single.hasPatch, isFalse);
    expect(paths.any((p) => p.endsWith('/compares')), isFalse);
  });

  test('listFiles uses /compares when patch sets only list MERGE_SOURCE', () async {
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/diffs/patches')) {
        return Response(
          jsonEncode([
            {
              'patchSetBizId': 'to-source',
              'relatedMergeItemType': 'MERGE_SOURCE',
              'versionNo': 1,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (req.url.path.contains('/changeRequests/12/diffs')) {
        return Response('should not list CR diffs without from+to', 500);
      }
      if (req.url.path.endsWith('/compares')) {
        return Response(
          jsonEncode(loadFixture('codeup_compares.json')),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return Response('nope', 404);
    });
    final adapter = CodeupAdapter(http: ForgeHttp(client: client));
    final account = PlatformAccount(
      id: 'a',
      platform: ForgePlatform.codeup,
      displayName: 'coder',
      login: 'coder',
      baseUrl: kCodeupOpenApi,
      orgId: 'org1',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final cr = samplePr(
      platform: ForgePlatform.codeup,
      webUrl: 'https://codeup.aliyun.com/acme/box/change/12',
    ).copyWith(sourceBranch: 'feat-inbox', targetBranch: 'master');
    final files = await adapter.listFiles(account: account, token: 'pt', cr: cr);
    expect(files.single.path, 'big/file.dart');
    expect(files.single.hasPatch, isTrue);
    expect(files.single.patch, contains('void recovered()'));
  });

  test('listFiles unwraps a diffs object from GET /diffs', () async {
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/diffs/patches')) {
        return Response(jsonEncode(loadFixture('codeup_patches.json')), 200, headers: {'content-type': 'application/json'});
      }
      if (req.url.path.endsWith('/diffs') && !req.url.path.contains('changeTree') && !req.url.path.contains('patches')) {
        return Response(
          jsonEncode({'diffs': loadFixture('codeup_diffs.json')}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return Response('nope', 404);
    });
    final adapter = CodeupAdapter(http: ForgeHttp(client: client));
    final account = PlatformAccount(
      id: 'a',
      platform: ForgePlatform.codeup,
      displayName: 'coder',
      login: 'coder',
      baseUrl: kCodeupOpenApi,
      orgId: 'org1',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final cr = samplePr(platform: ForgePlatform.codeup, webUrl: 'https://codeup.aliyun.com/acme/box/change/12');
    final files = await adapter.listFiles(account: account, token: 'pt', cr: cr);
    expect(files.single.hasPatch, isTrue);
    expect(files.single.patch, contains('void refresh()'));
  });

  test('submitReview inline comment sends file_path and line_number', () async {
    Map<String, dynamic>? body;
    final client = MockClient((req) async {
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return Response('{}', 200, headers: {'content-type': 'application/json'});
    });
    final adapter = CodeupAdapter(http: ForgeHttp(client: client));
    await adapter.submitReview(
      account: PlatformAccount(
        id: 'a',
        platform: ForgePlatform.codeup,
        displayName: 'coder',
        login: 'coder',
        baseUrl: kCodeupOpenApi,
        orgId: 'org1',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      token: 'pt',
      cr: samplePr(platform: ForgePlatform.codeup),
      action: const ReviewAction(
        type: ReviewType.comment,
        body: 'nits',
        path: 'lib/domain/inbox.dart',
        line: 12,
      ),
    );
    expect(body?['comment_type'], 'INLINE_COMMENT');
    expect(body?['file_path'], 'lib/domain/inbox.dart');
    expect(body?['line_number'], 12);
  });
}
