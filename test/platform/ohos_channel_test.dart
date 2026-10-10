// 鸿蒙 Dart 侧 Ohos* 与 ArkTS 插件之间的 MethodChannel 契约。
// mock handler 只验证 method 名、参数字段、返回值反序列化；不跑真机。
import 'package:codeinbox/platform/ohos/open_url.dart';
import 'package:codeinbox/platform/ohos/prefs.dart';
import 'package:codeinbox/platform/ohos/secure_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturedCall {
  _CapturedCall(this.method, this.args);
  final String method;
  final Object? args;
}

void _install(MethodChannel ch, Object? Function(_CapturedCall) reply) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    ch,
    (call) async => reply(_CapturedCall(call.method, call.arguments)),
  );
}

void _uninstall(MethodChannel ch) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(ch, null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OhosPrefs', () {
    const ch = MethodChannel('codeinbox/prefs');
    late _CapturedCall last;

    setUp(() {
      _install(ch, (c) {
        last = c;
        return null;
      });
    });
    tearDown(() => _uninstall(ch));

    test('ready 走 ready', () async {
      await OhosPrefs().ready();
      expect(last.method, 'ready');
    });

    test('setString / getString 参数与返回值', () async {
      await OhosPrefs().setString('accounts', '[]');
      expect(last.method, 'setString');
      expect((last.args as Map)['key'], 'accounts');
      expect((last.args as Map)['value'], '[]');

      _install(ch, (c) {
        last = c;
        return '[{}]';
      });
      final r = await OhosPrefs().getString('accounts');
      expect(last.method, 'getString');
      expect((last.args as Map)['key'], 'accounts');
      expect(r, '[{}]');
    });

    test('getInt 返回 null', () async {
      final r = await OhosPrefs().getInt('missing');
      expect(last.method, 'getInt');
      expect(r, isNull);
    });

    test('setBool / getBool / remove', () async {
      await OhosPrefs().setBool('debug.bool', true);
      expect(last.method, 'setBool');
      expect((last.args as Map)['value'], isTrue);

      _install(ch, (c) {
        last = c;
        return false;
      });
      expect(await OhosPrefs().getBool('debug.bool'), isFalse);

      _install(ch, (c) {
        last = c;
        return null;
      });
      await OhosPrefs().remove('inbox_cache');
      expect(last.method, 'remove');
      expect((last.args as Map)['key'], 'inbox_cache');
    });
  });

  group('OhosSecureStore', () {
    const ch = MethodChannel('codeinbox/secure_store');
    late _CapturedCall last;

    setUp(() {
      _install(ch, (c) {
        last = c;
        return null;
      });
    });
    tearDown(() => _uninstall(ch));

    test('write / read / delete 对齐 ISecureStore', () async {
      await OhosSecureStore().write('token:a', 'ghs_x');
      expect(last.method, 'write');
      expect((last.args as Map)['key'], 'token:a');
      expect((last.args as Map)['value'], 'ghs_x');

      _install(ch, (c) {
        last = c;
        return 'ghs_x';
      });
      expect(await OhosSecureStore().read('token:a'), 'ghs_x');
      expect(last.method, 'read');

      _install(ch, (c) {
        last = c;
        return null;
      });
      await OhosSecureStore().delete('token:a');
      expect(last.method, 'delete');
      expect((last.args as Map)['key'], 'token:a');
    });
  });

  group('OhosOpenUrl', () {
    const ch = MethodChannel('codeinbox/open_url');
    late _CapturedCall last;

    setUp(() {
      _install(ch, (c) {
        last = c;
        return true;
      });
    });
    tearDown(() => _uninstall(ch));

    test('open 走 openUrl 且 url 原样下发', () async {
      await OhosOpenUrl().open('https://github.com/settings/tokens/new');
      expect(last.method, 'openUrl');
      expect((last.args as Map)['url'], 'https://github.com/settings/tokens/new');
    });

    test('native 返回 false 时抛错', () async {
      _install(ch, (c) {
        last = c;
        return false;
      });
      expect(
        () => OhosOpenUrl().open('https://example.com'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
