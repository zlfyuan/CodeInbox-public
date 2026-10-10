import 'package:flutter/material.dart';

import '../data/patch_codec.dart';
import '../domain/forge_adapter.dart';
import '../domain/models.dart';
import '../l10n/gen/app_localizations.dart';
import '../store.dart';

class DiffPage extends StatefulWidget {
  const DiffPage({super.key, required this.file, required this.cr});

  final ChangedFile file;
  final ChangeRequest cr;

  @override
  State<DiffPage> createState() => _DiffPageState();
}

class _DiffPageState extends State<DiffPage> {
  final _comment = TextEditingController();
  final _line = TextEditingController();
  bool _busy = false;
  int? _selectedLine;

  @override
  void dispose() {
    _comment.dispose();
    _line.dispose();
    super.dispose();
  }

  void _selectLine(int line) {
    setState(() => _selectedLine = line);
    _line.text = '$line';
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final file = widget.file;
    return Scaffold(
      appBar: AppBar(
        title: Text(file.path, overflow: TextOverflow.ellipsis),
        actions: [
          if (widget.cr.webUrl.isNotEmpty)
            IconButton(
              tooltip: l10n.openInBrowser,
              onPressed: () => store.openWeb(widget.cr.webUrl),
              icon: const Icon(Icons.open_in_browser),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        children: [
          if (!file.hasPatch)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(l10n.diffBinary),
                  const SizedBox(height: 16),
                  if (widget.cr.webUrl.isNotEmpty)
                    FilledButton(
                      onPressed: () => store.openWeb(widget.cr.webUrl),
                      child: Text(l10n.diffOpenInBrowser),
                    ),
                ],
              ),
            )
          else ...[
            if (file.truncated)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(l10n.diffTruncated),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(l10n.diffTapHint, style: Theme.of(context).textTheme.bodySmall),
            ),
            _PatchView(
              patch: file.patch!,
              l10n: l10n,
              selectedLine: _selectedLine,
              onSelectLine: _selectLine,
            ),
          ],
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(
              _selectedLine == null ? l10n.diffLineComment : l10n.diffCommentOnLine(_selectedLine!),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: TextField(
              controller: _line,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.diffLineNumberLabel,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _selectedLine = int.tryParse(v.trim())),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: TextField(
              controller: _comment,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.diffCommentHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: FilledButton(
              onPressed: _busy ? null : () => _post(store, l10n),
              child: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.diffPostComment),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _post(AppStore store, AppLocalizations l10n) async {
    final text = _comment.text.trim();
    final line = int.tryParse(_line.text.trim()) ?? _selectedLine;
    if (text.isEmpty || line == null) return;
    setState(() => _busy = true);
    try {
      // RIGHT-side (new file) line; adapters map path/line to each forge.
      await store.submitReview(
        widget.cr,
        ReviewAction(
          type: ReviewType.comment,
          body: text,
          path: widget.file.path,
          line: line,
        ),
      );
      if (!mounted) return;
      _comment.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.diffCommentPosted)));
    } on AdapterException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? l10n.diffCommentFailed)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.diffCommentFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _PatchView extends StatelessWidget {
  const _PatchView({
    required this.patch,
    required this.l10n,
    required this.selectedLine,
    required this.onSelectLine,
  });

  final String patch;
  final AppLocalizations l10n;
  final int? selectedLine;
  final ValueChanged<int> onSelectLine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          height: 1.35,
        );
    final gutter = style?.copyWith(color: scheme.onSurfaceVariant, fontSize: 11);
    final parsed = parsePatchLines(patch);
    final shown = parsed.length > 800 ? parsed.sublist(0, 800) : parsed;
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in shown)
            Material(
              color: _selected(line, scheme),
              child: InkWell(
                onTap: line.canComment ? () => onSelectLine(line.newLine!) : null,
                child: ColoredBox(
                  color: line.canComment && selectedLine == line.newLine
                      ? Colors.transparent
                      : _color(line, scheme),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            line.oldLine?.toString() ?? '',
                            style: gutter,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          child: Text(
                            line.newLine?.toString() ?? '',
                            style: gutter,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(line.text.isEmpty ? ' ' : line.text, style: style),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (parsed.length > 800)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(l10n.diffOmittedLines),
            ),
        ],
      ),
    );
  }

  Color _selected(PatchLine line, ColorScheme scheme) {
    if (line.canComment && selectedLine == line.newLine) {
      return scheme.primary.withValues(alpha: 0.18);
    }
    return Colors.transparent;
  }

  Color _color(PatchLine line, ColorScheme scheme) {
    return switch (line.kind) {
      PatchLineKind.meta => scheme.surfaceContainerHighest,
      PatchLineKind.hunk => scheme.primary.withValues(alpha: 0.12),
      PatchLineKind.add => const Color(0x3322C55E),
      PatchLineKind.del => const Color(0x33EF4444),
      PatchLineKind.context => Colors.transparent,
    };
  }
}
