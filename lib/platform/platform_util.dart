import 'dart:io' show Platform;

/// 平台判断的单一入口。业务代码禁止直接写 `Platform.isIOS` / `Platform.isAndroid`：
/// 鸿蒙 fork 把 `operatingSystem` 设为 `ohos`，但部分插件仍会把 ohos 误报成 Android。
class PlatformUtil {
  PlatformUtil._();

  /// 鸿蒙 NEXT。测试 / CI 可设 `CODEINBOX_OHOS=1` 强制走鸿蒙分支。
  static bool get isOHOS {
    if (Platform.operatingSystem == 'ohos') return true;
    return Platform.environment['CODEINBOX_OHOS'] == '1';
  }

  static bool get isIOS => !isOHOS && Platform.isIOS;

  static bool get isAndroid => !isOHOS && Platform.isAndroid;
}
