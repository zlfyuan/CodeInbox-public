import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/forge_adapter.dart';
import '../domain/models.dart';
import '../l10n/gen/app_localizations.dart';
import '../store.dart';
import 'issue_detail_page.dart';
import 'pr_detail_page.dart';
import 'readme_view.dart';
import 'widgets.dart';

/// Identity + README on Overview; open PRs on the second tab; Issues on the
/// third when the platform supports it. Tab count is computed at build time
/// from adapter.supportedCapabilities so unsupported surfaces are hidden
/// rather than shown as empty.
class RepoDetailPage extends StatefulWidget {
  const RepoDetailPage({super.key, required this.repo});

  final Repo repo;

  @override
  State<RepoDetailPage> createState() => _RepoDetailPageState();
}

class _RepoDetailPageState extends State<RepoDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Future<List<ChangeRequest>>? _pulls;
  Future<String?>? _readme;
  Future<List<Issue>>? _issues;
  Future<List<Branch>>? _branches;
  Future<List<GitCommit>>? _commits;
  Future<List<Contributor>>? _contributors;
  int _loadGen = 0;
  bool _readmeExpanded = false;
  // B-batch commit 3:Star 本地乐观状态。初始 null(未拉过),按一下锁定
  // optimistic = true(标星),失败回滚到 false。不在 AppStore 持久化,离开页面释放。
  bool? _starred = false;
  bool _starBusy = false;

  // B-batch 5 tab 上限:概览 / PR / Issues / 代码 / 贡献者。
  static const _tabCount = 5;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabCount, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = AppScope.of(context);
    _pulls ??= store.loadRepoPulls(widget.repo);
    _readme ??= store.loadRepoReadme(widget.repo);
    _issues ??= store.loadRepoIssues(widget.repo);
    _branches ??= store.loadRepoBranches(widget.repo);
    _commits ??= store.loadRepoCommits(widget.repo);
    _contributors ??= store.loadRepoContributors(widget.repo);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _reloadPulls() {
    setState(() {
      _loadGen++;
      _pulls = AppScope.of(context).loadRepoPulls(widget.repo);
    });
  }

  void _reloadIssues() {
    setState(() {
      _issues = AppScope.of(context).loadRepoIssues(widget.repo);
    });
  }

  void _reloadBranches() {
    setState(() {
      _branches = AppScope.of(context).loadRepoBranches(widget.repo);
    });
  }

  void _reloadCommits() {
    setState(() {
      _commits = AppScope.of(context).loadRepoCommits(widget.repo);
    });
  }

  void _reloadContributors() {
    setState(() {
      _contributors = AppScope.of(context).loadRepoContributors(widget.repo);
    });
  }

  Future<void> _toggleStar() async {
    if (_starBusy) return;
    final store = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final repo = widget.repo;
    final wasStarred = _starred ?? false;
    setState(() {
      _starred = !wasStarred;
      _starBusy = true;
    });
    try {
      if (!wasStarred) {
        await store.starRepo(repo);
      } else {
        await store.unstarRepo(repo);
      }
    } on AdapterException catch (e) {
      if (!mounted) return;
      // 乐观状态回滚 + 错误 SnackBar。message 已由 http_client 翻译,这里直接用。
      setState(() => _starred = wasStarred);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? l10n.repoDetailStarFailed)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _starred = wasStarred);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.repoDetailStarFailed)),
      );
    } finally {
      if (mounted) setState(() => _starBusy = false);
    }
  }

  void _reloadReadme() {
    setState(() {
      _readme = AppScope.of(context).loadRepoReadme(widget.repo);
      _readmeExpanded = false;
    });
  }

  void _showActionsSheet() {
    final store = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final repo = widget.repo;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_browser),
              title: Text(l10n.repoDetailSheetOpenInBrowser),
              onTap: () {
                Navigator.pop(ctx);
                store.openWeb(repo.webUrl);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(l10n.repoDetailSheetCopyWebUrl),
              onTap: () async {
                Navigator.pop(ctx);
                await Clipboard.setData(ClipboardData(text: repo.webUrl));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.repoDetailWebUrlCopied)),
                );
              },
            ),
            if (repo.cloneUrl != null && repo.cloneUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy_all),
                title: Text(l10n.repoDetailSheetCopyCloneUrlHttps),
                trailing: Text('HTTPS', style: Theme.of(ctx).textTheme.labelSmall),
                onTap: () => _copyAndPop(ctx, repo.cloneUrl!, l10n.repoDetailCloneUrlCopied),
              ),
            if (repo.sshUrl != null && repo.sshUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy_all),
                title: Text(l10n.repoDetailSheetCopyCloneUrlSsh),
                trailing: Text('SSH', style: Theme.of(ctx).textTheme.labelSmall),
                onTap: () => _copyAndPop(ctx, repo.sshUrl!, l10n.repoDetailCloneUrlCopied),
              ),
          ],
        ),
      ),
    );
  }

  void _copyAndPop(BuildContext sheetCtx, String text, String snackText) {
    final outer = context;
    Navigator.pop(sheetCtx);
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(outer).showSnackBar(SnackBar(content: Text(snackText)));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final repo = widget.repo;
    final account = store.accounts.where((a) => a.id == repo.accountId).firstOrNull;
    final caps = store.adapters.forPlatform(repo.platform).supportedCapabilities;
    final showIssues = caps.contains(RepoCapability.issues);
    final showCode = caps.contains(RepoCapability.branches) || caps.contains(RepoCapability.commits);
    final showContributors = caps.contains(RepoCapability.contributors);
    // TabController 长度是 5,缺失的 slot 在 TabBarView 里换 SizedBox.shrink()。
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(repo.repoName, overflow: TextOverflow.ellipsis),
            if (repo.owner.isNotEmpty && repo.owner != repo.repoName)
              Text(repo.owner, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        actions: [
          if (repo.webUrl.isNotEmpty)
            IconButton(
              tooltip: l10n.openInBrowser,
              onPressed: () => store.openWeb(repo.webUrl),
              icon: const Icon(Icons.open_in_browser),
            ),
          if (caps.contains(RepoCapability.star))
            IconButton(
              tooltip: (_starred ?? false) ? l10n.repoDetailUnstarTooltip : l10n.repoDetailStarTooltip,
              onPressed: _starBusy ? null : _toggleStar,
              icon: (_starred ?? false) ? const Icon(Icons.star) : const Icon(Icons.star_border),
            ),
          IconButton(
            onPressed: _showActionsSheet,
            icon: const Icon(Icons.more_vert),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.repoDetailTabOverview),
            FutureBuilder<List<ChangeRequest>>(
              key: ValueKey<int>(_loadGen),
              future: _pulls,
              builder: (context, snap) {
                final n = snap.data?.length;
                return n == null
                    ? Tab(text: l10n.repoDetailTabPullRequests)
                    : Tab(text: l10n.repoDetailTabPullRequestsCount(n));
              },
            ),
            if (showIssues)
              FutureBuilder<List<Issue>>(
                future: _issues,
                builder: (context, snap) {
                  final n = snap.data?.length;
                  return n == null
                      ? Tab(text: l10n.repoDetailTabIssues)
                      : Tab(text: l10n.repoDetailTabIssuesCount(n));
                },
              ),
            if (showCode)
              Tab(text: l10n.repoDetailTabCode),
            if (showContributors)
              FutureBuilder<List<Contributor>>(
                future: _contributors,
                builder: (context, snap) {
                  final n = snap.data?.length;
                  return n == null
                      ? Tab(text: l10n.repoDetailTabContributors)
                      : Tab(text: '${l10n.repoDetailTabContributors} ($n)');
                },
              ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(
            repo: repo,
            accountLabel: account?.label,
            store: store,
            readme: _readme,
            expanded: _readmeExpanded,
            onToggleReadme: () => setState(() => _readmeExpanded = !_readmeExpanded),
            onRetryReadme: _reloadReadme,
          ),
          _PullsTab(
            repo: repo,
            future: _pulls,
            loadGen: _loadGen,
            onRetry: _reloadPulls,
          ),
          if (showIssues)
            _IssuesTab(
              repo: repo,
              future: _issues,
              onRetry: _reloadIssues,
            )
          else
            const SizedBox.shrink(),
          if (showCode)
            _CodeTab(
              branches: _branches,
              commits: _commits,
              onRetryBranches: _reloadBranches,
              onRetryCommits: _reloadCommits,
            )
          else
            const SizedBox.shrink(),
          if (showContributors)
            _ContributorsTab(
              repo: repo,
              future: _contributors,
              onRetry: _reloadContributors,
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.repo,
    required this.store,
    required this.readme,
    required this.expanded,
    required this.onToggleReadme,
    required this.onRetryReadme,
    this.accountLabel,
  });

  final Repo repo;
  final AppStore store;
  final String? accountLabel;
  final Future<String?>? readme;
  final bool expanded;
  final VoidCallback onToggleReadme;
  final VoidCallback onRetryReadme;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        PlatformBadge(platform: repo.platform, accountLabel: accountLabel),
        const SizedBox(height: 8),
        Text(repo.fullName, style: Theme.of(context).textTheme.titleLarge),
        if (repo.description != null) ...[
          const SizedBox(height: 6),
          Text(repo.description!, style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: Icon(repo.private ? Icons.lock_outline : Icons.public, size: 16),
              label: Text(repoVisibilityLabel(l10n, repo.visibility)),
              visualDensity: VisualDensity.compact,
            ),
            if (repo.archived)
              Chip(
                avatar: const Icon(Icons.archive_outlined, size: 16),
                label: Text(l10n.repoMetaArchived),
                visualDensity: VisualDensity.compact,
              ),
            if (repo.fork)
              Chip(
                avatar: const Icon(Icons.call_split, size: 16),
                label: Text(l10n.repoMetaFork),
                visualDensity: VisualDensity.compact,
              ),
            if (repo.language != null)
              Chip(
                avatar: const Icon(Icons.code, size: 16),
                label: Text(repo.language!),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(child: _Stat(icon: Icons.star_outline, value: '${repo.starCount}', label: l10n.repoDetailStatStars)),
                Expanded(child: _Stat(icon: Icons.call_split, value: '${repo.forkCount}', label: l10n.repoDetailStatForks)),
                Expanded(child: _Stat(icon: Icons.adjust, value: '${repo.openIssueCount}', label: l10n.repoDetailStatIssues)),
                if (repo.subscribersCount != null)
                  Expanded(
                    child: _Stat(
                      icon: Icons.notifications_active_outlined,
                      value: '${repo.subscribersCount}',
                      label: l10n.repoDetailStatSubscribers,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _Meta(icon: Icons.alt_route, text: repo.defaultBranch),
            if (repo.license != null) _Meta(icon: Icons.balance, text: repo.license!),
            if (repo.createdAt != null) _Meta(icon: Icons.calendar_today_outlined, text: l10n.repoDetailMetaCreated(_ymd(repo.createdAt!))),
            _Meta(icon: Icons.update, text: l10n.repoDetailMetaUpdated(_ymd(repo.updatedAt))),
          ],
        ),
        if (repo.homepage != null) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => store.openWeb(repo.homepage!),
            child: _Meta(icon: Icons.link, text: _displayUrl(repo.homepage!), accent: true),
          ),
        ],
        if (repo.topics.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final topic in repo.topics)
                Chip(label: Text(topic), visualDensity: VisualDensity.compact),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Text(l10n.repoDetailReadmeHeader, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        FutureBuilder<String?>(
          future: readme,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              final message = snap.error is AdapterException
                  ? (snap.error as AdapterException).message ?? l10n.repoDetailLoadFailedReadme
                  : l10n.repoDetailLoadFailedReadme;
              return ErrorBanner(message: message, onRetry: onRetryReadme);
            }
            final markdown = snap.data;
            if (markdown == null || markdown.trim().isEmpty) {
              return Text(
                l10n.repoDetailReadmeEmpty,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              );
            }
            const previewAt = 1800;
            final long = markdown.length > previewAt;
            final shown = !expanded && long ? _preview(markdown, previewAt) : markdown;
            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ReadmeView(markdown: shown, onOpenUrl: store.openWeb),
                    if (long)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: onToggleReadme,
                          child: Text(expanded ? l10n.repoDetailShowLess : l10n.repoDetailShowMore),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PullsTab extends StatelessWidget {
  const _PullsTab({
    required this.repo,
    required this.future,
    required this.loadGen,
    required this.onRetry,
  });

  final Repo repo;
  final Future<List<ChangeRequest>>? future;
  final int loadGen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<ChangeRequest>>(
      key: ValueKey<int>(loadGen),
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          final message = snap.error is AdapterException
              ? (snap.error as AdapterException).message ?? l10n.repoDetailLoadFailed
              : l10n.repoDetailLoadFailed;
          return ListView(children: [ErrorBanner(message: message, onRetry: onRetry)]);
        }
        final items = snap.data ?? const <ChangeRequest>[];
        if (items.isEmpty) {
          return ListView(
            children: [
              ListTile(
                title: Text(l10n.repoDetailNoOpenPrs),
                subtitle: Text(l10n.repoDetailNoOpenPrsSubtitle(repo.fullName)),
              ),
            ],
          );
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final cr = items[i];
            return ListTile(
              leading: CircleAvatar(
                radius: 16,
                child: Text('#${cr.localNumber}', style: const TextStyle(fontSize: 11)),
              ),
              title: Text(cr.title),
              subtitle: Text(
                [
                  cr.authorLogin,
                  if (cr.draft) l10n.repoDetailDraft,
                  if (cr.sourceBranch.isNotEmpty && cr.targetBranch.isNotEmpty)
                    '${cr.sourceBranch} → ${cr.targetBranch}',
                  _ymd(cr.updatedAt),
                ].join(' · '),
              ),
              isThreeLine: true,
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => PrDetailPage(summary: cr),
              )),
            );
          },
        );
      },
    );
  }
}

