import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/local_search.dart';
import '../domain/models.dart';
import '../l10n/gen/app_localizations.dart';
import '../store.dart';
import 'language_dot.dart';
import 'local_search_field.dart';
import 'platform_filter_bar.dart';
import 'repo_detail_page.dart';
import 'section_header.dart';
import 'widgets.dart';

/// 仓库列表的排序方式。本地页面 state,杀进程后回到默认 Updated。
enum RepoSortMode { updated, name, stars, openPrs }

extension on RepoSortMode {
  // 静态 label 不带 locale:排序菜单本身是状态标记,只是名字需要本地化。
  String label(AppLocalizations l10n) => switch (this) {
        RepoSortMode.updated => l10n.sortByUpdated,
        RepoSortMode.name => l10n.sortByName,
        RepoSortMode.stars => l10n.sortByStars,
        RepoSortMode.openPrs => l10n.sortByOpenPrs,
      };
}

class ReposPage extends StatefulWidget {
  const ReposPage({super.key});

  @override
  State<ReposPage> createState() => _ReposPageState();
}

class _ReposPageState extends State<ReposPage> {
  final _search = TextEditingController();
  String _query = '';
  RepoSortMode _sort = RepoSortMode.updated;
  bool _hideArchived = false;
  bool _publicOnly = false;
  // null = 显示所有平台(同 InboxPage 的语义)。
  ForgePlatform? _platformFilter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final openByRepo = _openPrCountByRepo(store);
    final groups = _buildGroups(store, openByRepo);
    final searching = _query.trim().isNotEmpty;
    final hasFilter = _platformFilter != null || _hideArchived || _publicOnly;
    final empty = groups.isEmpty;
    final platforms = store.accounts.map((a) => a.platform).toSet();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reposTitle),
        actions: [
          PopupMenuButton<RepoSortMode>(
            tooltip: l10n.sortByTooltip,
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (mode) => setState(() => _sort = mode),
            itemBuilder: (context) => [
              for (final mode in RepoSortMode.values)
                CheckedPopupMenuItem<RepoSortMode>(
                  value: mode,
                  checked: mode == _sort,
                  child: Text(mode.label(l10n)),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          PlatformFilterBar(
            platforms: platforms,
            selected: _platformFilter,
            // "All" 高亮只取决于平台筛选,不影响右侧 chip。
            allSelected: _platformFilter == null,
            onSelected: (p) => setState(() => _platformFilter = p),
            trailing: [
              FilterChip(
                label: Text(l10n.filterHideArchived),
                selected: _hideArchived,
                onSelected: (v) => setState(() => _hideArchived = v),
              ),
              FilterChip(
                label: Text(l10n.filterPublicOnly),
                selected: _publicOnly,
                onSelected: (v) => setState(() => _publicOnly = v),
              ),
            ],
          ),
          LocalSearchField(
            controller: _search,
            hint: l10n.reposSearchHint,
            onChanged: (q) => setState(() => _query = q),
          ),
          if (store.reposError != null) ErrorBanner(message: store.reposError!, onRetry: store.refreshRepos),
          Expanded(
            child: RefreshIndicator(
              onRefresh: store.refreshRepos,
              child: empty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 360,
                          child: searching
                              ? EmptyState(
                                  title: l10n.reposNoMatchesTitle,
                                  subtitle: l10n.reposNoMatchesSubtitle,
                                )
                              : hasFilter
                                  ? EmptyState(
                                      title: l10n.reposFilteredEmptyTitle,
                                      subtitle: l10n.reposFilteredEmptySubtitle,
                                    )
                                  : EmptyState(
                                      title: l10n.reposEmptyTitle,
                                      subtitle: l10n.reposEmptySubtitle,
                                    ),
                        ),
                      ],
                    )
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        for (final group in groups) ...[
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: SectionHeaderDelegate(group.title),
                          ),
                          SliverList.separated(
                            itemCount: group.repos.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final item = group.repos[i];
                              final account =
                                  store.accounts.where((a) => a.id == item.accountId).firstOrNull;
                              return _Row(
                                repo: item,
                                accountLabel: account?.label,
                                openPrCount:
                                    openByRepo['${item.accountId}/${item.fullName}'] ?? 0,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => RepoDetailPage(repo: item),
                                  ),
                                ),
                                onLongPress: () => _showSheet(context, store, item, l10n),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 从本地 inbox 聚合每个仓库的 open PR 数。
  /// 键用 accountId + repoFullName,避免不同账号下同名仓库混淆。
  /// 不发网络请求;依赖 store.inbox 已在内存中。
  Map<String, int> _openPrCountByRepo(AppStore store) {
    final map = <String, int>{};
    for (final cr in store.inbox) {
      if (cr.state != CrState.open) continue;
      final key = '${cr.accountId}/${cr.repoFullName}';
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  /// 应用平台筛选 + 归档筛选 + 可见性筛选 + 搜索 + 排序,然后 groupRepos。
  List<RepoGroup> _buildGroups(AppStore store, Map<String, int> openByRepo) {
    var repos = store.repos;
    if (_platformFilter != null) {
      repos = repos.where((r) => r.platform == _platformFilter).toList();
    }
    if (_hideArchived) {
      repos = repos.where((r) => !r.archived).toList();
    }
    if (_publicOnly) {
      repos = repos.where((r) => r.visibility == RepoVisibility.public).toList();
    }
    final groups = groupRepos(repos, store.accounts, query: _query);
    // groupRepos 已按平台分好,只需对每个 group.repos 应用排序。
    final cmp = _comparator(openByRepo);
    for (final g in groups) {
      g.repos.sort(cmp);
    }
    return groups;
  }

  int Function(Repo, Repo) _comparator(Map<String, int> openByRepo) {
    switch (_sort) {
      case RepoSortMode.updated:
        return (a, b) => b.updatedAt.compareTo(a.updatedAt);
      case RepoSortMode.name:
        return (a, b) =>
          a.repoName.toLowerCase().compareTo(b.repoName.toLowerCase());
      case RepoSortMode.stars:
        return (a, b) => b.starCount.compareTo(a.starCount);
      case RepoSortMode.openPrs:
        return (a, b) {
          final ca = openByRepo['${a.accountId}/${a.fullName}'] ?? 0;
          final cb = openByRepo['${b.accountId}/${b.fullName}'] ?? 0;
          return cb.compareTo(ca);
        };
    }
  }

  void _showSheet(BuildContext context, AppStore store, Repo repo, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_browser),
              title: Text(l10n.repoSheetOpenInBrowser),
              onTap: () {
                Navigator.pop(ctx);
                store.openWeb(repo.webUrl);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(l10n.repoSheetCopyUrl),
              onTap: () async {
                Navigator.pop(ctx);
                await Clipboard.setData(ClipboardData(text: repo.webUrl));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.repoSheetUrlCopied)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 仓库行:语言色点 + owner/repoName + description + 元数据 wrap + open PR pill + chevron。
/// 用 Material + InkWell 让涟漪在 SliverList 中正常工作。
class _Row extends StatelessWidget {
  const _Row({
    required this.repo,
    required this.accountLabel,
    required this.openPrCount,
    required this.onTap,
    required this.onLongPress,
  });

  final Repo repo;
  final String? accountLabel;
  final int openPrCount;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // leading:语言色点,稳定视觉锚点。
              LanguageDot(language: repo.language),
              const SizedBox(width: 12),
              // 中段三行:title / description / meta wrap。
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RepoName(owner: repo.owner, name: repo.repoName),
                    if (repo.description != null && repo.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        repo.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 4),
                    _MetaRow(repo: repo, l10n: l10n),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // trailing:open PR pill(>0 才显示)+ chevron。
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (openPrCount > 0) _OpenPrPill(count: openPrCount, l10n: l10n),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// owner / repoName 拼接:owner 弱化,repoName 加粗,整体单行省略。
/// owner 为空时(异常数据)只渲染 repoName,不会渲染 " / " 前缀。
class _RepoName extends StatelessWidget {
  const _RepoName({required this.owner, required this.name});
  final String owner;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bold = theme.textTheme.titleSmall;
    final muted = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Text.rich(
      TextSpan(
        children: [
          if (owner.isNotEmpty) TextSpan(text: '$owner / ', style: muted),
          TextSpan(text: name, style: bold),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      // 外层 style 用 bold 是为了 ellipsis 字符与正文一致;内层 TextSpan 覆盖颜色。
      style: bold,
    );
  }
}

/// 第二行元数据:语言 · Updated 日期 · visibility · archived · fork。
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.repo, required this.l10n});
  final Repo repo;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    final visIcon = switch (repo.visibility) {
      RepoVisibility.public => Icons.public,
      RepoVisibility.internal => Icons.shield_outlined,
      RepoVisibility.private => Icons.lock_outline,
    };
    return Wrap(
      spacing: 10,
      runSpacing: 2,
      children: [
        if (repo.language != null && repo.language!.isNotEmpty)
          _MetaIconText(icon: Icons.code, text: repo.language!, style: style),
        _MetaIconText(
          icon: Icons.update,
          text: l10n.repoMetaUpdated(_ymd(repo.updatedAt)),
          style: style,
        ),
        _MetaIconText(
          icon: visIcon,
          text: repoVisibilityLabel(l10n, repo.visibility),
          style: style,
        ),
        if (repo.archived)
          _MetaIconText(icon: Icons.archive_outlined, text: l10n.repoMetaArchived, style: style),
        if (repo.fork)
          _MetaIconText(icon: Icons.call_split, text: l10n.repoMetaFork, style: style),
      ],
    );
  }
}

class _MetaIconText extends StatelessWidget {
  const _MetaIconText({required this.icon, required this.text, required this.style});
  final IconData icon;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: style.color),
        const SizedBox(width: 3),
        Text(text, style: style),
      ],
    );
  }
}

/// open PR 数量小药丸。count == 0 时不渲染。
class _OpenPrPill extends StatelessWidget {
  const _OpenPrPill({required this.count, required this.l10n});
  final int count;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        l10n.repoOpenPrPill(count),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// YYYY-MM-DD 格式化,与 repo_detail_page.dart 内私有 _ymd 行为一致。
/// 这里复制一份避免为共享而改动无关文件。
String _ymd(DateTime t) {
  final u = t.toUtc();
  final m = u.month.toString().padLeft(2, '0');
  final d = u.day.toString().padLeft(2, '0');
  return '${u.year}-$m-$d';
}