import 'package:codeinbox/domain/inbox.dart';
import 'package:codeinbox/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  test('mergeInbox dedupes by id and ORs flags', () {
    final a = samplePr(reviewRequested: true, assignedToMe: false);
    final b = samplePr(
      reviewRequested: false,
      assignedToMe: true,
      updatedAt: DateTime.utc(2026, 9, 15),
    );
    final merged = mergeInbox([a, b]);
    expect(merged, hasLength(1));
    expect(merged.single.reviewRequested, isTrue);
    expect(merged.single.assignedToMe, isTrue);
    expect(merged.single.updatedAt, DateTime.utc(2026, 9, 15));
  });

  test('mergeInbox sorts newest first', () {
    final older = samplePr(
      id: 'github:a:acme/box:1',
      number: 1,
      title: 'old',
      updatedAt: DateTime.utc(2026, 9, 1),
    );
    final newer = samplePr(
      id: 'github:a:acme/box:2',
      number: 2,
      title: 'new',
      updatedAt: DateTime.utc(2026, 9, 10),
    );
    final merged = mergeInbox([older, newer]);
    expect(merged.map((e) => e.title).toList(), ['new', 'old']);
  });

  test('applyInboxFilter by platform and review', () {
    final items = [
      samplePr(reviewRequested: true),
      samplePr(
        id: 'gitee:b:acme/box:3',
        number: 3,
        platform: ForgePlatform.gitee,
        accountId: 'b',
        reviewRequested: false,
        assignedToMe: true,
        title: 'gitee pr',
      ),
    ];
    expect(applyInboxFilter(items, const InboxFilter(platform: ForgePlatform.gitee)), hasLength(1));
    expect(applyInboxFilter(items, const InboxFilter(onlyReviewRequested: true)), hasLength(1));
  });
}
