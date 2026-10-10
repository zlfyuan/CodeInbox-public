import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { CodeInboxBadgePlugin } from '../plugins/codeinbox_badge_plugin';
import { CodeInboxOpenUrlPlugin } from '../plugins/codeinbox_open_url_plugin';
import { CodeInboxPrefsPlugin } from '../plugins/codeinbox_prefs_plugin';
import { CodeInboxSecureStorePlugin } from '../plugins/codeinbox_secure_store_plugin';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    // 自写 MethodChannel。GeneratedPluginRegistrant 只登记 CPF 三方 fork，对本仓是空的。
    CodeInboxPrefsPlugin.registerWith(flutterEngine)
    CodeInboxSecureStorePlugin.registerWith(flutterEngine)
    CodeInboxOpenUrlPlugin.registerWith(flutterEngine)
    CodeInboxBadgePlugin.registerWith(flutterEngine)
  }
}
