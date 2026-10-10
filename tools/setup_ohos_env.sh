#!/usr/bin/env bash
# 探测本机 DevEco Studio + HarmonyOS SDK，导出 Flutter-OH 能识别的环境变量。
# 使用本机 DevEco / HarmonyOS SDK，可与其他工程共用。
#
# Flutter-OH 读 SDK 的顺序（packages/flutter_tools/lib/src/ohos/ohos_sdk.dart）：
#   flutter config --ohos-sdk  >  DEVECO_SDK_HOME  >  HOS_SDK_HOME
# OpenHarmony 独立 SDK 走 OHOS_HOME / OHOS_SDK_HOME；本机没有独立 OH SDK，不走那条。
# 注意：OHOS_SDK_ROOT 这个名字 Flutter-OH 不认，不要再用。
#
# 已在本机验证（macOS arm64，2026-09-04）：
#   DevEco Studio 26.0.0（DS-261.23567.138.36.2600821）
#   HarmonyOS SDK 26.0.0.105（API 26）
#   ohpm 26.0.0.630 / node v24.14.1 / hvigorw 6.26.4 / hdc 3.2.0f
#   Java：DevEco 自带 jbr，版本随 DevEco 走（本机为 OpenJDK 25.0.2）
#
# 用法（先切鸿蒙 Flutter，再 source 本脚本）：
#   source tools/setup_ohos_flutter.sh
#   source tools/setup_ohos_env.sh
#   flutter doctor -v          # HarmonyOS toolchain 应为 ✓
#
# 脚本只 export 当前 shell，不改 ~/.zshrc。

set -euo pipefail

# --- 1. 定位 DevEco Studio（macOS 默认安装路径优先） ---
# HarmonyOS 6.x 的 SDK 在 $TOOL_HOME/sdk/default/（含 sdk-pkg.json + openharmony/ + hms/）
# 工具链（ohpm / hvigor / node）在 $TOOL_HOME/tools/，不在 SDK 目录里。
CANDIDATE_TOOL_HOMES=(
  "/Applications/DevEco-Studio.app/Contents"
  "$HOME/Applications/DevEco-Studio.app/Contents"
)

TOOL_HOME="${TOOL_HOME:-}"
if [ -z "$TOOL_HOME" ]; then
  for c in "${CANDIDATE_TOOL_HOMES[@]}"; do
    if [ -f "$c/sdk/default/sdk-pkg.json" ]; then
      TOOL_HOME="$c"
      break
    fi
  done
fi

if [ -z "$TOOL_HOME" ] || [ ! -d "$TOOL_HOME/sdk" ]; then
  echo "[setup_ohos_env] 未发现 DevEco Studio / HarmonyOS SDK。"
  echo "  请安装 DevEco Studio 6.0+："
  echo "    https://developer.huawei.com/consumer/cn/deveco-studio/"
  echo "  装好后重新 source，或手动指定："
  echo "    export TOOL_HOME=/Applications/DevEco-Studio.app/Contents"
  echo "    export DEVECO_SDK_HOME=\$TOOL_HOME/sdk"
  return 1 2>/dev/null || exit 1
fi

export TOOL_HOME
export DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-$TOOL_HOME/sdk}"
# Flutter-OH 同时认 HOS_SDK_HOME；与 DEVECO_SDK_HOME 指向同一处。
export HOS_SDK_HOME="${HOS_SDK_HOME:-$DEVECO_SDK_HOME}"

# --- 2. 把 ohpm / hvigor / node / hdc 接到 PATH 前面 ---
OHPM_BIN="$TOOL_HOME/tools/ohpm/bin"
HVIGOR_BIN="$TOOL_HOME/tools/hvigor/bin"
NODE_BIN="$TOOL_HOME/tools/node/bin"
# hdc 在 API 目录的 toolchains 下，不是 tools/
HDC_BIN="$DEVECO_SDK_HOME/default/openharmony/toolchains"

for b in "$OHPM_BIN" "$HVIGOR_BIN" "$NODE_BIN" "$HDC_BIN"; do
  if [ -d "$b" ]; then
    case ":$PATH:" in
      *":$b:"*) ;;
      *) export PATH="$b:$PATH" ;;
    esac
  fi
done

if [ -x "$HDC_BIN/hdc" ]; then
  export HDC_HOME="$HDC_BIN"
fi

