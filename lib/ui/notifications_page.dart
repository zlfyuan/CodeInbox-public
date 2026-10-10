import 'package:flutter/material.dart';

import '../domain/local_search.dart';
import '../domain/models.dart';
import '../l10n/gen/app_localizations.dart';
import '../store.dart';
import 'local_search_field.dart';
import 'platform_filter_bar.dart';
import 'pr_detail_page.dart';
import 'widgets.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _search = TextEditingController();
  String _query = '';
  ForgePlatform? _platform;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final platforms = store.accounts.map((a) => a.platform).toSet();
    final items = store.notifications.where((n) {
      if (_platform != null && n.platform != _platform) return false;
      return alertMatchesQuery(n, _query);
    }).toList();
    final searching = _query.trim().isNotEmpty || _platform != null;
    return Scaffold(
      // 标题靠左,避免 iOS 风格默认居中。
      appBar: AppBar(title: Text(l10n.alertsTitle), centerTitle: false),
      body: Column(
        children: [
          PlatformFilterBar(
            platforms: platforms,
            selected: _platform,
            onSelected: (platform) => setState(() => _platform = platform),
          ),
          LocalSearchField(
            controller: _search,
            hint: l10n.alertsSearchHint,
            onChanged: (q) => setState(() => _query = q),
          ),
          if (store.notificationsError != null)
            ErrorBanner(message: store.notificationsError!, onRetry: store.refreshNotifications),
          Expanded(
            child: RefreshIndicator(
              onRefresh: store.refreshNotifications,
              child: items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 360,
                          child: searching
                              ? EmptyState(
                                  title: l10n.alertsNoMatchesTitle,
                                  subtitle: l10n.alertsNoMatchesSubtitle,
                                )
                              : EmptyState(
                                  title: l10n.alertsNoUnreadTitle,
                                  subtitle: l10n.alertsNoUnreadSubtitle,
                                ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final item = items[i];
                        final account = store.accounts.where((a) => a.id == item.accountId).firstOrNull;
                        return ListTile(
                          title: Text(item.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (item.repoFullName != null) Text(item.repoFullName!),
                              const SizedBox(height: 4),
                              PlatformBadge(platform: item.platform, accountLabel: account?.label),
                            ],
                          ),
                          isThreeLine: item.repoFullName != null,
                          trailing: item.unread ? const Icon(Icons.circle, size: 10) : null,
                          onTap: () => _open(context, store, item),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, AppStore store, NotificationItem item) {
    final cr = item.toChangeRequest();
    if (cr != null) {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => PrDetailPage(summary: cr),
      ));
      return;
    }
    if (item.webUrl.isNotEmpty) store.openWeb(item.webUrl);
  }
}