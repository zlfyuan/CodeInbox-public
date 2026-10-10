import 'package:flutter/services.dart';

import '../../data/open_url.dart';

/// 鸿蒙打开链接。通道 `codeinbox/open_url` → `startAbility(viewData)` 系统浏览器。
///
/// 不走 `url_launcher`（无 ohos 实现），也不做应用内 ArkWeb：CodeInbox 的
/// `IOpenUrl` 在 iOS / Android 本来就是外开浏览器（PAT 页 / 大 diff 回落）。
class OhosOpenUrl implements IOpenUrl {
  OhosOpenUrl({MethodChannel? channel})
      : _ch = channel ?? const MethodChannel('codeinbox/open_url');

  final MethodChannel _ch;

  @override
  Future<void> open(String url) async {
    final ok = await _ch.invokeMethod<bool>('openUrl', {'url': url});
    if (ok != true) throw Exception('Could not open browser');
  }
}
