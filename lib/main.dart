import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/account_repository.dart';
import 'data/adapter_registry.dart';
import 'data/inbox_cache.dart';
import 'data/open_url.dart';
import 'data/prefs.dart';
import 'data/secure_store.dart';
import 'l10n/gen/app_localizations.dart';
import 'platform/ohos/open_url.dart';
import 'platform/ohos/prefs.dart';
import 'platform/ohos/secure_store.dart';
import 'platform/platform_util.dart';
import 'store.dart';
import 'theme.dart';
import 'ui/home.dart';
import 'ui/welcome_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 鸿蒙没有 shared_preferences / flutter_secure_storage / url_launcher 的 ohos 实现，
  // 全部换成自写 MethodChannel；iOS / Android 保持原样。
  late final IPrefs prefs;
  late final ISecureStore secure;
  late final IOpenUrl openUrl;
  if (PlatformUtil.isOHOS) {
    final ohosPrefs = OhosPrefs();
    await ohosPrefs.ready();
    prefs = ohosPrefs;
    secure = OhosSecureStore();
    openUrl = OhosOpenUrl();
  } else {
    prefs = SharedPrefsImpl(await SharedPreferences.getInstance());
    secure = FlutterSecureStore();
    openUrl = UrlLauncherOpenUrl();
  }

  final store = AppStore(
    accounts: AccountRepository(secure: secure, prefs: prefs),
    adapters: AdapterRegistry(),
    cache: InboxCache(prefs),
    openUrl: openUrl,
  );
  await store.load();
  runApp(CodeInboxApp(store: store));
}

class CodeInboxApp extends StatelessWidget {
  const CodeInboxApp({super.key, required this.store, this.locale});

  final AppStore store;
  // 测试时强制某个 locale;null 表示跟系统。
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: store,
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: codeInboxTheme(brightness: Brightness.light),
        darkTheme: codeInboxTheme(brightness: Brightness.dark),
        themeMode: ThemeMode.system,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _RootGate(),
      ),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (store.accounts.isEmpty) return const WelcomePage();
        return const HomePage();
      },
    );
  }
}
