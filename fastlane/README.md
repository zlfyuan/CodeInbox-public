fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

仅推送元数据/截图,不重新打包、不上传二进制(审核信息更新用)

### ios release

```sh
[bundle exec] fastlane ios release
```

Release:打包 + 上传元数据 + 上传二进制(首次发布 / 升级用)

### ios build

```sh
[bundle exec] fastlane ios build
```

仅编译,不打包 ipa(本地 smoke 用)

### ios delete_locale

```sh
[bundle exec] fastlane ios delete_locale
```

删指定 locale 的 App Store Version Localization(走 Spaceship API,不重新打包)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
