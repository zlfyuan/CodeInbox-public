import 'dart:convert';

import '../domain/forge_adapter.dart';

const kReadmeFileNames = ['README.md', 'readme.md', 'README', 'README.rst', 'README.adoc'];

const kMaxReadmeChars = 30000;

/// Decodes GitHub/Gitee/GitLab-style file payloads (base64 `content`).
String? decodeRepoFileContent(dynamic json) {
  if (json == null) return null;
  if (json is String) return json.trim().isEmpty ? null : json;
  if (json is! Map) return null;
  final map = Map<String, dynamic>.from(json);
  final nested = map['File'] ?? map['file'] ?? map['blob'] ?? map['Blob'] ?? map['Result'];
  if (nested is Map && map['content'] == null && map['Content'] == null) {
    return decodeRepoFileContent(nested);
  }
  final content = map['content'] as String? ?? map['Content'] as String? ?? map['file_content'] as String?;
  if (content == null || content.trim().isEmpty) return null;
  final encoding = (map['encoding'] ?? map['Encoding'])?.toString().toLowerCase();
  if (encoding == null || encoding == 'base64' || content.contains('\n') && !content.contains(' ')) {
    try {
      final bytes = base64.decode(content.replaceAll(RegExp(r'\s'), ''));
      return utf8.decode(bytes);
    } catch (_) {
      return content;
    }
  }
  return content;
}

(String markdown, bool truncated) clipReadme(String raw) {
  if (raw.length <= kMaxReadmeChars) return (raw, false);
  return ('${raw.substring(0, kMaxReadmeChars)}\n\n… truncated', true);
}

bool isMissingFile(AdapterException e) =>
    e.kind == AdapterErrorKind.unsupported || e.statusCode == 404;

Future<String?> firstReadme(Future<dynamic> Function(String name) fetch) async {
  for (final name in kReadmeFileNames) {
    try {
      final text = decodeRepoFileContent(await fetch(name));
      if (text != null && text.trim().isNotEmpty) return clipReadme(text).$1;
    } on AdapterException catch (e) {
      if (isMissingFile(e)) continue;
      rethrow;
    } on FormatException {
      continue;
    }
  }
  return null;
}
