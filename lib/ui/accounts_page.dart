import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../l10n/gen/app_localizations.dart';
import '../store.dart';
import 'account_detail_sheet.dart';
import 'add_account_page.dart';
import 'widgets.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountsTitle)),
      body: ListView(
        children: [
          for (final account in store.accounts)
            ListTile(
              // 点击账号行 → 底部弹出 sheet,展示全字段 + 复制用户名
              onTap: () => showAccountDetailSheet(context, account),
              title: Text(account.label),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _buildSubtitle(context, account),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmRemove(context, store, account),
              ),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(l10n.accountsAddGithub),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const AddAccountPage(platform: ForgePlatform.github),
            )),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(l10n.accountsAddGitee),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const AddAccountPage(platform: ForgePlatform.gitee),
            )),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(l10n.accountsAddGitlab),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const AddAccountPage(platform: ForgePlatform.gitlab),
            )),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(l10n.accountsAddCodeup),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const AddAccountPage(platform: ForgePlatform.codeup),
            )),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(l10n.accountsAddGongfeng),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const AddAccountPage(platform: ForgePlatform.gongfeng),
            )),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(l10n.accountsAddCoding),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const AddAccountPage(platform: ForgePlatform.coding),
            )),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.accountsRevokeGithub),
            onTap: () => store.openWeb(store.tokenRevokeUrl(ForgePlatform.github)),
          ),
          ListTile(
            title: Text(l10n.accountsRevokeGitee),
            onTap: () => store.openWeb(store.tokenRevokeUrl(ForgePlatform.gitee)),
          ),
          ListTile(
            title: Text(l10n.accountsRevokeGitlab),
            onTap: () => store.openWeb(store.tokenRevokeUrl(ForgePlatform.gitlab)),
          ),
          ListTile(
            title: Text(l10n.accountsRevokeCodeup),
            onTap: () => store.openWeb(store.tokenRevokeUrl(ForgePlatform.codeup)),
          ),
          ListTile(
            title: Text(l10n.accountsRevokeGongfeng),
            onTap: () => store.openWeb(store.tokenRevokeUrl(ForgePlatform.gongfeng)),
          ),
          ListTile(
            title: Text(l10n.accountsRevokeCoding),
            onTap: () => store.openWeb(store.tokenRevokeUrl(ForgePlatform.coding)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, AppStore store, PlatformAccount account) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountsRemoveDialogTitle),
        content: Text(l10n.accountsRemoveDialogContent(account.label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.accountsRemoveCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.accountsRemoveConfirm)),
        ],
      ),
    );
    if (ok == true) await store.removeAccount(account.id);
  }
}

String _accountSubtitle(PlatformAccount account) {
  if (account.platform == ForgePlatform.codeup) {
    // Codeup 中心版有 orgId 的话,行内不再拼,改走 _buildSubtitle 的双行布局。
    final org = account.orgId;
    if (org != null && org.isNotEmpty) return account.login;
    return account.login;
  }
  if (account.platform == ForgePlatform.coding && account.baseUrl != null) {
    return '${account.login} · ${account.baseUrl}';
  }
  if (account.baseUrl == null ||
      account.baseUrl == kGitlabDotCom ||
      account.baseUrl == kGongfengDotCom) {
    return account.login;
  }
  return '${account.login} · ${account.baseUrl}';
}

/// 账号行副标题。
/// - Codeup 中心版(orgId 非空):第一行 `● Codeup  login`,第二行单独 org
/// - 其它:单行 `● Platform  login · baseUrl`
Widget _buildSubtitle(BuildContext context, PlatformAccount account) {
  final theme = Theme.of(context);
  // Codeup 中心版 orgId 非空:org 单独占一行,与 platform/login 分开
  if (account.platform == ForgePlatform.codeup &&
      account.orgId != null &&
      account.orgId!.isNotEmpty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlatformBadge(platform: account.platform, accountLabel: account.login),
        // left: 14 对齐 PlatformBadge 内 dot(8)+ 间距(6),让 org 视觉上挂在
        // platform name 之下而不是 platform dot 之下。
        Padding(
          padding: const EdgeInsets.only(top: 2, left: 14),
          child: Text(
            account.orgId!,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
          ),
        ),
      ],
    );
  }
  return PlatformBadge(
    platform: account.platform,
    accountLabel: _accountSubtitle(account),
  );
}