class _IssuesTab extends StatelessWidget {
  const _IssuesTab({
    required this.repo,
    required this.future,
    required this.onRetry,
  });

  final Repo repo;
  final Future<List<Issue>>? future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<Issue>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          final message = snap.error is AdapterException
              ? (snap.error as AdapterException).message ?? l10n.repoDetailLoadFailed
              : l10n.repoDetailLoadFailed;
          return ListView(children: [ErrorBanner(message: message, onRetry: onRetry)]);
        }
        final items = snap.data ?? const <Issue>[];
        if (items.isEmpty) {
          return ListView(
            children: [
              ListTile(
                title: Text(l10n.repoDetailNoOpenIssues),
                subtitle: Text(l10n.repoDetailNoOpenIssuesSubtitle(repo.fullName)),
              ),
            ],
          );
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final issue = items[i];
            return ListTile(
              leading: CircleAvatar(
                radius: 16,
                child: Text('#${issue.localNumber}', style: const TextStyle(fontSize: 11)),
              ),
              title: Text(issue.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                [
                  issue.authorLogin,
                  if (issue.labels.isNotEmpty) issue.labels.join(', '),
                  _ymd(issue.updatedAt),
                ].join(' · '),
              ),
              isThreeLine: issue.labels.isNotEmpty,
              trailing: issue.state == IssueState.closed
                  ? const Icon(Icons.check_circle_outline, size: 18)
                  : null,
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => IssueDetailPage(summary: issue),
              )),
            );
          },
        );
      },
    );
  }
}

