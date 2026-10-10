import 'dart:async';

import 'package:codeinbox/domain/forge_adapter.dart';
import 'package:codeinbox/domain/models.dart';
import 'package:codeinbox/main.dart';
import 'package:codeinbox/store.dart';
import 'package:codeinbox/ui/diff_page.dart';
import 'package:codeinbox/ui/inbox_page.dart';
import 'package:codeinbox/ui/notifications_page.dart';
import 'package:codeinbox/ui/repos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_adapter.dart';
import 'support.dart';

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('codeinbox/badge'),
      (_) async => null,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('codeinbox/badge'),
      null,
    );
  });

  testWidgets('no accounts shows welcome', (tester) async {
    final store = await makeStore(adapters: {
      ForgePlatform.github: FakeAdapter(platform: ForgePlatform.github),
      ForgePlatform.gitee: FakeAdapter(platform: ForgePlatform.gitee),
    });
    await tester.pumpWidget(CodeInboxApp(store: store));
    expect(find.text('One inbox for GitHub, Gitee, GitLab, Codeup, Gongfeng, and CODING review requests.'), findsOneWidget);
    expect(find.text('Add GitHub'), findsOneWidget);
    expect(find.text('Add GitLab'), findsOneWidget);
    expect(find.text('Add Codeup'), findsOneWidget);
    expect(find.text('Add Gongfeng'), findsOneWidget);
    expect(find.text('Add CODING'), findsOneWidget);
  });

  testWidgets('account with inbox shows PR title', (tester) async {
    final account = sampleAccount();
    final store = await makeStore(
      accounts: [account],
      adapters: {
        ForgePlatform.github: FakeAdapter(
          platform: ForgePlatform.github,
          inbox: [samplePr(accountId: account.id)],
          files: const [
            ChangedFile(path: 'lib/domain/inbox.dart', additions: 4, deletions: 1, patch: '@@\n+ok\n'),
          ],
        ),
        ForgePlatform.gitee: FakeAdapter(platform: ForgePlatform.gitee),
      },
    );
    await tester.pumpWidget(CodeInboxApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Fix inbox merge'), findsOneWidget);
    expect(find.text('Inbox'), findsWidgets);

    await tester.tap(find.text('Fix inbox merge'));
    await tester.pumpAndSettle();
    expect(find.text('lib/domain/inbox.dart'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
  });

  testWidgets('alert for a pull request opens detail', (tester) async {
    final account = sampleAccount();
    final pr = samplePr(accountId: account.id);
    final store = await makeStore(
      accounts: [account],
      adapters: {
        ForgePlatform.github: FakeAdapter(
          platform: ForgePlatform.github,
          notifications: [
            NotificationItem(
              id: 'n1',
              platform: ForgePlatform.github,
              accountId: account.id,
              title: 'Review requested on inbox',
              unread: true,
              webUrl: pr.webUrl,
              updatedAt: pr.updatedAt,
              relatedType: RelatedType.changeRequest,
              repoFullName: pr.repoFullName,
              localNumber: pr.localNumber,
            ),
          ],
          files: const [
            ChangedFile(path: 'lib/domain/inbox.dart', additions: 4, deletions: 1, patch: '@@\n+ok\n'),
          ],
        ),
        ForgePlatform.gitee: FakeAdapter(platform: ForgePlatform.gitee),
      },
    );
    await tester.pumpWidget(CodeInboxApp(store: store));
    await store.refreshAll();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review requested on inbox'));
    await tester.pumpAndSettle();
    expect(find.text('lib/domain/inbox.dart'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
  });

  testWidgets('repo opens its detail with open pull requests', (tester) async {
    final account = sampleAccount();
    final store = await makeStore(
      accounts: [account],
      adapters: {
        ForgePlatform.github: FakeAdapter(
          platform: ForgePlatform.github,
          repos: [sampleRepo(accountId: account.id)],
          repoPulls: [samplePr(accountId: account.id, title: 'Repo listed PR')],
        ),
        ForgePlatform.gitee: FakeAdapter(platform: ForgePlatform.gitee),
      },
    );
    await tester.pumpWidget(CodeInboxApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Repos'));
    await tester.pumpAndSettle();
    expect(find.text('GitHub (1)'), findsOneWidget);
    // 新版标题是 'owner / repoName',整体文本 'acme / box'。用全文匹配,
    // 避免与 description 'Inbox for reviews'(含 'box' 子串)和底部导航 'Inbox' 标签撞车。
    await tester.tap(find.text('acme / box'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox for reviews'), findsOneWidget);
    expect(find.text('main'), findsOneWidget);
    expect(find.text('Dart'), findsOneWidget);
    expect(find.text('Stars'), findsOneWidget);
    expect(find.text('Forks'), findsOneWidget);
    expect(find.text('Issues'), findsOneWidget);
    expect(find.text('MIT'), findsOneWidget);
    expect(find.text('inbox'), findsOneWidget);
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('This is the README.'), findsOneWidget);
    expect(find.textContaining('Pull requests'), findsOneWidget);
    await tester.tap(find.textContaining('Pull requests'));
    await tester.pumpAndSettle();
    expect(find.text('Repo listed PR'), findsOneWidget);
  });

  testWidgets('PR detail Retry clears stale error and reloads', (tester) async {
    final account = sampleAccount();
    final adapter = FakeAdapter(
      platform: ForgePlatform.github,
      inbox: [samplePr(accountId: account.id)],
      files: const [
        ChangedFile(path: 'lib/domain/inbox.dart', additions: 4, deletions: 1, patch: '@@\n+ok\n'),
      ],
      detailError: AdapterException.http(502, 'upstream'),
    );
    final store = await makeStore(
      accounts: [account],
      adapters: {
        ForgePlatform.github: adapter,
        ForgePlatform.gitee: FakeAdapter(platform: ForgePlatform.gitee),
      },
    );
    await tester.pumpWidget(CodeInboxApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fix inbox merge'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('HTTP 502'), findsOneWidget);

    adapter.detailError = null;
    adapter.detailGate = Completer<void>();
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    adapter.detailGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('lib/domain/inbox.dart'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(adapter.getChangeRequestCount, 2);
  });

  testWidgets('diff page posts a line comment', (tester) async {
    final account = sampleAccount();
    final adapter = FakeAdapter(
      platform: ForgePlatform.github,
      inbox: [samplePr(accountId: account.id)],
      files: const [
        ChangedFile(
          path: 'lib/domain/inbox.dart',
          additions: 4,
          deletions: 1,
          patch: '@@ -1,1 +1,2 @@\n keep\n+ok\n',
        ),
      ],
    );
    final store = await makeStore(
      accounts: [account],
      adapters: {
        ForgePlatform.github: adapter,
        ForgePlatform.gitee: FakeAdapter(platform: ForgePlatform.gitee),
      },
    );
    await tester.pumpWidget(CodeInboxApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fix inbox merge'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('lib/domain/inbox.dart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ok'));
    await tester.pump();
    final fields = find.descendant(of: find.byType(DiffPage), matching: find.byType(TextField));
    await tester.enterText(fields.at(1), 'nits');
    await tester.tap(find.text('Post comment'));
    await tester.pumpAndSettle();
    expect(adapter.submitted, hasLength(1));
    expect(adapter.submitted.single.path, 'lib/domain/inbox.dart');
    expect(adapter.submitted.single.line, 2);
    expect(adapter.submitted.single.body, 'nits');
    expect(find.text('Comment posted'), findsOneWidget);
  });

  testWidgets('inbox load more appends the next page', (tester) async {
    final account = sampleAccount();
    final page1 = [
      for (var i = 1; i <= AppStore.inboxPageSize; i++)
        samplePr(id: 'github:a:acme/box:$i', number: i, title: 'PR $i', accountId: account.id),
    ];
    final store = await makeStore(
      accounts: [account],
      adapters: {
        ForgePlatform.github: FakeAdapter(
          platform: ForgePlatform.github,
          inbox: page1,
          inboxMore: [samplePr(id: 'github:a:acme/box:99', number: 99, title: 'Older PR', accountId: account.id)],
        ),
        ForgePlatform.gitee: FakeAdapter(platform: ForgePlatform.gitee),
      },
    );
    await tester.pumpWidget(CodeInboxApp(store: store));
    await tester.pumpAndSettle();
    final inboxScrollable = find.descendant(
      of: find.byType(InboxPage),
      matching: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    );
    await tester.scrollUntilVisible(find.text('Load more'), 500, scrollable: inboxScrollable);
    await tester.drag(inboxScrollable, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(find.text('Older PR'), findsOneWidget);
  });

  testWidgets('inbox search hides non-matching titles', (tester) async {
    final account = sampleAccount();
    final store = await makeStore(
      accounts: [account],
      adapters: {
        ForgePlatform.github: FakeAdapter(
          platform: ForgePlatform.github,
          inbox: [samplePr(accountId: account.id)],
        ),
        ForgePlatform.gitee: FakeAdapter(platform: ForgePlatform.gitee),
      },
    );
    await tester.pumpWidget(CodeInboxApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Fix inbox merge'), findsOneWidget);
    await tester.enterText(
      find.descendant(of: find.byType(InboxPage), matching: find.byType(TextField)),
      'zzzz',
    );
    await tester.pump();
    expect(find.text('No matches'), findsOneWidget);
    expect(find.text('Fix inbox merge'), findsNothing);
  });

  testWidgets('alerts platform chip keeps time order within the platform', (tester) async {
    final github = sampleAccount();
    final gitee = sampleAccount(id: 'b', platform: ForgePlatform.gitee, login: 'coder');
    final store = await makeStore(
      accounts: [github, gitee],
      adapters: {
        ForgePlatform.github: FakeAdapter(
          platform: ForgePlatform.github,
          notifications: [
            NotificationItem(
              id: 'n-gh',
              platform: ForgePlatform.github,
              accountId: github.id,
              title: 'GitHub ping',
              unread: true,
              webUrl: 'https://github.com/acme/box/pull/12',
              updatedAt: DateTime.utc(2026, 9, 14),
              relatedType: RelatedType.changeRequest,
              repoFullName: 'acme/box',
              localNumber: 12,
            ),
          ],
        ),
        ForgePlatform.gitee: FakeAdapter(
          platform: ForgePlatform.gitee,
          notifications: [
            NotificationItem(
              id: 'n-ge',
              platform: ForgePlatform.gitee,
              accountId: gitee.id,
              title: 'Gitee ping',
              unread: true,
              webUrl: 'https://gitee.com/acme/box/pulls/7',
              updatedAt: DateTime.utc(2026, 9, 15),
              relatedType: RelatedType.changeRequest,
              repoFullName: 'acme/box',
              localNumber: 7,
            ),
          ],
        ),
      },
    );
    await tester.pumpWidget(CodeInboxApp(store: store));
    await store.refreshAll();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();
    expect(find.text('GitHub ping'), findsOneWidget);
    expect(find.text('Gitee ping'), findsOneWidget);
    await tester.tap(find.descendant(
      of: find.byType(NotificationsPage),
      matching: find.widgetWithText(FilterChip, 'Gitee'),
    ));
    await tester.pump();
    expect(find.text('Gitee ping'), findsOneWidget);
    expect(find.text('GitHub ping'), findsNothing);
  });

  testWidgets('repos group by platform, search, sort, and hide-archived', (tester) async {
    final github = sampleAccount();
    final gitee = sampleAccount(id: 'b', platform: ForgePlatform.gitee, login: 'coder');
    final store = await makeStore(
      accounts: [github, gitee],
      adapters: {
        ForgePlatform.github: FakeAdapter(
          platform: ForgePlatform.github,
          repos: [
            sampleRepo(accountId: github.id),
            // 归档仓库:Hide archived 默认 OFF 时仍可见,开启后消失。
            sampleRepo(
              id: 'r-arch',
              accountId: github.id,
              fullName: 'acme/archived-box',
              webUrl: 'https://github.com/acme/archived-box',
              archived: true,
            ),
          ],
        ),
        ForgePlatform.gitee: FakeAdapter(
          platform: ForgePlatform.gitee,
          repos: [
            sampleRepo(
              id: 'r2',
              platform: ForgePlatform.gitee,
              accountId: gitee.id,
              fullName: 'acme/gitee-box',
              webUrl: 'https://gitee.com/acme/gitee-box',
              language: 'Go',
              topics: const [],
            ),
          ],
        ),
      },
    );
    await tester.pumpWidget(CodeInboxApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Repos'));
    await tester.pumpAndSettle();
    expect(find.text('GitHub (2)'), findsOneWidget);
    expect(find.text('Gitee (1)'), findsOneWidget);

    // 搜索 'gitee' 后只剩 Gitee 那条;新标题拆成 owner / repoName。
    await tester.enterText(
      find.descendant(of: find.byType(ReposPage), matching: find.byType(TextField)),
      'gitee',
    );
    await tester.pump();
    expect(find.text('Gitee (1)'), findsOneWidget);
    expect(find.text('GitHub (2)'), findsNothing);
    // 新版标题 'acme / gitee-box',全文匹配避免与 'Inbox' 等含 'box' 子串的元素撞车。
    expect(find.text('acme / gitee-box'), findsOneWidget);
    await tester.enterText(
      find.descendant(of: find.byType(ReposPage), matching: find.byType(TextField)),
      '',
    );
    await tester.pump();

    // 排序菜单:4 个模式都在。
    await tester.tap(find.descendant(
      of: find.byType(ReposPage),
      matching: find.byIcon(Icons.sort),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Recently updated'), findsOneWidget);
    expect(find.text('Name A→Z'), findsOneWidget);
    expect(find.text('Most stars'), findsOneWidget);
    expect(find.text('Most open PRs'), findsOneWidget);
    // 选中非默认项 'Name A→Z' 让菜单自动关闭,顺便验证选中后页面重排。
    await tester.tap(find.text('Name A→Z').last);
    await tester.pumpAndSettle();

    // Hide archived 默认 OFF,两个 GitHub 仓库都可见。全文匹配避免 'box' 子串撞车。
    expect(find.text('acme / archived-box'), findsOneWidget);
    expect(find.text('acme / box'), findsOneWidget);
    await tester.tap(find.descendant(
      of: find.byType(ReposPage),
      matching: find.widgetWithText(FilterChip, 'Hide archived'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('acme / archived-box'), findsNothing);
    expect(find.text('acme / box'), findsOneWidget);
  });

  testWidgets('repos row shows open PR count pill from inbox', (tester) async {
    final account = sampleAccount();
    // inbox 里两条 acme/box 的 open PR,触发 open-PR pill 显示。
    final pr1 = samplePr(id: 'github:a:acme/box:1', number: 1, title: 'PR one', accountId: account.id);
    final pr2 = samplePr(id: 'github:a:acme/box:2', number: 2, title: 'PR two', accountId: account.id);
    final store = await makeStore(
      accounts: [account],
      adapters: {
        ForgePlatform.github: FakeAdapter(
          platform: ForgePlatform.github,
          inbox: [pr1, pr2],
          repos: [
            sampleRepo(accountId: account.id),
            sampleRepo(
              id: 'r-empty',
              accountId: account.id,
              fullName: 'acme/empty',
              webUrl: 'https://github.com/acme/empty',
            ),
          ],
        ),
        ForgePlatform.gitee: FakeAdapter(platform: ForgePlatform.gitee),
      },
    );
    await tester.pumpWidget(CodeInboxApp(store: store));
    await store.refreshInbox();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Repos'));
    await tester.pumpAndSettle();
    // acme/box 有 2 个 open PR,显示 '2 open' pill;acme/empty 是 0,不显示 pill。
    expect(find.text('2 open'), findsOneWidget);
    expect(find.text('0 open'), findsNothing);
  });

  testWidgets('Chinese locale renders localized strings on welcome and inbox', (tester) async {
    final store = await makeStore(adapters: {
      ForgePlatform.github: FakeAdapter(platform: ForgePlatform.github),
      ForgePlatform.gitee: FakeAdapter(platform: ForgePlatform.gitee),
    });
    // 强制 zh_CN locale,验证 AppLocalizations.of(context) 走 zh 分支。
    await tester.pumpWidget(CodeInboxApp(store: store, locale: const Locale('zh', 'CN')));
    expect(find.text('添加 GitHub'), findsOneWidget);
    expect(find.text('添加 CODING'), findsOneWidget);
    expect(find.text('统一收件箱:GitHub / Gitee / GitLab / Codeup / 工蜂 / CODING 的评审请求一处看完。'),
        findsOneWidget);
  });

  testWidgets('Chinese locale renders localized tabs after accounts exist', (tester) async {
    final account = sampleAccount();
    final store = await makeStore(
      accounts: [account],
      adapters: {
        ForgePlatform.github: FakeAdapter(
          platform: ForgePlatform.github,
          inbox: [samplePr(accountId: account.id)],
        ),
        ForgePlatform.gitee: FakeAdapter(platform: ForgePlatform.gitee),
      },
    );
    await tester.pumpWidget(CodeInboxApp(store: store, locale: const Locale('zh', 'CN')));
    await tester.pumpAndSettle();
    expect(find.text('收件箱'), findsWidgets);
    expect(find.text('通知'), findsWidgets);
    expect(find.text('仓库'), findsWidgets);
    expect(find.text('我的'), findsWidgets);
  });

  testWidgets('tapping an account tile opens detail sheet with selectable values', (tester) async {
    final github = sampleAccount(id: 'g1', login: 'octocat');
    final store = await makeStore(
      accounts: [github],
      adapters: {ForgePlatform.github: FakeAdapter(platform: ForgePlatform.github)},
    );
    await tester.pumpWidget(CodeInboxApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accounts'));
    await tester.pumpAndSettle();
    // 点账号 tile:用 widgetWithText 精确定位到包含 'octocat' 的 ListTile。
    // ListTile.first 会命中底部 tab scaffold 的 ListTile 而不是账号行。
    await tester.tap(find.widgetWithText(ListTile, 'octocat'), warnIfMissed: false);
    await tester.pumpAndSettle();
    // sheet 出现:登录名作为 header + Username / Auth type / Account ID 字段都在
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Auth type'), findsOneWidget);
    expect(find.text('Account ID'), findsOneWidget);
    // octocat 在 header(login)和 ListTile.title 里都出现,至少 2 个
    expect(find.text('octocat'), findsWidgets);
    // 旧版的复制按钮已移除
    expect(find.text('Copy username'), findsNothing);
    // value 用 Text 包在 SelectionArea 内(系统长按菜单靠 SelectionArea 弹)
    expect(find.byType(SelectionArea), findsOneWidget);
  });
}
