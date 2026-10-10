import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../l10n/gen/app_localizations.dart';
import '../theme.dart';

class PlatformBadge extends StatelessWidget {
  const PlatformBadge({super.key, required this.platform, this.accountLabel});

  final ForgePlatform platform;
  final String? accountLabel;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: platformDot(platform), shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(platformLabel(AppLocalizations.of(context), platform), style: style),
        if (accountLabel != null && accountLabel!.isNotEmpty) ...[
          Text(' · $accountLabel', style: style),
        ],
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(message, style: TextStyle(color: scheme.onErrorContainer, fontSize: 13)),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text(AppLocalizations.of(context).retry),
              ),
          ],
        ),
      ),
    );
  }
}
