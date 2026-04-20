#!/bin/bash
# =============================================================================
# sync-from-repo.sh
# 将 my-agents-and-skills 仓库里最新的 Agents 和 Skills 同步到本地
# 用法: bash scripts/sync-from-repo.sh
# =============================================================================

set -e

# ── 路径配置 ──────────────────────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOCAL_AGENTS_DIR="${HOME}/.config/Code/User/prompts"
LOCAL_SKILLS_DIR="${HOME}/.copilot/skills"
REPO_AGENTS_DIR="${REPO_DIR}/agents"
REPO_SKILLS_DIR="${REPO_DIR}/skills"

# ── 颜色输出 ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── 前置检查 ──────────────────────────────────────────────────────────────────
[ -d "$REPO_DIR/.git" ] || error "请在仓库目录内运行此脚本，或检查路径配置。"
command -v git &>/dev/null || error "未找到 git，请先安装。"

info "仓库路径: $REPO_DIR"

# ── 拉取最新仓库内容 ──────────────────────────────────────────────────────────
info "正在拉取仓库最新内容 (git pull)..."
cd "$REPO_DIR"
git pull

# ── 同步 Agents → 本地 ────────────────────────────────────────────────────────
mkdir -p "$LOCAL_AGENTS_DIR"
AGENT_COUNT=0

if [ -d "$REPO_AGENTS_DIR" ]; then
  while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    dest="${LOCAL_AGENTS_DIR}/${filename}"
    if [ ! -f "$dest" ] || ! diff -q "$file" "$dest" &>/dev/null; then
      cp "$file" "$dest"
      info "  [Agent] 已同步: $filename"
      AGENT_COUNT=$((AGENT_COUNT + 1))
    fi
  done < <(find "$REPO_AGENTS_DIR" -maxdepth 1 -name "*.agent.md" -print0)
  [ $AGENT_COUNT -eq 0 ] && warn "  [Agent] 没有新增或变更的 agent 文件。"
else
  warn "  [Agent] 仓库目录不存在: $REPO_AGENTS_DIR"
fi

# ── 同步 Skills → 本地 ────────────────────────────────────────────────────────
mkdir -p "$LOCAL_SKILLS_DIR"
SKILL_COUNT=0

if [ -d "$REPO_SKILLS_DIR" ]; then
  while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    [ "$filename" = "README.md" ] && continue
    dest="${LOCAL_SKILLS_DIR}/${filename}"
    if [ ! -f "$dest" ] || ! diff -q "$file" "$dest" &>/dev/null; then
      cp "$file" "$dest"
      info "  [Skill] 已同步: $filename"
      SKILL_COUNT=$((SKILL_COUNT + 1))
    fi
  done < <(find "$REPO_SKILLS_DIR" -maxdepth 1 -name "*.md" -print0)
  [ $SKILL_COUNT -eq 0 ] && warn "  [Skill] 没有新增或变更的 skill 文件。"
else
  warn "  [Skill] 仓库目录不存在: $REPO_SKILLS_DIR"
fi

# ── 完成提示 ──────────────────────────────────────────────────────────────────
echo ""
info "✅ 同步完成！"
info "   Agents 已写入: $LOCAL_AGENTS_DIR  (共 ${AGENT_COUNT} 个变更)"
info "   Skills 已写入: $LOCAL_SKILLS_DIR  (共 ${SKILL_COUNT} 个变更)"
echo ""
warn "👉 请重启 VS Code 以使新的 Agents / Skills 生效。"
