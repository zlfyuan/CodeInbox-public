# CodeInbox

[English](README.md) · [简体中文](README.zh-CN.md)

统一管理 GitHub、Gitee、GitLab、Codeup、工蜂（Gongfeng）和 CODING 评审请求的移动端收件箱。基于 Flutter 开发，支持 Android、iOS 和 HarmonyOS NEXT。

访问令牌仅保存在设备本地（iOS Keychain / Android Keystore / 鸿蒙 HUKS），无后端服务。

## 运行

iOS 和 Android 使用官方 Flutter SDK（Dart 3.8）。在该 shell 中不要 `source` 鸿蒙的 Flutter 分支。

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

### iOS 签名

仓库中不包含 Apple Team ID。如需在真机上运行，请复制示例文件并填写你自己的 Team ID：

```bash
cp ios/Flutter/Local.xcconfig.example ios/Flutter/Local.xcconfig
```

`Local.xcconfig` 已被加入 `.gitignore`。Debug、Profile 和 Release 三种构建都从此文件中读取 `DEVELOPMENT_TEAM`。

### iOS 26 真机

`flutter run`（debug / JIT 模式）在 iOS 26 真机上启动时会崩溃：

`Unable to flip between RX and RW memory protection on pages`

这是 Flutter 3.32 + Dart 3.8.1 自身的问题，并非本应用 bug。iOS 26 阻止了 debug JIT 所需的 RX↔RW 页面切换。模拟器上 debug 模式正常运行；真机请使用 AOT：

```bash
flutter run --profile
# 或
flutter run --release
```

profile 和 release 模式下不支持热重载。在真机上使用带热重载的 debug 模式需要 Flutter 3.35 或更高版本。请勿将本机公共的官方 SDK 升级到 3.35，因为其他本地应用仍依赖 3.32。`UIScene lifecycle will soon be required` 这行只是警告。

### 鸿蒙

请使用新的终端。鸿蒙 Flutter 分支位于 `~/.ohos-flutter`，不会提交到仓库。

```bash
source tools/setup_ohos_flutter.sh
source tools/setup_ohos_env.sh
set +e
flutter build hap --debug --no-codesign
```

`ohos/` 目录已在仓库中。不要执行 `flutter create --platforms ohos`。签名材料（p12、加密后的密码、机器路径）均不在仓库内，请在本地 DevEco 中配置签名，不要回写到 `ohos/build-profile.json5`。

`lib/` 必须保持可在 Dart 3.8 上编译通过。

## 账号

应用只要求填写一个个人访问令牌。令牌存储在平台的安全存储中，不会被记录。

### GitHub

1. 打开 **Settings → Developer settings → Personal access tokens → Tokens (classic)**。
2. 创建具有 `repo`、`notifications` 和 `read:user` 权限的令牌。
3. Fine-grained 令牌无法可靠读取通知，请使用 classic 令牌。

`https://github.com/settings/tokens/new?description=CodeInbox&scopes=repo,notifications,read:user`

### Gitee

1. 打开 https://gitee.com/personal_access_tokens
2. 勾选 `user_info`、`projects`、pull-request 权限以及通知权限。

Gitee 没有全局的“评审请求”API。本应用最多扫描最近更新的 20 个仓库。

### GitLab

1. 在 gitlab.com 或你自己的实例上打开 `{base}/-/user_settings/personal_access_tokens`。
2. 创建一个具有 `api` 权限的令牌。
3. 在应用中设置 **Base URL**（`https://gitlab.com` 或你自己的实例地址），然后粘贴令牌。

### Codeup

在 https://devops.aliyun.com/user/setting 创建令牌。默认 API 地址为 `https://openapi-rdc.aliyuncs.com`。

### 工蜂（Gongfeng）

在 **个人中心 → 账号** 创建私有令牌（地址 `https://git.code.tencent.com/profile/account`，自建实例路径相同）。粘贴令牌前先设置 **Base URL**。本应用最多扫描 20 个仓库。

### CODING

先设置团队 URL（`https://your-team.coding.net`），再在该团队的账号设置中创建令牌。本应用最多扫描 20 个项目。

## 目录结构

- `lib/domain` — 共享模型与 `ForgeAdapter`
- `lib/data/adapters` — GitHub、Gitee、GitLab、Codeup、工蜂、CODING
- `lib/ui` — 收件箱、通知、仓库、我

点击变更请求会在应用内打开详情页：描述、文件、评论，以及在对应平台支持下进行评审或合并。过大的或缺失的 diff 会在浏览器中打开。

## 隐私

本版本没有后端，也没有广告、分析或崩溃上报的 SDK。

- 令牌保留在系统的安全存储中，不会写入偏好设置，也不会被记录。
- 账号标识和收件箱缓存都保存在设备本地。
- API 请求由设备直接发送到你所添加的平台。你提交的评论只会发送至该平台。
- 不会出售任何信息，令牌也不会发送给 CodeInbox 的作者。

## 许可

MIT，详见 [LICENSE](LICENSE)。
