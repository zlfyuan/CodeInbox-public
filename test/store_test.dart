import 'package:codeinbox/domain/models.dart';
import 'package:codeinbox/store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_adapter.dart';
import 'support.dart';

void main() {
  test('refreshNotifications synthesizes Alerts from Codeup inbox', () async {
    final account = sampleAccount(id: 'c', platform: ForgePlatform.codeup, login: 'coder');
    final pr = samplePr(
      id: 'codeup:c:acme/box:12',
      platform: ForgePlatform.codeup,
      accountId: 'c',
      webUrl: 'https://codeup.aliyun.com/acme/box/change/12',
    );
    final store = await makeStore(
      accounts: [account],
      adapters: {
        ForgePlatform.codeup: FakeAdapter(platform: ForgePlatform.codeup, inbox: [pr]),
      },
    );
    await store.refreshAll();
    expect(store.notifications, hasLength(1));
    expect(store.notifications.single.title, pr.title);
    expect(store.notifications.single.opensDetail, isTrue);
  });

  test('refreshNotifications keeps native Gongfeng events', () async {
    final account = sampleAccount(id: 'g', platform: ForgePlatform.gongfeng, login: 'coder');
    final pr = samplePr(
      id: 'gongfeng:g:9001',
      platform: ForgePlatform.gongfeng,
      accountId: 'g',
      webUrl: 'https://git.code.tencent.com/acme/box/merge_requests/12',
    );
    final native = NotificationItem(
      id: 'evt-1',
      platform: ForgePlatform.gongfeng,
      accountId: account.id,
      title: 'Native event',
      unread: true,
      webUrl: pr.webUrl,
      updatedAt: pr.updatedAt,
      relatedType: RelatedType.changeRequest,
      repoFullName: pr.repoFullName,
      localNumber: pr.localNumber,
    );
    final store = await makeStore(
      accounts: [account],
      adapters: {
        ForgePlatform.gongfeng: FakeAdapter(
          platform: ForgePlatform.gongfeng,
          inbox: [pr],
          notifications: [native],
        ),
      },
    );
    await store.refreshAll();
    expect(store.notifications, hasLength(1));
    expect(store.notifications.single.title, 'Native event');
  });

  test('loadMoreInbox appends the next page', () async {
    final account = sampleAccount();
    final page1 = [
      for (var i = 1; i <= AppStore.inboxPageSize; i++)
        samplePr(id: 'github:a:acme/box:$i', number: i, title: 'PR $i'),
    ];
    final store = await makeStore(
      accounts: [account],
      adapters: {
        ForgePlatform.github: FakeAdapter(
          platform: ForgePlatform.github,
          inbox: page1,
          inboxMore: [samplePr(id: 'github:a:acme/box:99', number: 99, title: 'Older PR')],
        ),
      },
    );
    await store.refreshInbox();
    expect(store.inbox, hasLength(AppStore.inboxPageSize));
    expect(store.inboxHasMore, isTrue);
    await store.loadMoreInbox();
    expect(store.inbox.any((e) => e.title == 'Older PR'), isTrue);
    expect(store.inboxHasMore, isFalse);
  });

  group('addAccount', () {
    test('adds the first GitHub account', () async {
      final store = await makeStore(adapters: {
        ForgePlatform.github: FakeAdapter(platform: ForgePlatform.github),
      });
      await store.addAccount(platform: ForgePlatform.github, token: 'ghs_test_***');
      expect(store.accounts, hasLength(1));
      expect(store.accounts.single.platform, ForgePlatform.github);
    });

    test('allows adding a second GitHub account', () async {
      final existing = sampleAccount();
      final store = await makeStore(
        accounts: [existing],
        adapters: {
          ForgePlatform.github: FakeAdapter(platform: ForgePlatform.github),
        },
      );
      await store.addAccount(platform: ForgePlatform.github, token: 'ghs_test_***');
      expect(store.accounts, hasLength(2));
    });

    test('allows adding a non-GitHub platform', () async {
      final store = await makeStore(adapters: {
        ForgePlatform.gitee: FakeAdapter(platform: ForgePlatform.gitee),
      });
      await store.addAccount(platform: ForgePlatform.gitee, token: 'ghs_test_***');
      expect(store.accounts.single.platform, ForgePlatform.gitee);
    });
  });
}
