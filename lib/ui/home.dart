import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../store.dart';
import 'inbox_page.dart';
import 'mine_page.dart';
import 'notifications_page.dart';
import 'repos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int index = 0;
  AppStore? _store;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = AppScope.of(context);
      store.refreshAll();
      store.startPolling();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _store = AppScope.of(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store?.stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cached in didChangeDependencies; AppScope.of is unsafe after unmount.
    final store = _store;
    if (store == null) return;
    if (state == AppLifecycleState.resumed) {
      store.refreshAll();
      store.startPolling();
    } else if (state == AppLifecycleState.paused) {
      store.stopPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          InboxPage(),
          NotificationsPage(),
          ReposPage(),
          MinePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: store.inboxBadge > 0,
              label: Text('${store.inboxBadge}'),
              child: const Icon(Icons.inbox_outlined),
            ),
            selectedIcon: const Icon(Icons.inbox),
            label: l10n.tabInbox,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: store.notifications.where((n) => n.unread).isNotEmpty,
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: l10n.tabAlerts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: const Icon(Icons.folder),
            label: l10n.tabRepos,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.tabMe,
          ),
        ],
      ),
    );
  }
}