# --- 2.5 JAVA_HOME：hvigorw 在 PackageHap 阶段调用 java，macOS arm64 不再带 Java ---
# DevEco 自带 jbr，版本随 DevEco 走（6.x 是 JBR17，26.x 是 JBR25，不要写死 17）；
# 没有 jbr 就尝试 /usr/libexec/java_home，再退回 brew openjdk。
JBR_HOME="$TOOL_HOME/jbr/Contents/Home"
JAVA_HOME="${JAVA_HOME:-}"
if [ -z "$JAVA_HOME" ] && [ -x "$JBR_HOME/bin/java" ]; then
  JAVA_HOME="$JBR_HOME"
elif [ -z "$JAVA_HOME" ] && command -v /usr/libexec/java_home >/dev/null 2>&1; then
  JAVA_HOME="$(/usr/libexec/java_home 2>/dev/null || true)"
elif [ -z "$JAVA_HOME" ] && [ -x "/opt/homebrew/opt/openjdk@17/bin/java" ]; then
  JAVA_HOME="/opt/homebrew/opt/openjdk@17"
fi
if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
  export JAVA_HOME
  case ":$PATH:" in
    *":$JAVA_HOME/bin:"*) ;;
    *) export PATH="$JAVA_HOME/bin:$PATH" ;;
  esac
fi

# --- 2.6 给 DevEco 准备本地 flutter.har ---
# DevEco 直接跑 hvigorw，不能用 flutter-hvigor-plugin（无 plugins.ohos 会 .filter crash）。
# 引擎 HAR 不入库（ohos/.gitignore 的 *.har），每次 source 若缺失就从 fork 缓存拷一份。
_OHOS_FLUTTER_HOME="${OHOS_FLUTTER_ROOT:-${FLUTTER_ROOT:-$HOME/.ohos-flutter}}"
_OHOS_HAR_SRC="$_OHOS_FLUTTER_HOME/bin/cache/artifacts/engine/ohos-arm64/flutter.har"
# 假定在仓库根 source（cwd 含 ohos/）；不猜 BASH_SOURCE，zsh source 时 $0 不是脚本路径。
if [ -d ohos ] && [ -f "$_OHOS_HAR_SRC" ]; then
  mkdir -p ohos/har
  if [ ! -f ohos/har/flutter.har ] || ! cmp -s "$_OHOS_HAR_SRC" ohos/har/flutter.har; then
    cp "$_OHOS_HAR_SRC" ohos/har/flutter.har
    echo "[setup_ohos_env] copied flutter.har → ohos/har/flutter.har"
  fi
fi
unset _OHOS_FLUTTER_HOME _OHOS_HAR_SRC

# --- 3. 若当前 shell 已是鸿蒙 Flutter，写入 flutter config --ohos-sdk ---
if command -v flutter >/dev/null 2>&1; then
  flutter config --ohos-sdk="$DEVECO_SDK_HOME" >/dev/null
fi

# --- 4. 打印探测结果，方便对照 flutter doctor ---
echo "[setup_ohos_env] TOOL_HOME=$TOOL_HOME"
echo "[setup_ohos_env] DEVECO_SDK_HOME=$DEVECO_SDK_HOME"
if [ -f "$DEVECO_SDK_HOME/default/sdk-pkg.json" ]; then
  echo "[setup_ohos_env] sdk-pkg=$(python3 -c "import json; d=json.load(open('$DEVECO_SDK_HOME/default/sdk-pkg.json')); print(d['data'].get('displayName',''), d['data'].get('version',''), 'API', d['data'].get('apiVersion',''))" 2>/dev/null || echo "$DEVECO_SDK_HOME/default")"
fi
echo "[setup_ohos_env] ohpm=$(command -v ohpm 2>/dev/null || echo MISSING)"
echo "[setup_ohos_env] hvigorw=$(command -v hvigorw 2>/dev/null || echo MISSING)"
echo "[setup_ohos_env] node=$(command -v node 2>/dev/null || echo MISSING) $(node -v 2>/dev/null || true)"
echo "[setup_ohos_env] hdc=$(command -v hdc 2>/dev/null || echo MISSING)"
echo "[setup_ohos_env] java=$(command -v java 2>/dev/null || echo MISSING) JAVA_HOME=${JAVA_HOME:-MISSING}"
echo "[setup_ohos_env] next: flutter doctor -v"