/// 代码 tab:两个独立 section(branches + commits),任一抛 unsupported 时整 tab
/// 降级为「该平台暂不支持代码浏览」卡片(由父级 showCode 守卫 + capability 决定)。
class _CodeTab extends StatelessWidget {
  const _CodeTab({
    required this.branches,
    required this.commits,
    required this.onRetryBranches,
    required this.onRetryCommits,
  });

  final Future<List<Branch>>? branches;
  final Future<List<GitCommit>>? commits;
  final VoidCallback onRetryBranches;
  final VoidCallback onRetryCommits;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _BranchesSection(future: branches, onRetry: onRetryBranches),
        const SizedBox(height: 8),
        _CommitsSection(future: commits, onRetry: onRetryCommits),
      ],
    );
  }
}

class _BranchesSection extends StatelessWidget {
  const _BranchesSection({required this.future, required this.onRetry});

  final Future<List<Branch>>? future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<Branch>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          final message = snap.error is AdapterException
              ? (snap.error as AdapterException).message ?? l10n.repoDetailLoadFailed
              : l10n.repoDetailLoadFailed;
          return ErrorBanner(message: message, onRetry: onRetry);
        }
        final items = snap.data ?? const <Branch>[];
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(l10n.repoDetailNoBranches, style: Theme.of(context).textTheme.bodyMedium),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.repoDetailCodeBranchesHeader(items.length),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            for (final b in items)
              ListTile(
                dense: true,
                title: Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(b.commitSha.length >= 7 ? b.commitSha.substring(0, 7) : b.commitSha,
                    style: Theme.of(context).textTheme.labelSmall),
                trailing: b.protected
                    ? Chip(
                        label: Text(l10n.repoDetailBranchProtected),
                        visualDensity: VisualDensity.compact,
                      )
                    : null,
              ),
          ],
        );
      },
    );
  }
}

