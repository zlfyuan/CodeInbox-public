#!/usr/bin/env bash
# 拉 CPF-Flutter/flutter_flutter（鸿蒙 fork）到 ~/.ohos-flutter/，并把它接到当前 shell 的 PATH 前面。
#
# 鸿蒙 SDK 放在本机 ~/.ohos-flutter，可与其他工程共用，不进本仓库。
#
# 设计原则：
# - 不动全局 Flutter：iOS / Android 继续用官方 3.32.8（~/development/flutter）。
# - 不进项目：fork 拉到 ~/.ohos-flutter/，避免污染 git。
# - 国内默认可走 pub / storage 镜像。
#
# 版本锁定：oh-3.35.7-release（基于上游 Flutter 3.35.7，随分支带 Dart 3.9.2）。
# - 本仓库 ohos/ 由此分支 `flutter create --platforms ohos` 生成。
# - 含 `flutter build hap`、ohos 模板、@ohos/flutter_ohos。
# - 选 release 分支而非 dev：三方库适配最多、最稳；且随分支的 Dart 3.9.2 满足
#   pubspec.yaml 的 `sdk: ^3.8.1` 下界，无需为鸿蒙单独放宽约束。
# - 注意 Dart 版本是 3.9.2（不是 3.8.x）：业务代码仍须保持 Dart 3.8 语法，
#   因为 iOS / Android 锁官方 3.32.8 / Dart 3.8.1。
# - 上游 tag 3.47.x / master 没有 ohos 适配，不能当鸿蒙 SDK 用。
#
# 用法：
#   source tools/setup_ohos_flutter.sh
#   source tools/setup_ohos_env.sh
#   flutter --version     # Channel 应指向 gitcode，Flutter 3.35.7 / Dart 3.9.2
#
# 卸载当前 shell 的切换：
#   unset FLUTTER_ROOT OHOS_FLUTTER_ROOT
#   # 重新开一个终端即回到官方 Flutter
#
# 删掉本地 fork：
#   rm -rf ~/.ohos-flutter
#
# 已知 fork 修正（每次 source 自动应用，备份在 ~/.ohos-flutter.patches/）：
# 1. version.dart 去掉「channel != master/main 则跳过 git tag」的早返——oh-* 分支是 detached HEAD，
#    不走 tag 解析的话 `flutter pub get` 会把 SDK 当 0.0.0-unknown。
# 2. 在本地打一个 `<flutter_version>` 注解 tag（默认 3.35.7），让 git describe 出真实版本号。
# 3. 删 bin/cache/flutter.version.json 触发重建；stamp hash 改变会触发 flutter_tools.snapshot 重编译。

set -euo pipefail

# 2026-06 仓库迁到 CPF-Flutter；openharmony-sig / openharmony-tpc 旧地址会跳转，新 clone 走新组织。
OHOS_FLUTTER_REPO="${OHOS_FLUTTER_REPO:-https://gitcode.com/CPF-Flutter/flutter_flutter.git}"
OHOS_FLUTTER_HOME="${OHOS_FLUTTER_HOME:-$HOME/.ohos-flutter}"
OHOS_FLUTTER_BRANCH="${OHOS_FLUTTER_BRANCH:-oh-3.35.7-release}"
OHOS_FLUTTER_VERSION_TAG="${OHOS_FLUTTER_VERSION_TAG:-3.35.7}"

# 国内镜像（用户可选覆盖）
PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"

# source 时不能改调用方 cwd，否则紧接着 source setup_ohos_env.sh 会找不到脚本。
_OHOS_FLUTTER_OLD_PWD="$PWD"

# --- 1. 克隆 / 更新 fork ---
if [ ! -d "$OHOS_FLUTTER_HOME/.git" ]; then
  echo "[setup_ohos_flutter] cloning $OHOS_FLUTTER_REPO ($OHOS_FLUTTER_BRANCH) → $OHOS_FLUTTER_HOME"
  git clone --depth 1 --branch "$OHOS_FLUTTER_BRANCH" "$OHOS_FLUTTER_REPO" "$OHOS_FLUTTER_HOME"
else
  echo "[setup_ohos_flutter] using existing $OHOS_FLUTTER_HOME (branch=$OHOS_FLUTTER_BRANCH)"
  cd "$OHOS_FLUTTER_HOME"
  # 已存在的 shallow clone：放宽 remote refspec 让 fetch 能拉到目标 branch
  git config --get remote.origin.fetch >/dev/null 2>&1 \
    || git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  git fetch --tags --depth 1 origin "$OHOS_FLUTTER_BRANCH" \
    || git fetch --tags --depth 1 origin "+$OHOS_FLUTTER_BRANCH:$OHOS_FLUTTER_BRANCH"
  git checkout --detach FETCH_HEAD 2>/dev/null || git checkout "$OHOS_FLUTTER_BRANCH"
fi

