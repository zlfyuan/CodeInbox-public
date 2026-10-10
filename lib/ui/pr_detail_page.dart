import 'package:flutter/material.dart';

import '../domain/forge_adapter.dart';
import '../domain/models.dart';
import '../l10n/gen/app_localizations.dart';
import '../store.dart';
import 'diff_page.dart';
import 'widgets.dart';

class PrDetailPage extends StatefulWidget {
  const PrDetailPage({super.key, required this.summary});

  final ChangeRequest summary;

  @override
  State<PrDetailPage> createState() => _PrDetailPageState();
}

class _PrDetailPageState extends State<PrDetailPage> {
  Future<CrDetail>? _future;
  // Bumps FutureBuilder's key so a Retry does not keep the previous error snapshot.
  int _loadGen = 0;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppScope.of(context).loadDetail(widget.summary);
  }

  void _reload() {
    setState(() {
      _loadGen++;
      _future = AppScope.of(context).loadDetail(widget.summary);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<CrDetail>(
      key: ValueKey<int>(_loadGen),
      future: _future,
      builder: (context, snap) {
        final detail = snap.data;
        final cr = detail?.changeRequest ?? widget.summary;
        return Scaffold(
          appBar: AppBar(
            title: Text('${cr.repoFullName} #${cr.localNumber}'),
            actions: [
              IconButton(
                tooltip: l10n.openInBrowser,
                onPressed: cr.webUrl.isEmpty ? null : () => store.openWeb(cr.webUrl),
                icon: const Icon(Icons.open_in_browser),
              ),
            ],
          ),
          body: _body(context, store, snap, detail, cr),
          bottomNavigationBar: detail == null || cr.state != CrState.open
              ? null
              : _ReviewBar(
                  cr: cr,
                  supported: detail.supportedReviews,
                  busy: _busy,
                  onReview: (action) => _submit(store, cr, action, l10n),
                ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    AppStore store,
    AsyncSnapshot<CrDetail> snap,
    CrDetail? detail,
    ChangeRequest cr,
  ) {
    final l10n = AppLocalizations.of(context);
    // FutureBuilder.inState keeps the old error when the future is replaced.
    // Check in-flight first, otherwise Retry looks like a no-op.
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
          ListTile(
            title: Text(l10n.openInBrowser),
            trailing: const Icon(Icons.open_in_browser),
            onTap: () => store.openWeb(widget.summary.webUrl),
          ),
        ],
      );
    }
    if (detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final account = store.accounts.where((a) => a.id == cr.accountId).firstOrNull;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cr.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(crStateLabel(l10n, cr.state)), visualDensity: VisualDensity.compact),
                  if (cr.draft) Chip(label: Text(l10n.repoDetailDraft), visualDensity: VisualDensity.compact),
                  if (cr.ciStatus != null)
                    Chip(label: Text(l10n.prDetailChipCi(cr.ciStatus!)), visualDensity: VisualDensity.compact),
                  if (cr.mergeable == false)
                    Chip(label: Text(l10n.prDetailChipNotMergeable), visualDensity: VisualDensity.compact),
                ],
              ),
              const SizedBox(height: 8),
              PlatformBadge(platform: cr.platform, accountLabel: account?.label),
              const SizedBox(height: 8),
              Text(l10n.prDetailBranchLine(cr.authorLogin, cr.sourceBranch, cr.targetBranch)),
            ],
          ),
        ),
        if (cr.body != null && cr.body!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SelectableText(cr.body!),
          ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(l10n.prDetailFilesHeader(detail.files.length), style: Theme.of(context).textTheme.titleSmall),
        ),
        if (detail.files.isEmpty)
          ListTile(dense: true, title: Text(l10n.prDetailNoFiles)),
        for (final file in detail.files)
          ListTile(
            dense: true,
            title: Text(file.path, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(l10n.prDetailFileStat(file.additions, file.deletions, file.status)),
            // Chevron hints the row is tappable and opens the diff.
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => DiffPage(file: file, cr: cr),
            )),
          ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(l10n.prDetailCommentsHeader(detail.comments.length), style: Theme.of(context).textTheme.titleSmall),
        ),
        if (detail.comments.isEmpty) ListTile(dense: true, title: Text(l10n.prDetailNoComments)),
        for (final comment in detail.comments)
          ListTile(
            title: Text(comment.authorLogin),
            subtitle: Text(
              [
                if (comment.path != null)
                  comment.line != null
                      ? l10n.prDetailCommentPath(comment.path!, comment.line!)
                      : comment.path!,
                comment.body,
              ].join('\n'),
            ),
            isThreeLine: comment.path != null,
          ),
      ],
    );
  }

  Future<void> _submit(AppStore store, ChangeRequest cr, ReviewAction action, AppLocalizations l10n) async {
    setState(() => _busy = true);
    try {
      await store.submitReview(cr, action);
      if (!mounted) return;
      final label = switch (action.type) {
        ReviewType.approve => l10n.prDetailReviewApproved,
        ReviewType.requestChanges => l10n.prDetailReviewRequestedChanges,
        ReviewType.comment => l10n.prDetailReviewCommentPosted,
        ReviewType.merge => l10n.prDetailReviewMerged,
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
      if (action.type == ReviewType.merge) {
        Navigator.of(context).pop();
        return;
      }
      _reload();
    } on AdapterException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? l10n.prDetailReviewFailed)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.prDetailReviewFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ReviewBar extends StatelessWidget {
  const _ReviewBar({
    required this.cr,
    required this.supported,
    required this.busy,
    required this.onReview,
  });

  final ChangeRequest cr;
  final Set<ReviewType> supported;
  final bool busy;
  final Future<void> Function(ReviewAction action) onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : () => _openSheet(context, l10n),
                  child: Text(l10n.prDetailReviewButton),
                ),
              ),
              if (supported.contains(ReviewType.merge) && cr.mergeable != false) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: busy ? null : () => _confirmMerge(context, l10n),
                  child: Text(l10n.prDetailMergeButton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context, AppLocalizations l10n) async {
    final body = TextEditingController();
    final action = await showModalBottomSheet<ReviewAction>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(l10n.prDetailReviewSheetTitle, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: body,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: l10n.prDetailReviewSheetCommentHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (supported.contains(ReviewType.comment))
                FilledButton.tonal(
                  onPressed: () {
                    if (body.text.trim().isEmpty) return;
                    Navigator.pop(ctx, ReviewAction(type: ReviewType.comment, body: body.text));
                  },
                  child: Text(l10n.prDetailReviewSheetComment),
                ),
              if (supported.contains(ReviewType.approve)) ...[
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, ReviewAction(type: ReviewType.approve, body: body.text)),
                  child: Text(l10n.prDetailReviewSheetApprove),
                ),
              ],
              if (supported.contains(ReviewType.requestChanges)) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    if (body.text.trim().isEmpty) return;
                    Navigator.pop(ctx, ReviewAction(type: ReviewType.requestChanges, body: body.text));
                  },
                  child: Text(l10n.prDetailReviewSheetRequestChanges),
                ),
              ],
            ],
          ),
        );
      },
    );
    body.dispose();
    if (action != null) await onReview(action);
  }

  Future<void> _confirmMerge(BuildContext context, AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.prDetailMergeDialogTitle),
        content: Text(l10n.prDetailMergeDialogContent(cr.repoFullName, cr.localNumber)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.prDetailCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.prDetailMergeButton)),
        ],
      ),
    );
    if (ok == true) await onReview(const ReviewAction(type: ReviewType.merge));
  }
}