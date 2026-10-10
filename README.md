# CodeInbox

Unified mobile inbox for GitHub, Gitee, GitLab, Codeup, Gongfeng, and CODING review requests. Flutter, Android + iOS + HarmonyOS NEXT.

Tokens stay on device (Keychain / Keystore / HUKS). There is no backend.

## Run

iOS and Android use the official Flutter SDK (Dart 3.8). Do not source the HarmonyOS Flutter fork in that shell.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

### iOS signing

The Apple Team ID is not in the repo. For a physical device, copy the example and fill in your own team:

```bash
cp ios/Flutter/Local.xcconfig.example ios/Flutter/Local.xcconfig
```

`Local.xcconfig` is gitignored. Debug, Profile, and Release read `DEVELOPMENT_TEAM` from it.

### iOS 26 physical device

`flutter run` (debug / JIT) crashes on launch on iOS 26 phones:

`Unable to flip between RX and RW memory protection on pages`

This is Flutter 3.32 + Dart 3.8.1, not an app bug. iOS 26 blocks the RX↔RW page flip that debug JIT needs. Simulator debug is fine. On a phone use AOT:

```bash
flutter run --profile
# or
flutter run --release
```

No hot reload in profile or release. On-device debug with hot reload needs Flutter 3.35 or newer. Do not bump a shared official SDK that other local apps still need at 3.32. The `UIScene lifecycle will soon be required` line is a warning only.

### HarmonyOS

Use a new terminal. The fork stays in `~/.ohos-flutter` and is not committed.

```bash
source tools/setup_ohos_flutter.sh
source tools/setup_ohos_env.sh
set +e
flutter build hap --debug --no-codesign
```

`ohos/` is already in the repo. Do not run `flutter create --platforms ohos`. Signing material (p12, encrypted passwords, machine paths) is not in the repo. Configure signing in DevEco locally, and do not commit it back into `ohos/build-profile.json5`.

`lib/` must stay compilable on Dart 3.8.

## Accounts

The app only asks for a personal access token. Tokens are stored in the platform secure store and are not logged.

### GitHub

1. Open **Settings → Developer settings → Personal access tokens → Tokens (classic)**.
2. Create a token with `repo`, `notifications`, and `read:user`.
3. Fine-grained tokens cannot read notifications reliably. Use classic.

`https://github.com/settings/tokens/new?description=CodeInbox&scopes=repo,notifications,read:user`

### Gitee

1. Open https://gitee.com/personal_access_tokens
2. Enable `user_info`, `projects`, pull-request scopes, and notifications.

Gitee has no global “review requested” API. The inbox scans at most the 20 most recently updated repositories.

### GitLab

1. Open `{base}/-/user_settings/personal_access_tokens` on gitlab.com or your instance.
2. Create a token with the `api` scope.
3. In the app, set **Base URL** (`https://gitlab.com` or your instance) and paste the token.

### Codeup

Create a token at https://devops.aliyun.com/user/setting. The default API base is `https://openapi-rdc.aliyuncs.com`.

### Gongfeng

Create a private token at **Profile → Account** (`https://git.code.tencent.com/profile/account`, or the same path on a self-hosted instance). Set **Base URL** before pasting the token. The inbox scans at most 20 repositories.

### CODING

Set the team URL first (`https://your-team.coding.net`), then create a token under that team’s account settings. The inbox scans at most 20 projects.

## Layout

- `lib/domain` — shared models and `ForgeAdapter`
- `lib/data/adapters` — GitHub, Gitee, GitLab, Codeup, Gongfeng, CODING
- `lib/ui` — Inbox, Alerts, Repos, Me

Tapping a change request opens in-app detail: description, files, comments, and review or merge when that host supports it. Large or missing diffs open in the browser.

## Privacy

This version has no backend and no ad, analytics, or crash-reporting SDK.

- Tokens stay in the system secure store. They are not written to preferences and not logged.
- Account labels and the inbox cache stay on the device.
- API calls go from the device straight to the host you added. A comment you submit is sent only to that host.
- Nothing is sold, and tokens are not sent to the author of CodeInbox.

## License

MIT. See [LICENSE](LICENSE).
