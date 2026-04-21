#!/bin/bash
# ============================================================
# code-review-fixer skill 安装脚本
#
# 使用方式：
#   bash install.sh
#
# 安装方式：symlink（推荐）
#   安装后只需在本 repo 执行 git pull 即可获取最新版 skill，
#   无需重新安装。
# ============================================================

set -e

SKILL_NAME="code-review-fixer"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SOURCE="$SCRIPT_DIR"

# 支持 GitHub Copilot 的 skill 目录
COPILOT_SKILLS_DIR="$HOME/.copilot/skills"

TARGET="$COPILOT_SKILLS_DIR/$SKILL_NAME"

echo "========================================="
echo "  安装 $SKILL_NAME skill"
echo "========================================="
echo ""
echo "来源:  $SKILL_SOURCE"
echo "目标:  $TARGET"
echo ""

# 创建目标目录（如不存在）
mkdir -p "$COPILOT_SKILLS_DIR"

# 如果目标已存在且是普通目录（非 symlink），备份它
if [ -d "$TARGET" ] && [ ! -L "$TARGET" ]; then
    BACKUP="${TARGET}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "⚠️  已存在普通目录，备份到: $BACKUP"
    mv "$TARGET" "$BACKUP"
fi

# 如果已是 symlink，先删除旧的再重建
if [ -L "$TARGET" ]; then
    echo "🔄  更新已有 symlink..."
    rm "$TARGET"
fi

# 创建 symlink
ln -s "$SKILL_SOURCE" "$TARGET"

echo ""
echo "✅  安装完成！"
echo ""
echo "使用方式："
echo "  在 VS Code Copilot 聊天中输入 /code-review-fixer 触发 skill"
echo ""
echo "推荐工作流："
echo "  /layered-code-review  →  /code-review-fixer  →  /peer-review"
echo ""
echo "更新方式："
echo "  cd $(dirname "$SCRIPT_DIR") && git pull"
echo "  （symlink 方式无需重新安装）"
echo ""
