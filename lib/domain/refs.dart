class ChangeRequestRef {
  const ChangeRequestRef({
    required this.repoFullName,
    required this.localNumber,
  });

  final String repoFullName;
  final int localNumber;
}

/// Pulls a repo + number out of GitHub / Gitee / GitLab HTML or API URLs.
ChangeRequestRef? parseChangeRequestRef(String? url) {
  if (url == null || url.isEmpty) return null;
  const patterns = <String>[
    r'api\.github\.com/repos/([^/]+/[^/]+)/(?:pulls|issues)/(\d+)',
    r'(?:www\.)?github\.com/([^/]+/[^/]+)/(?:pull|issues)/(\d+)',
    r'gitee\.com/api/v5/repos/([^/]+/[^/]+)/(?:pulls|issues)/(\d+)',
    r'gitee\.com/([^/]+/[^/]+)/(?:pulls|issues)/(\d+)',
    r'https?://[^/]+/(.+)/-/(?:merge_requests|issues)/(\d+)',
    r'codeup\.aliyun\.com/(.+)/change/(\d+)',
    r'devops\.aliyun\.com/.+/code/(.+)/(?:change|merge_request)/(\d+)',
    // Gongfeng / old GitLab: no /-/ segment.
    r'https?://[^/]+/(.+)/merge_requests/(\d+)',
  ];
  final coding = RegExp(r'[^./]+\.coding\.net/p/([^/]+)/d/([^/]+)/git/merge/(\d+)').firstMatch(url);
  if (coding != null) {
    final number = int.tryParse(coding.group(3)!);
    final repo = '${coding.group(1)}/${coding.group(2)}';
    if (number != null) return ChangeRequestRef(repoFullName: repo, localNumber: number);
  }
  for (final pattern in patterns) {
    final match = RegExp(pattern).firstMatch(url);
    if (match == null) continue;
    final number = int.tryParse(match.group(2)!);
    final repo = match.group(1);
    if (number == null || repo == null || repo.isEmpty) continue;
    if (repo.startsWith('api/')) continue;
    return ChangeRequestRef(repoFullName: repo, localNumber: number);
  }
  return null;
}

ChangeRequestRef? firstChangeRequestRef(Iterable<String?> urls) {
  for (final url in urls) {
    final ref = parseChangeRequestRef(url);
    if (ref != null) return ref;
  }
  return null;
}

List<dynamic> jsonAsList(dynamic json) {
  if (json == null) return const [];
  if (json is List) return json;
  if (json is Map) {
    // `diffs` before any other Codeup compare keys — that payload also has `commits`.
    for (final key in ['data', 'list', 'items', 'values', 'diffs', 'result', 'files', 'changedTreeItems']) {
      final inner = json[key];
      if (inner is List) return inner;
    }
  }
  throw FormatException('Expected a list from the API');
}
