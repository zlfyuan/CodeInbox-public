import 'package:flutter/material.dart';

import '../domain/local_search.dart';
import '../domain/models.dart';
import '../l10n/gen/app_localizations.dart';
import '../store.dart';
import 'add_account_page.dart';
import 'local_search_field.dart';
import 'platform_filter_bar.dart';
import 'pr_detail_page.dart';
import 'widgets.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final items = store.filteredInbox.where((e) => inboxMatchesQuery(e, _query)).toList();
    final platforms = store.accounts.map((a) => a.platform).toSet();
    final searching = _query.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.inboxTitle)),
      body: Column(
        children: [
          PlatformFilterBar(
            platforms: platforms,
            selected: store.inboxFilter.platform,
            allSelected: store.inboxFilter.platform == null && !store.inboxFilter.onlyReviewRequested,
            onSelected: (platform) => store.setInboxFilter(InboxFilter(platform: platform)),
            trailing: [
              FilterChip(
                label: Text(l10n.inboxFilterNeedsReview),
                selected: store.inboxFilter.onlyReviewRequested,
                onSelected: (v) => store.setInboxFilter(store.inboxFilter.copyWith(onlyReviewRequested: v)),
              ),
            ],
          ),
          LocalSearchField(
            controller: _search,
            hint: l10n.inboxSearchHint,
            onChanged: (q) => setState(() => _query = q),
          ),
          if (store.inboxError != null) ErrorBanner(message: store.inboxError!, onRetry: store.refreshInbox),
          Expanded(
            child: RefreshIndicator(
              onRefresh: store.refreshInbox,
              child: items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 360,
                          child: searching
                              ? EmptyState(
                                  title: l10n.inboxNoMatchesTitle,
                                  subtitle: l10n.inboxNoMatchesSubtitle,
                                )
                              : EmptyState(
                                  title: store.inboxLoading ? l10n.inboxLoadingTitle : l10n.inboxAllCaughtUpTitle,
                                  subtitle: store.accounts.length < 2
                                      ? l10n.inboxAllCaughtUpSubtitleSingle
                                      : l10n.inboxAllCaughtUpSubtitleGitee,
                                  action: store.accounts.length < 2
                                      ? FilledButton.tonal(
                                          onPressed: () {
                                            final have = store.accounts.map((a) => a.platform).toSet();
                                            final missing = ForgePlatform.values.firstWhere(
                                              (p) => !have.contains(p),
                                              orElse: () => ForgePlatform.gitlab,
                                            );
                                            Navigator.of(context).push(MaterialPageRoute<void>(
                                              builder: (_) => AddAccountPage(platform: missing),
                                            ));
                                          },
                                          child: Text(l10n.inboxAddAnotherPlatform),
                                        )
                                      : null,
                                ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length + (store.inboxHasMore && !searching ? 1 : 0),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        if (i == items.length) {
                          return ListTile(
                            title: store.inboxLoadingMore
                                ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                                : Text(l10n.inboxLoadMore),
                            onTap: store.inboxLoadingMore ? null : store.loadMoreInbox,
                          );
                        }
                        final item = items[i];
                        final account = store.accounts.where((a) => a.id == item.accountId).firstOrNull;
                        return ListTile(
                          title: Text(item.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${item.repoFullName} #${item.localNumber}'),
                              const SizedBox(height: 4),
                              PlatformBadge(platform: item.platform, accountLabel: account?.label),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => PrDetailPage(summary: item),
                          )),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}