import 'models.dart';

/// Dedupes by [ChangeRequest.id], ORs review/assignment flags, newest first.
List<ChangeRequest> mergeInbox(Iterable<ChangeRequest> items) {
  final map = <String, ChangeRequest>{};
  for (final item in items) {
    final prev = map[item.id];
    if (prev == null) {
      map[item.id] = item;
      continue;
    }
    final newer = item.updatedAt.isAfter(prev.updatedAt) ? item : prev;
    map[item.id] = newer.copyWith(
      reviewRequested: prev.reviewRequested || item.reviewRequested,
      assignedToMe: prev.assignedToMe || item.assignedToMe,
      updatedAt: newer.updatedAt,
    );
  }
  final list = map.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return list;
}

List<ChangeRequest> applyInboxFilter(List<ChangeRequest> items, InboxFilter filter) {
  return items.where((item) {
    if (filter.platform != null && item.platform != filter.platform) return false;
    if (filter.onlyReviewRequested && !item.reviewRequested) return false;
    return true;
  }).toList();
}
