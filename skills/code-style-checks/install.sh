#!/bin/bash
# ============================================================
# code-style-checks skill 安装脚本
#
# 使用方式（从本目录之外调用）：
#   bash /path/to/code-style-checks/install.sh
#
# 安装方式：将本目录 symlink 到 ~/.copilot/skills/code-style-checks
#   安装后更新只需在本目录执行 git pull，无需重新安装。
#
# 若本目录已在 ~/.copilot/skills/code-style-checks 下，直接使用即可，
# 无需重新安装。
# ============================================================

set -e

SKILL_NAME="code-style-checks"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 支持 GitHub Copilot 的 skill 目录
COPILOT_SKILLS_DIR="$HOME/.copilot/skills"
TARGET="$COPILOT_SKILLS_DIR/$SKILL_NAME"

echo "========================================="
echo "  安装 $SKILL_NAME skill"
echo "========================================="
echo ""
echo "来源:  $SCRIPT_DIR"
echo "目标:  $TARGET"
echo ""

# 如果 SCRIPT_DIR 就是 TARGET，说明已经在正确位置，无需安装
if [ "$SCRIPT_DIR" = "$TARGET" ]; then
    echo "✅  skill 已在正确位置，无需安装。"
    echo ""
    echo "提示：重启 VS Code 后即可在 Copilot Chat 中使用 /code-style-checks。"
    echo ""
    exit 0
fi

# 创建目标父目录（如不存在）
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
ln -s "$SCRIPT_DIR" "$TARGET"

echo "✅  安装完成！"
echo ""
echo "  symlink: $TARGET"
echo "       →   $SCRIPT_DIR"
echo ""
echo "下一步："
echo "  重启 VS Code（首次安装后必须），"
echo "  然后在 Copilot Chat 中输入 /code-style-checks 开始使用。"
echo ""
echo "提示：此目录（code-style-checks/）可整体拷贝给他人，"
echo "      对方运行 bash install.sh 即可完成安装。"
echo ""
