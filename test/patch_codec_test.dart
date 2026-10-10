import 'package:codeinbox/data/patch_codec.dart';
import 'package:codeinbox/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsePatchLines numbers add and context on the new side', () {
    const patch = '''@@ -10,3 +10,4 @@
 keep
-old
+new
 keep2
''';
    final lines = parsePatchLines(patch);
    final added = lines.where((l) => l.kind == PatchLineKind.add).single;
    expect(added.newLine, 11);
    expect(added.canComment, isTrue);
    final deleted = lines.where((l) => l.kind == PatchLineKind.del).single;
    expect(deleted.oldLine, 11);
    expect(deleted.canComment, isFalse);
  });

  test('applyRecoveredPatches only fills files that lacked a patch', () {
    const files = [
      ChangedFile(path: 'a.dart', patch: '@@\n+kept\n'),
      ChangedFile(path: 'b.dart'),
    ];
    final filled = applyRecoveredPatches(files, {'b.dart': '@@ -1 +1 @@\n+ok\n'});
    expect(filled[0].patch, '@@\n+kept\n');
    expect(filled[1].hasPatch, isTrue);
    expect(filled[1].patch, contains('+ok'));
  });
}
