import 'package:flutter/material.dart';

import '../domain/forge_adapter.dart';
import '../domain/models.dart';
import '../l10n/gen/app_localizations.dart';
import '../store.dart';
import 'widgets.dart';

/// 仓库 Issue 详情:标题 / state chip / labels / assignees / body / 顶部评论。
/// 无 review bar(无 PR 的 approve/request changes/merge 概念)。
class IssueDetailPage extends StatefulWidget {
  const IssueDetailPage({super.key, required this.summary});

  final Issue summary;

  @override
  State<IssueDetailPage> createState() => _IssueDetailPageState();
}

class _IssueDetailPageState extends State<IssueDetailPage> {
  Future<IssueDetail>? _future;
  int _loadGen = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppScope.of(context).loadIssueDetail(widget.summary);
  }

  void _reload() {
    setState(() {
      _loadGen++;
      _future = AppScope.of(context).loadIssueDetail(widget.summary);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<IssueDetail>(
      key: ValueKey<int>(_loadGen),
      future: _future,
      builder: (context, snap) {
        final detail = snap.data;
        final issue = detail?.issue ?? widget.summary;
        return Scaffold(
          appBar: AppBar(
            title: Text('${issue.repoFullName} #${issue.localNumber}'),
            actions: [
              if (issue.webUrl.isNotEmpty)
                IconButton(
                  tooltip: l10n.openInBrowser,
                  onPressed: () => store.openWeb(issue.webUrl),
                  icon: const Icon(Icons.open_in_browser),
                ),
            ],
          ),
          body: _body(context, store, snap, detail, issue),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    AppStore store,
    AsyncSnapshot<IssueDetail> snap,
    IssueDetail? detail,
    Issue issue,
  ) {
    final l10n = AppLocalizations.of(context);
    if (snap.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snap.hasError) {
      final message = snap.error is AdapterException
          ? (snap.error as AdapterException).message ?? l10n.repoDetailLoadFailed
          : l10n.repoDetailLoadFailed;
      return ListView(
        children: [
          ErrorBanner(message: message, onRetry: _reload),
          if (issue.webUrl.isNotEmpty)
            ListTile(
              title: Text(l10n.openInBrowser),
              trailing: const Icon(Icons.open_in_browser),
              onTap: () => store.openWeb(issue.webUrl),
            ),
        ],
      );
    }
    final account = store.accounts.where((a) => a.id == issue.accountId).firstOrNull;
    final comments = detail?.comments ?? const <IssueComment>[];
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(issue.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: Icon(
                      issue.state == IssueState.open ? Icons.error_outline : Icons.check_circle_outline,
                      size: 16,
                    ),
                    label: Text(issueStateLabel(l10n, issue.state)),
                    visualDensity: VisualDensity.compact,
                  ),
                  for (final label in issue.labels)
                    Chip(label: Text(label), visualDensity: VisualDensity.compact),
                ],
              ),
              const SizedBox(height: 8),
              PlatformBadge(platform: issue.platform, accountLabel: account?.label),
              const SizedBox(height: 8),
              Text(
                l10n.issueDetailMetaLine(issue.authorLogin, _ymd(issue.createdAt)),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (issue.assignees.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.issueDetailAssignees(issue.assignees.join(', ')),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        if (issue.body != null && issue.body!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SelectableText(issue.body!),
          ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            l10n.issueDetailCommentsHeader(comments.length),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        if (comments.isEmpty)
          ListTile(dense: true, title: Text(l10n.issueDetailNoComments)),
        for (final c in comments)
          ListTile(
            title: Text(c.authorLogin),
            subtitle: Text(c.body),
            isThreeLine: c.body.split('\n').length > 1,
          ),
      ],
    );
  }
}

/// Locale-aware Issue 状态标签。
String issueStateLabel(AppLocalizations l10n, IssueState state) => switch (state) {
      IssueState.open => l10n.issueStateOpen,
      IssueState.closed => l10n.issueStateClosed,
    };

String _ymd(DateTime t) {
  final u = t.toUtc();
  final m = u.month.toString().padLeft(2, '0');
  final d = u.day.toString().padLeft(2, '0');
  return '${u.year}-$m-$d';
}
