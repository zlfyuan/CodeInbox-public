import 'package:flutter/material.dart';

import '../domain/forge_adapter.dart';
import '../domain/models.dart';
import '../l10n/gen/app_localizations.dart';
import '../store.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({super.key, required this.platform});

  final ForgePlatform platform;

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _token = TextEditingController();
  final _alias = TextEditingController();
  final _baseUrl = TextEditingController();
  final _orgId = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _isGitlab => widget.platform == ForgePlatform.gitlab;
  bool get _isCodeup => widget.platform == ForgePlatform.codeup;
  bool get _isGongfeng => widget.platform == ForgePlatform.gongfeng;
  bool get _isCoding => widget.platform == ForgePlatform.coding;
  bool get _needsBaseUrl => _isGitlab || _isCodeup || _isGongfeng || _isCoding;

  @override
  void initState() {
    super.initState();
    if (_isGitlab) _baseUrl.text = kGitlabDotCom;
    if (_isCodeup) _baseUrl.text = kCodeupOpenApi;
    if (_isGongfeng) _baseUrl.text = kGongfengDotCom;
  }

  @override
  void dispose() {
    _token.dispose();
    _alias.dispose();
    _baseUrl.dispose();
    _orgId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final name = platformLabel(l10n, widget.platform);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addAccountTitle(name))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(_help(l10n), style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          if (_needsBaseUrl) ...[
            TextField(
              controller: _baseUrl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: _isCodeup ? l10n.addAccountApiDomain : l10n.addAccountBaseUrl,
                hintText: _isCodeup
                    ? kCodeupOpenApi
                    : (_isGongfeng
                        ? kGongfengDotCom
                        : (_isCoding ? kCodingHintHost : 'https://gitlab.com')),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_isCodeup) ...[
            TextField(
              controller: _orgId,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.addAccountOrgId,
                hintText: l10n.addAccountOrgIdHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton(
            onPressed: () => store.openWeb(store.tokenCreateUrl(widget.platform, baseUrl: _baseUrl.text)),
            child: Text(l10n.addAccountOpenTokenPage(name)),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _token,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.addAccountPat,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _alias,
            decoration: InputDecoration(
              labelText: l10n.addAccountDisplayName,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : () => _save(store, l10n),
            child: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.addAccountVerifySave),
          ),
        ],
      ),
    );
  }

  // Per-platform help text. 直接使用 l10n 字段,无 platform 私有化逻辑。
  String _help(AppLocalizations l10n) => switch (widget.platform) {
        ForgePlatform.github => l10n.addAccountHelpGithub,
        ForgePlatform.gitee => l10n.addAccountHelpGitee,
        ForgePlatform.gitlab => l10n.addAccountHelpGitlab,
        ForgePlatform.codeup => l10n.addAccountHelpCodeup,
        ForgePlatform.gongfeng => l10n.addAccountHelpGongfeng,
        ForgePlatform.coding => l10n.addAccountHelpCoding(kCodingHintHost),
      };

  Future<void> _save(AppStore store, AppLocalizations l10n) async {
    final token = _token.text.trim();
    if (token.isEmpty) {
      setState(() => _error = l10n.addAccountErrorNoToken);
      return;
    }
    if (_isCoding && _baseUrl.text.trim().isEmpty) {
      setState(() => _error = l10n.addAccountErrorNoTeam(kCodingHintHost));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await store.addAccount(
        platform: widget.platform,
        token: token,
        displayName: _alias.text.trim().isEmpty ? null : _alias.text.trim(),
        baseUrl: _needsBaseUrl ? _baseUrl.text : null,
        orgId: _isCodeup ? _orgId.text : null,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AdapterException catch (e) {
      setState(() => _error = e.message ?? l10n.addAccountErrorVerifyFailed);
    } catch (_) {
      setState(() => _error = l10n.addAccountErrorVerifyFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}