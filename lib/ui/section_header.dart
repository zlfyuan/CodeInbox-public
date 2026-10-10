import 'package:flutter/material.dart';

/// Pinned group title for Repos (and any other sliver list).
class SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  SectionHeaderDelegate(this.title);

  final String title;

  @override
  double get minExtent => 36;

  @override
  double get maxExtent => 36;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      elevation: overlapsContent ? 1 : 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(SectionHeaderDelegate oldDelegate) => oldDelegate.title != title;
}