class _CommitsSection extends StatelessWidget {
  const _CommitsSection({required this.future, required this.onRetry});

  final Future<List<GitCommit>>? future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<GitCommit>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          final message = snap.error is AdapterException
              ? (snap.error as AdapterException).message ?? l10n.repoDetailLoadFailed
              : l10n.repoDetailLoadFailed;
          return ErrorBanner(message: message, onRetry: onRetry);
        }
        final items = snap.data ?? const <GitCommit>[];
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(l10n.repoDetailNoCommits, style: Theme.of(context).textTheme.bodyMedium),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.repoDetailCodeCommitsHeader(items.length),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            for (final c in items)
              ListTile(
                dense: true,
                title: Text(c.messageFirstLine, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${c.authorName} · ${_ymd(c.authoredAt)} · ${c.shortSha}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                onTap: c.webUrl.isEmpty ? null : () => AppScope.of(context).openWeb(c.webUrl),
              ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.accent = false});

  final IconData icon;
  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: accent ? scheme.primary : null,
                ),
          ),
        ),
      ],
    );
  }
}

String _ymd(DateTime t) {
  final u = t.toUtc();
  final m = u.month.toString().padLeft(2, '0');
  final d = u.day.toString().padLeft(2, '0');
  return '${u.year}-$m-$d';
}

