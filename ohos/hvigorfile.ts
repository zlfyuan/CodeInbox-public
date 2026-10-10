// 不走 flutter 自带的 hvigor 构建插件：本仓没有 CPF 三方 ohos 插件，
// `.flutter-plugins-dependencies` 里没有 plugins.ohos，
// injectNativeModules / findFlutterPlugins 会对 undefined 调 .filter，
// DevEco 直接跑 hvigorw 会 00305010。引擎走 oh-package.json5 的本地 flutter.har。
//
// ⚠️ 本文件任何位置（包括注释）都不许出现 flutter / hvigor / plugin 三段连写的包名：
// flutter_tools 是靠「文本包含」来判断走哪套 builder 的
// （packages/flutter_tools/lib/src/ohos/hvigor_utils.dart 的 useHvigorTsBuilder）。
// 一旦命中，`flutter build hap` 会跳过 flutter assemble —— 不重编 Dart、不刷新
// entry/src/main/resources/rawfile/flutter_assets，DevEco 跑出来就永远是旧代码。
// 需要描述它时，写「flutter 自带的 hvigor 插件」即可。
import { appTasks } from '@ohos/hvigor-ohos-plugin';

export default {
    system: appTasks,  /* Built-in plugin of Hvigor. It cannot be modified. */
    plugins:[]         /* Custom plugin to extend the functionality of Hvigor. */
}