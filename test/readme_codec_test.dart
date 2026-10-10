import 'dart:convert';

import 'package:codeinbox/data/readme_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodeRepoFileContent reads GitHub base64', () {
    final body = base64.encode(utf8.encode('# Hello\n'));
    final text = decodeRepoFileContent({'encoding': 'base64', 'content': body});
    expect(text, '# Hello\n');
  });

  test('decodeRepoFileContent unwraps CODING File map', () {
    final body = base64.encode(utf8.encode('hi'));
    final text = decodeRepoFileContent({
      'File': {'Content': body, 'Encoding': 'base64'},
    });
    expect(text, 'hi');
  });

  test('clipReadme truncates long files', () {
    final long = 'a' * (kMaxReadmeChars + 20);
    final clipped = clipReadme(long);
    expect(clipped.$2, isTrue);
    expect(clipped.$1.length, lessThan(long.length));
  });
}
