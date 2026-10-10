import '../domain/forge_adapter.dart';
import '../domain/models.dart';

enum PatchLineKind { meta, hunk, context, add, del }

class PatchLine {
  const PatchLine({required this.text, required this.kind, this.oldLine, this.newLine});

  final String text;
  final PatchLineKind kind;
  final int? oldLine;
  final int? newLine;

  bool get canComment => newLine != null && (kind == PatchLineKind.add || kind == PatchLineKind.context);
}

/// Parse a unified-diff body (with or without `diff --git` headers) into
/// numbered lines so the Diff page can tap a RIGHT-side line to comment.
List<PatchLine> parsePatchLines(String patch) {
  var oldN = 0;
  var newN = 0;
  final out = <PatchLine>[];
  for (final line in patch.split('\n')) {
    if (line.startsWith('@@')) {
      final match = RegExp(r'@@ -(\d+)(?:,\d+)? \+(\d+)').firstMatch(line);
      oldN = int.tryParse(match?.group(1) ?? '') ?? 0;
      newN = int.tryParse(match?.group(2) ?? '') ?? 0;
      out.add(PatchLine(text: line, kind: PatchLineKind.hunk));
      continue;
    }
    if (line.startsWith('+++') ||
        line.startsWith('---') ||
        line.startsWith('diff ') ||
        line.startsWith('index ') ||
        line.startsWith('\\')) {
      out.add(PatchLine(text: line, kind: PatchLineKind.meta));
      continue;
    }
    if (line.startsWith('+')) {
      out.add(PatchLine(text: line, kind: PatchLineKind.add, newLine: newN));
      newN++;
      continue;
    }
    if (line.startsWith('-')) {
      out.add(PatchLine(text: line, kind: PatchLineKind.del, oldLine: oldN));
      oldN++;
      continue;
    }
    final oldLine = oldN;
    final newLine = newN;
    out.add(PatchLine(text: line, kind: PatchLineKind.context, oldLine: oldLine, newLine: newLine));
    oldN++;
    newN++;
  }
  return out;
}

/// Parse GitHub/GitLab-style raw unified diff into new-path → patch body.
/// Binary hunks are skipped. Renames use the `b/PATH` (new) name.
Map<String, String> parseRawDiffIntoPatches(String rawDiff) {
  final result = <String, String>{};
  if (rawDiff.isEmpty) return result;
  final sections = rawDiff.split(RegExp(r'^diff --git ', multiLine: true));
  for (final section in sections) {
    if (section.trim().isEmpty) continue;
    final lines = section.split('\n');
    if (lines.isEmpty) continue;
    final headerMatch = RegExp(r'^a/(.+?) b/(.+?)$').firstMatch(lines.first);
    if (headerMatch == null) continue;
    final newPath = headerMatch.group(2)!;
    if (lines.any((l) => l.startsWith('Binary files'))) continue;
    var plusIdx = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('+++ ')) {
        plusIdx = i;
        break;
      }
    }
    if (plusIdx < 0 || plusIdx + 1 >= lines.length) continue;
    final patch = lines.sublist(plusIdx + 1).join('\n').trimRight();
    if (patch.isEmpty) continue;
    result[newPath] = patch;
  }
  return result;
}

List<ChangedFile> applyRecoveredPatches(List<ChangedFile> files, Map<String, String> recovered) {
  if (recovered.isEmpty) return files;
  return files.map((f) {
    if (f.hasPatch) return f;
    final patch = recovered[f.path];
    if (patch == null) return f;
    final clipped = clipPatch(patch);
    return ChangedFile(
      path: f.path,
      status: f.status,
      additions: f.additions,
      deletions: f.deletions,
      patch: clipped.$1,
      truncated: clipped.$2,
    );
  }).toList();
}

/// Fill files that came back without a patch by parsing a raw `.diff` body.
Future<List<ChangedFile>> recoverPatches({
  required List<ChangedFile> files,
  required Future<String> Function() fetchDiff,
}) async {
  if (files.isEmpty || !files.any((f) => !f.hasPatch)) return files;
  try {
    return applyRecoveredPatches(files, parseRawDiffIntoPatches(await fetchDiff()));
  } on AdapterException {
    return files;
  } on FormatException {
    return files;
  }
}
