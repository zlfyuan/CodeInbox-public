import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';

/// Lightweight README renderer (headings, lists, code, links). No extra package.
class ReadmeView extends StatelessWidget {
  const ReadmeView({super.key, required this.markdown, required this.onOpenUrl});

  final String markdown;
  final ValueChanged<String> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final block in _blocks(markdown))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _render(block, theme, scheme, l10n),
          ),
      ],
    );
  }

  Widget _render(_Block block, ThemeData theme, ColorScheme scheme, AppLocalizations l10n) {
    switch (block) {
      case _Heading(:final level, :final text):
        final style = switch (level) {
          1 => theme.textTheme.headlineSmall,
          2 => theme.textTheme.titleLarge,
          3 => theme.textTheme.titleMedium,
          _ => theme.textTheme.titleSmall,
        };
        return Padding(
          padding: EdgeInsets.only(top: level <= 2 ? 8 : 0),
          child: Text.rich(_inline(text, theme, scheme, l10n), style: style?.copyWith(fontWeight: FontWeight.w600)),
        );
      case _Paragraph(:final text):
        return Text.rich(_inline(text, theme, scheme, l10n), style: theme.textTheme.bodyMedium?.copyWith(height: 1.45));
      case _Quote(:final text):
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: scheme.outlineVariant, width: 3)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text.rich(
              _inline(text, theme, scheme, l10n),
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
            ),
          ),
        );
      case _ListBlock(:final items):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: theme.textTheme.bodyMedium),
                    Expanded(child: Text.rich(_inline(item, theme, scheme, l10n), style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
          ],
        );
      case _Code(:final text):
        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              text.trimRight(),
              style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', height: 1.4),
            ),
          ),
        );
      case _Rule():
        return const Divider(height: 24);
    }
  }

  TextSpan _inline(String text, ThemeData theme, ColorScheme scheme, AppLocalizations l10n) {
    final pattern = RegExp(
      r'!\[([^\]]*)\]\([^)]+\)|'
      r'\[([^\]]+)\]\(([^)]+)\)|'
      r'`([^`]+)`|'
      r'\*\*([^*]+)\*\*|'
      r'(?<!\*)\*([^*]+)\*(?!\*)',
    );
    final children = <InlineSpan>[];
    var start = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        children.add(TextSpan(text: text.substring(start, match.start)));
      }
      if (match.group(1) != null) {
        final alt = match.group(1)!.trim();
        children.add(TextSpan(text: alt.isEmpty ? l10n.imageAlt : alt, style: TextStyle(color: scheme.onSurfaceVariant)));
      } else if (match.group(2) != null) {
        final label = match.group(2)!;
        final href = match.group(3)!;
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () {
                if (href.startsWith('http://') || href.startsWith('https://')) onOpenUrl(href);
              },
              child: Text(
                label,
                style: TextStyle(color: scheme.primary, decoration: TextDecoration.underline),
              ),
            ),
          ),
        );
      } else if (match.group(4) != null) {
        children.add(TextSpan(
          text: match.group(4),
          style: TextStyle(fontFamily: 'monospace', backgroundColor: scheme.surfaceContainerHighest),
        ));
      } else if (match.group(5) != null) {
        children.add(TextSpan(text: match.group(5), style: const TextStyle(fontWeight: FontWeight.w600)));
      } else if (match.group(6) != null) {
        children.add(TextSpan(text: match.group(6), style: const TextStyle(fontStyle: FontStyle.italic)));
      }
      start = match.end;
    }
    if (start < text.length) children.add(TextSpan(text: text.substring(start)));
    return TextSpan(children: children);
  }
}

sealed class _Block {}

class _Heading extends _Block {
  _Heading(this.level, this.text);
  final int level;
  final String text;
}

class _Paragraph extends _Block {
  _Paragraph(this.text);
  final String text;
}

class _Quote extends _Block {
  _Quote(this.text);
  final String text;
}

class _ListBlock extends _Block {
  _ListBlock(this.items);
  final List<String> items;
}

class _Code extends _Block {
  _Code(this.text);
  final String text;
}

class _Rule extends _Block {}

List<_Block> _blocks(String src) {
  final lines = src.replaceAll('\r\n', '\n').split('\n');
  final out = <_Block>[];
  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    if (line.startsWith('```')) {
      i++;
      final buf = StringBuffer();
      while (i < lines.length && !lines[i].startsWith('```')) {
        buf.writeln(lines[i]);
        i++;
      }
      if (i < lines.length) i++;
      out.add(_Code(buf.toString()));
      continue;
    }
    final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
    if (heading != null) {
      out.add(_Heading(heading.group(1)!.length, heading.group(2)!.trim()));
      i++;
      continue;
    }
    final trimmed = line.trim();
    if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
      out.add(_Rule());
      i++;
      continue;
    }
    if (line.startsWith('>')) {
      final parts = <String>[];
      while (i < lines.length && lines[i].startsWith('>')) {
        parts.add(lines[i].replaceFirst(RegExp(r'^>\s?'), ''));
        i++;
      }
      out.add(_Quote(parts.join('\n')));
      continue;
    }
    if (RegExp(r'^\s*[-*+]\s+').hasMatch(line) || RegExp(r'^\s*\d+\.\s+').hasMatch(line)) {
      final items = <String>[];
      while (i < lines.length &&
          (RegExp(r'^\s*[-*+]\s+').hasMatch(lines[i]) || RegExp(r'^\s*\d+\.\s+').hasMatch(lines[i]))) {
        items.add(lines[i].replaceFirst(RegExp(r'^\s*([-*+]|\d+\.)\s+'), ''));
        i++;
      }
      out.add(_ListBlock(items));
      continue;
    }
    if (trimmed.isEmpty) {
      i++;
      continue;
    }
    final parts = <String>[line.trim()];
    i++;
    while (i < lines.length &&
        lines[i].trim().isNotEmpty &&
        !lines[i].startsWith('#') &&
        !lines[i].startsWith('```') &&
        !lines[i].startsWith('>') &&
        !RegExp(r'^\s*[-*+]\s+').hasMatch(lines[i]) &&
        !RegExp(r'^\s*\d+\.\s+').hasMatch(lines[i])) {
      parts.add(lines[i].trim());
      i++;
    }
    out.add(_Paragraph(parts.join(' ')));
  }
  return out;
}
