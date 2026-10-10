import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../l10n/gen/app_localizations.dart';

/// Horizontal platform chips. [trailing] is extra chips such as "Needs my review".
class PlatformFilterBar extends StatelessWidget {
  const PlatformFilterBar({
    super.key,
    required this.platforms,
    required this.selected,
    required this.onSelected,
    this.allSelected,
    this.trailing = const [],
  });

  final Set<ForgePlatform> platforms;
  final ForgePlatform? selected;
  final ValueChanged<ForgePlatform?> onSelected;
  // When null, All is selected iff [selected] is null.
  final bool? allSelected;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allOn = allSelected ?? selected == null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        // mainAxisSize 默认 max,会让 Row 撑满 scroll viewport 宽度,
        // 内容少时视觉上像是水平居中。改成 min 让 Row 只占内容宽度,
        // 配合默认的 mainAxisAlignment: start 自然左对齐。
        mainAxisSize: MainAxisSize.min,
        children: [
          FilterChip(
            label: Text(l10n.filterAll),
            selected: allOn,
            onSelected: (_) => onSelected(null),
          ),
          for (final platform in ForgePlatform.values)
            if (platforms.contains(platform)) ...[
              const SizedBox(width: 8),
              FilterChip(
                label: Text(platformLabel(l10n, platform)),
                selected: selected == platform,
                onSelected: (_) => onSelected(platform),
              ),
            ],
          for (final chip in trailing) ...[
            const SizedBox(width: 8),
            chip,
          ],
        ],
      ),
    );
  }
}