String _displayUrl(String url) {
  return url.replaceFirst(RegExp(r'^https?://'), '');
}

String _preview(String src, int limit) {
  if (src.length <= limit) return src;
  final cut = src.lastIndexOf('\n', limit);
  return src.substring(0, cut > 400 ? cut : limit);
}

/// 贡献者 tab:头像 + login + 贡献数。onTap 跳 GitHub profile。
class _ContributorsTab extends StatelessWidget {
  const _ContributorsTab({
    required this.repo,
    required this.future,
    required this.onRetry,
  });

  final Repo repo;
  final Future<List<Contributor>>? future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<Contributor>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          final message = snap.error is AdapterException
              ? (snap.error as AdapterException).message ?? l10n.repoDetailLoadFailed
              : l10n.repoDetailLoadFailed;
          return ListView(children: [ErrorBanner(message: message, onRetry: onRetry)]);
        }
        final items = snap.data ?? const <Contributor>[];
        if (items.isEmpty) {
          return ListView(
            children: [
              ListTile(
                title: Text(l10n.repoDetailNoContributors),
                subtitle: Text(l10n.repoDetailNoContributorsSubtitle(repo.fullName)),
              ),
            ],
          );
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final c = items[i];
            return ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: scheme.surfaceContainerHighest,
                backgroundImage: (c.avatarUrl != null && c.avatarUrl!.isNotEmpty)
                    ? NetworkImage(c.avatarUrl!)
                    : null,
                child: c.avatarUrl == null || c.avatarUrl!.isEmpty
                    ? Text(c.login.isNotEmpty ? c.login[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 12))
                    : null,
              ),
              title: Text(c.login),
              subtitle: Text(l10n.repoDetailContributions(c.contributionCount)),
              onTap: c.profileUrl.isEmpty
                  ? null
                  : () => AppScope.of(context).openWeb(c.profileUrl),
            );
          },
        );
      },
    );
  }
}