import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../l10n/gen/app_localizations.dart';
import 'widgets.dart';

/// 弹出账号详情 bottom sheet。
///
/// 展示账号所有非敏感元数据(用户名、显示名、平台、服务地址、组织 ID、
/// 认证方式、内部 ID、添加时间)。**绝不展示 token** —— token 只在
/// [ISecureStore],UI 层拿不到。
///
/// 整张 sheet 用 [SelectionArea] 包住,所有 [Text] 自动可选,长按弹出系统
/// 选择菜单(自带 Copy / Look Up / Share…)。比每个 value 单独用
/// [SelectableText] 稳:在 `showModalBottomSheet` 里单独 SelectableText 的
/// toolbar Overlay 经常被 sheet 自己的 ModalRoute 截断,菜单就不弹。
void showAccountDetailSheet(BuildContext context, PlatformAccount account) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // 顶部 16px 圆角。BottomSheet 默认 shape 是直角,iOS 风格上不习惯。
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    // 不用 showDragHandle:它在最顶部插一个 DragHandle widget,会跟
    // SelectionArea 的长按选区手势抢焦点。
    builder: (_) => _AccountDetailSheet(account: account),
  );
}

class _AccountDetailSheet extends StatelessWidget {
  const _AccountDetailSheet({required this.account});

  final PlatformAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      // `Material` 显式给 SelectionArea 提供 surface 颜色 + 文字主题上下文,
      // iOS 26 上 SelectionArea 在 modal route 里需要父级 Material 才能正确
      // 挂到 system context menu。
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: SelectionArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题:显示名(若有)+ 用户名(主标识)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (account.displayName.isNotEmpty)
                            Text(account.displayName, style: theme.textTheme.titleLarge),
                          if (account.displayName.isNotEmpty) const SizedBox(height: 2),
                          Text(account.login, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                        ],
                      ),
                    ),
                    PlatformBadge(platform: account.platform),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                // 元数据行:每行 label + value,空值不渲染该行
                _Row(label: l10n.accountDetailDisplayName, value: account.displayName, omitWhenEmpty: true),
                _Row(label: l10n.accountDetailLogin, value: account.login),
                _Row(label: l10n.accountDetailBaseUrl, value: account.baseUrl, omitWhenEmpty: true),
                _Row(label: l10n.accountDetailOrgId, value: account.orgId, omitWhenEmpty: true),
                _Row(label: l10n.accountDetailAuthType, value: account.authType.name),
                _Row(label: l10n.accountDetailAccountId, value: account.id),
                _Row(label: l10n.accountDetailCreatedAt, value: _formatCreatedAt(account.createdAt)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 本地时区的 `YYYY-MM-DD HH:mm` 格式,无外部依赖,够用。
  String _formatCreatedAt(DateTime t) {
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }
}

/// 单行 label + value。[omitWhenEmpty] 为 true 时 value 为空就整行不渲染。
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.omitWhenEmpty = false});

  final String label;
  final String? value;
  final bool omitWhenEmpty;

  @override
  Widget build(BuildContext context) {
    if (omitWhenEmpty && (value == null || value!.isEmpty)) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          ),
          Expanded(
            child: Text(
              value ?? '',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
