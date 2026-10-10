// CodeInbox KV。Dart OhosPrefs → @ohos.data.preferences。
// MethodChannel: codeinbox/prefs
//
// 协议：ready / getString / setString / getInt / setInt / getBool / setBool / remove
// 取参必须 call.argument('key')：StandardMessageCodec 把 Dart Map 解成 JS Map，
// call.args['key'] 永远是 undefined，会让 store.load() 失败、runApp 进不去。
import {
  FlutterEngine,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult
} from '@ohos/flutter_ohos';
import dataPreferences from '@ohos.data.preferences';
import { BusinessError } from '@ohos.base';
import { common } from '@kit.AbilityKit';

const CHANNEL_NAME = 'codeinbox/prefs';
const STORE_NAME = 'codeinbox_kv';

export class CodeInboxPrefsPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  // getPreferences 是异步的；ready() 和读写都等这个 Promise，避免 NOT_READY 竞态。
  private opened: Promise<dataPreferences.Preferences> | null = null;

  getUniqueClassName(): string {
    return 'CodeInboxPrefsPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    const context: common.Context = binding.getApplicationContext();
    this.opened = dataPreferences.getPreferences(context, { name: STORE_NAME });
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    this.opened = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    const opened = this.opened;
    if (opened == null) {
      result.error('NOT_READY', 'preferences store not opened yet', null);
      return;
    }
    if (call.method === 'ready') {
      opened
        .then(() => result.success(null))
        .catch((e: BusinessError) => result.error('NOT_READY', e.message, null));
      return;
    }
    opened
      .then((prefs: dataPreferences.Preferences) => this.handle(prefs, call, result))
      .catch((e: BusinessError) => result.error('NOT_READY', e.message, null));
  }

  private handle(
    prefs: dataPreferences.Preferences,
    call: MethodCall,
    result: MethodResult
  ): void {
    const key = call.argument('key') as string | undefined;
    if (key == null) {
      result.error('BAD_ARGS', 'missing string argument: key', null);
      return;
    }
    switch (call.method) {
      case 'getString':
        if (!prefs.hasSync(key)) {
          result.success(null);
          return;
        }
        prefs.get(key, '')
          .then((v: dataPreferences.ValueType) => result.success(v as string))
          .catch((e: BusinessError) => result.error('GET_FAIL', e.message, null));
        return;
      case 'setString':
        prefs.put(key, call.argument('value') as string)
          .then(() => prefs.flush())
          .then(() => result.success(null))
          .catch((e: BusinessError) => result.error('SET_FAIL', e.message, null));
        return;
      case 'getInt':
        if (!prefs.hasSync(key)) {
          result.success(null);
          return;
        }
        prefs.get(key, 0)
          .then((v: dataPreferences.ValueType) => result.success(v as number))
          .catch((e: BusinessError) => result.error('GET_FAIL', e.message, null));
        return;
      case 'setInt':
        prefs.put(key, call.argument('value') as number)
          .then(() => prefs.flush())
          .then(() => result.success(null))
          .catch((e: BusinessError) => result.error('SET_FAIL', e.message, null));
        return;
      case 'getBool':
        if (!prefs.hasSync(key)) {
          result.success(null);
          return;
        }
        prefs.get(key, false)
          .then((v: dataPreferences.ValueType) => result.success(v as boolean))
          .catch((e: BusinessError) => result.error('GET_FAIL', e.message, null));
        return;
      case 'setBool':
        prefs.put(key, call.argument('value') as boolean)
          .then(() => prefs.flush())
          .then(() => result.success(null))
          .catch((e: BusinessError) => result.error('SET_FAIL', e.message, null));
        return;
      case 'remove':
        prefs.delete(key)
          .then(() => prefs.flush())
          .then(() => result.success(null))
          .catch((e: BusinessError) => result.error('REMOVE_FAIL', e.message, null));
        return;
      default:
        result.notImplemented();
        return;
    }
  }

  static registerWith(engine: FlutterEngine): void {
    engine.getPlugins()?.add(new CodeInboxPrefsPlugin());
  }
}