# --- 2. 初始化 git submodules（engine artifacts；3.44 起 engine 已合进仓库，可能没有） ---
cd "$OHOS_FLUTTER_HOME"
if [ -f .gitmodules ]; then
  git submodule update --init --depth 1
fi

# --- 3. 应用 fork patch：去掉 version.dart 的「非 master/main 不 fetchTags」早返 ---
_VERSION_DART="$OHOS_FLUTTER_HOME/packages/flutter_tools/lib/src/version.dart"
if [ -f "$_VERSION_DART" ] && ! grep -q "CPF-Flutter fork patch" "$_VERSION_DART"; then
  echo "[setup_ohos_flutter] patching $_VERSION_DART"
  mkdir -p "$HOME/.ohos-flutter.patches"
  cp "$_VERSION_DART" "$HOME/.ohos-flutter.patches/version.dart.$(date +%Y%m%d%H%M%S).bak"
  python3 - "$_VERSION_DART" <<'PY'
import re, sys
path = sys.argv[1]
src = open(path).read()
old = re.search(
    r'FlutterVersion fetchTagsAndGetVersion\([^)]*\)\s*\{.*?return this;\s*\}',
    src, re.S)
if not old:
    print('[skip] no early-return block found, version.dart may already be patched', file=sys.stderr)
    sys.exit(0)
new = '''FlutterVersion fetchTagsAndGetVersion({SystemClock clock = const SystemClock()}) {
    // We don't need to fetch tags on beta and stable to calculate the version,
    // we should already exactly be on a tag that was pushed when this release
    // was published.
    // CPF-Flutter fork patch: detached HEAD on oh-* branches doesn't expose a
    // matching semver tag upstream, so always re-resolve via git describe to
    // pick up the locally stamped `<flutter_version>` tag set by
    // `setup_ohos_flutter.sh`. Without this `flutter pub get` rejects plugins
    // that require a minimum Flutter SDK version (e.g. share_plus).
    return FlutterVersion(
      clock: clock,
      flutterRoot: flutterRoot,
      fs: fs,
      fetchTags: true,
      git: _git,
    );
  }'''
open(path, 'w').write(src.replace(old.group(0), new))
print('[ok] version.dart patched')
PY
else
  echo "[setup_ohos_flutter] version.dart already patched or missing"
fi

# --- 4. 在本地 HEAD 打 <flutter_version> 注解 tag，让 git describe 出真实版本号 ---
if ! git describe --tags --exact-match HEAD 2>/dev/null | grep -q "^${OHOS_FLUTTER_VERSION_TAG}$"; then
  echo "[setup_ohos_flutter] stamping local tag $OHOS_FLUTTER_VERSION_TAG on $(git rev-parse --short HEAD)"
  git tag -f -a "$OHOS_FLUTTER_VERSION_TAG" -m "CPF-Flutter fork local stamp for $OHOS_FLUTTER_BRANCH" HEAD
fi

# --- 5. 让 flutter_tools.snapshot / flutter.version.json 下次跑 flutter 时重建 ---
# bin/internal/update_dart_sdk.sh 也会重写 stamp 文件，stamp 改了 snapshot 必重建。
rm -f "$OHOS_FLUTTER_HOME/bin/cache/flutter.version.json"
rm -f "$OHOS_FLUTTER_HOME/bin/cache/flutter_tools.stamp"
echo "[setup_ohos_flutter] invalidated cache, flutter_tools.snapshot will regenerate on next call"

cd "$_OHOS_FLUTTER_OLD_PWD"
unset _OHOS_FLUTTER_OLD_PWD

# --- 6. 导出变量给调用方（只影响当前 shell） ---
export FLUTTER_ROOT="$OHOS_FLUTTER_HOME"
export OHOS_FLUTTER_ROOT="$OHOS_FLUTTER_HOME"
export PATH="$OHOS_FLUTTER_HOME/bin:$PATH"
export PUB_HOSTED_URL
export FLUTTER_STORAGE_BASE_URL
# 让 flutter doctor 不再抱怨「upstream 不是官方 github」。
export FLUTTER_GIT_URL="${FLUTTER_GIT_URL:-$(git -C "$OHOS_FLUTTER_HOME" remote get-url origin 2>/dev/null || echo "$OHOS_FLUTTER_REPO")}"

echo "[setup_ohos_flutter] FLUTTER_ROOT=$FLUTTER_ROOT"
echo "[setup_ohos_flutter] branch=$OHOS_FLUTTER_BRANCH"
echo "[setup_ohos_flutter] tag=$(git -C "$OHOS_FLUTTER_HOME" describe --tags HEAD 2>/dev/null || echo none)"
echo "[setup_ohos_flutter] PUB_HOSTED_URL=$PUB_HOSTED_URL"
echo "[setup_ohos_flutter] next:"
echo "  source tools/setup_ohos_env.sh"
echo "  flutter --version"
echo "  flutter doctor -v"
