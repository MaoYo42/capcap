#!/bin/bash
# 本地构建 + 替换 /Applications/capcap.app
#
# 与上游 bundle.sh 的区别：
#   - 默认用本机 Apple Development 证书签名（可用 SIGN_IDENTITY 覆盖）。
#     签名身份稳定，TCC 的「辅助功能 / 屏幕录制」授权在重新构建后不会丢。
#   - 替换前把旧版本整体移到 ~/.capcap-backup/，不做 rm -rf。
#   - 自动清掉 quarantine，避免 Gatekeeper 拦截。
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

APP_NAME="capcap.app"
BUILT_APP="$REPO_DIR/build/$APP_NAME"
TARGET_APP="/Applications/$APP_NAME"
BACKUP_DIR="$HOME/.capcap-backup"
CONFIG="${CONFIG:-release}"

if [ -z "${SIGN_IDENTITY:-}" ]; then
    SIGN_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null \
        | sed -n 's/.*"\(Apple Development:.*\)"/\1/p' | head -1)"
fi
if [ -z "${SIGN_IDENTITY:-}" ]; then
    echo "warning: 没有可用的 Apple Development 证书，将退化为 ad-hoc 签名（每次重建都要重新授权）" >&2
    SIGN_IDENTITY="-"
fi
echo "签名身份: $SIGN_IDENTITY"

echo "== 构建 ($CONFIG) =="
SIGN_IDENTITY="$SIGN_IDENTITY" bash scripts/bundle.sh --"$CONFIG"

echo "== 备份旧版本 =="
STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
if [ -d "$TARGET_APP" ]; then
    mv "$TARGET_APP" "$BACKUP_DIR/capcap-$STAMP.app"
    echo "旧版本已移到 $BACKUP_DIR/capcap-$STAMP.app"
else
    echo "未发现已安装的 capcap.app，跳过备份"
fi

echo "== 退出运行中的实例 =="
pkill -x capcap 2>/dev/null || true
sleep 1

echo "== 安装 =="
ditto "$BUILT_APP" "$TARGET_APP"
xattr -dr com.apple.quarantine "$TARGET_APP" 2>/dev/null || true

echo "== 校验签名 =="
codesign --verify --deep --strict "$TARGET_APP"
echo "签名校验通过"

echo "== 启动 =="
open -a "$TARGET_APP"
echo "完成。首次运行需要在「系统设置 → 隐私与安全性」里重新勾选辅助功能和屏幕录制（签名变了，旧授权不再匹配）。"
