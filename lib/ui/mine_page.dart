import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../store.dart';
import 'accounts_page.dart';
import 'widgets.dart';

class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mineTitle)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.mineAccounts),
            subtitle: Text(l10n.mineAccountsSubtitle(store.accounts.length)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AccountsPage()),
            ),
          ),
          ListTile(
            title: Text(l10n.mineAppearance),
            subtitle: Text(l10n.mineAppearanceSubtitle),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.mineAbout),
            subtitle: Text(l10n.mineAboutSubtitle('0.1.0')),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text(l10n.mineTokensExplanation),
          ),
          if (store.accounts.isEmpty)
            EmptyState(
              title: l10n.mineNoAccountsTitle,
              subtitle: l10n.mineNoAccountsSubtitle,
            ),
        ],
      ),
    );
  }
}
