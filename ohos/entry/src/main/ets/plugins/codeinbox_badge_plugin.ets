// CodeInbox 桌面角标。Dart 已有 MethodChannel('codeinbox/badge')。
// 鸿蒙第一刀与 Android 相同：空实现 success，不申请通知权限。
import {
  FlutterEngine,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult
} from '@ohos/flutter_ohos';

const CHANNEL_NAME = 'codeinbox/badge';

export class CodeInboxBadgePlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;

  getUniqueClassName(): string {
    return 'CodeInboxBadgePlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'setBadge') {
      result.success(null);
      return;
    }
    result.notImplemented();
  }

  static registerWith(engine: FlutterEngine): void {
    engine.getPlugins()?.add(new CodeInboxBadgePlugin());
  }
}
