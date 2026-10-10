import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../l10n/gen/app_localizations.dart';
import 'add_account_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.welcomeHeadline,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.welcomeSubheadline,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    FilledButton(
                      onPressed: () => _add(context, ForgePlatform.github),
                      child: Text(l10n.accountsAddGithub),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _add(context, ForgePlatform.gitee),
                      child: Text(l10n.accountsAddGitee),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _add(context, ForgePlatform.gitlab),
                      child: Text(l10n.accountsAddGitlab),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _add(context, ForgePlatform.codeup),
                      child: Text(l10n.accountsAddCodeup),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _add(context, ForgePlatform.gongfeng),
                      child: Text(l10n.accountsAddGongfeng),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _add(context, ForgePlatform.coding),
                      child: Text(l10n.accountsAddCoding),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _add(BuildContext context, ForgePlatform platform) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddAccountPage(platform: platform),
      ),
    );
  }
}
