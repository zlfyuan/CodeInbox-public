// CodeInbox 打开链接。Dart OhosOpenUrl → 系统浏览器（viewData）。
// MethodChannel: codeinbox/open_url
//
// 不走应用内 ArkWeb：iOS / Android 的 IOpenUrl 本来就是外开浏览器。
import {
  FlutterEngine,
  FlutterPlugin,
  FlutterPluginBinding,
  AbilityAware,
  AbilityPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult
} from '@ohos/flutter_ohos';
import { BusinessError } from '@ohos.base';
import { common, Want } from '@kit.AbilityKit';

const CHANNEL_NAME = 'codeinbox/open_url';

export class CodeInboxOpenUrlPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  // startAbility 需要 UIAbilityContext，application context 拉不起来浏览器。
  private ctx: common.UIAbilityContext | null = null;

  getUniqueClassName(): string {
    return 'CodeInboxOpenUrlPlugin';
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

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.ctx = binding.getAbility().context as common.UIAbilityContext;
  }

  onDetachedFromAbility(): void {
    this.ctx = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method !== 'openUrl') {
      result.notImplemented();
      return;
    }
    const url = call.argument('url') as string | undefined;
    if (url == null || url.length === 0) {
      result.error('BAD_ARGS', 'missing string argument: url', null);
      return;
    }
    const ctx = this.ctx;
    if (ctx == null) {
      result.error('NO_CONTEXT', 'UIAbilityContext not attached', null);
      return;
    }
    const want: Want = {
      action: 'ohos.want.action.viewData',
      uri: url
    };
    ctx.startAbility(want)
      .then(() => result.success(true))
      .catch((e: BusinessError) => result.error('OPEN_FAIL', e.message, null));
  }

  static registerWith(engine: FlutterEngine): void {
    engine.getPlugins()?.add(new CodeInboxOpenUrlPlugin());
  }
}
