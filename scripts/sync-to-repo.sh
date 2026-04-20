cd ~/dev/my-agents-and-skills   # 进入你的仓库目录

cat > scripts/sync-to-repo.sh << 'ENDOFSCRIPT'
#!/bin/bash
# =============================================================================
# sync-to-repo.sh
# 将本地自定义的 Agents 和 Skills 同步到 my-agents-and-skills 仓库
# 用法: bash scripts/sync-to-repo.sh
# =============================================================================

set -e

# -- 路径配置 ------------------------------------------------------------------
REPO_DIR="$(git rev-parse --show-toplevel)"
LOCAL_AGENTS_DIR="${HOME}/.config/Code/User/prompts"
LOCAL_SKILLS_DIR="${HOME}/.copilot/skills"
REPO_AGENTS_DIR="${REPO_DIR}/agents"
REPO_SKILLS_DIR="${REPO_DIR}/skills"

# -- 颜色输出 ------------------------------------------------------------------
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# -- 前置检查 ------------------------------------------------------------------
[ -d "$REPO_DIR/.git" ] || error "请在仓库目录内运行此脚本。"
command -v git &>/dev/null || error "未找到 git，请先安装。"

info "仓库路径: $REPO_DIR"
info "开始同步本地 Agents / Skills 到仓库..."

# -- 同步 Agents (.agent.md) ---------------------------------------------------
mkdir -p "$REPO_AGENTS_DIR"
AGENT_COUNT=0

if [ -d "$LOCAL_AGENTS_DIR" ]; then
  while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    dest="${REPO_AGENTS_DIR}/${filename}"
    if [ ! -f "$dest" ] || ! diff -q "$file" "$dest" &>/dev/null; then
      cp "$file" "$dest"
      info "  [Agent] 已同步: $filename"
      AGENT_COUNT=$((AGENT_COUNT + 1))
    fi
  done < <(find "$LOCAL_AGENTS_DIR" -maxdepth 1 -name "*.agent.md" -print0)
  [ $AGENT_COUNT -eq 0 ] && warn "  [Agent] 没有新增或变更的 agent 文件。"
else
  warn "  [Agent] 本地目录不存在: $LOCAL_AGENTS_DIR"
fi

# -- 同步 Skills ---------------------------------------------------------------
mkdir -p "$REPO_SKILLS_DIR"
SKILL_COUNT=0

if [ -d "$LOCAL_SKILLS_DIR" ]; then
  while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    dest="${REPO_SKILLS_DIR}/${filename}"
    if [ ! -f "$dest" ] || ! diff -q "$file" "$dest" &>/dev/null; then
      cp "$file" "$dest"
      info "  [Skill] 已同步: $filename"
      SKILL_COUNT=$((SKILL_COUNT + 1))
    fi
  done < <(find "$LOCAL_SKILLS_DIR" -maxdepth 1 -name "*.md" -print0)
  [ $SKILL_COUNT -eq 0 ] && warn "  [Skill] 没有新增或变更的 skill 文件。"
else
  warn "  [Skill] 本地目录不存在: $LOCAL_SKILLS_DIR"
fi

# -- 自动生成 agents/README.md -------------------------------------------------
info "正在更新 agents/README.md ..."
{
  printf '# Agents\n\n'
  printf '本目录存放所有自定义 GitHub Copilot Agents。\n\n'
  printf '| 文件名 | 大小 | 最后修改时间 |\n'
  printf '|--------|------|-------------|\n'
  for f in "$REPO_AGENTS_DIR"/*.agent.md; do
    [ -f "$f" ] || continue
    fname=$(basename "$f")
    fsize=$(wc -c < "$f" | tr -d ' ')
    fdate=$(date -r "$f" '+%Y-%m-%d %H:%M' 2>/dev/null || stat -c '%y' "$f" | cut -d' ' -f1,2 | cut -c1-16)
    printf '| `%s` | %s bytes | %s |\n' "$fname" "$fsize" "$fdate"
  done
  printf '\n> 自动生成于 %s，请勿手动编辑此文件。\n' "$(date '+%Y-%m-%d %H:%M:%S')"
} > "${REPO_AGENTS_DIR}/README.md"

# -- 自动生成 skills/README.md -------------------------------------------------
info "正在更新 skills/README.md ..."
{
  printf '# Skills\n\n'
  printf '本目录存放所有自定义 GitHub Copilot Skills。\n\n'
  printf '| 文件名 | 大小 | 最后修改时间 |\n'
  printf '|--------|------|-------------|\n'
  for f in "$REPO_SKILLS_DIR"/*.md; do
    [ -f "$f" ] || continue
    fname=$(basename "$f")
    [ "$fname" = "README.md" ] && continue
    fsize=$(wc -c < "$f" | tr -d ' ')
    fdate=$(date -r "$f" '+%Y-%m-%d %H:%M' 2>/dev/null || stat -c '%y' "$f" | cut -d' ' -f1,2 | cut -c1-16)
    printf '| `%s` | %s bytes | %s |\n' "$fname" "$fsize" "$fdate"
  done
  printf '\n> 自动生成于 %s，请勿手动编辑此文件。\n' "$(date '+%Y-%m-%d %H:%M:%S')"
} > "${REPO_SKILLS_DIR}/README.md"

# -- Git 提交并推送 ------------------------------------------------------------
cd "$REPO_DIR"
git add agents/ skills/

if git diff --cached --quiet; then
  warn "没有任何变更需要提交。"
else
  COMMIT_MSG="sync: local to repo [$(date '+%Y-%m-%d')] agents:${AGENT_COUNT} skills:${SKILL_COUNT}"
  git commit -m "$COMMIT_MSG"

  # 优先尝试 SSH，失败则自动切换 HTTPS
  if git push 2>/dev/null; then
    info "推送完成（SSH）！提交信息: $COMMIT_MSG"
  else
    warn "SSH 推送失败，尝试通过 HTTPS 推送..."
    REMOTE_URL=$(git remote get-url origin)
    HTTPS_URL=$(echo "$REMOTE_URL" | sed 's|git@github.com:|https://github.com/|')
    git push "$HTTPS_URL"
    info "推送完成（HTTPS）！提交信息: $COMMIT_MSG"
  fi
fi
ENDOFSCRIPT

# 推送到 GitHub
chmod +x scripts/sync-to-repo.sh
git add scripts/sync-to-repo.sh
git commit -m "fix: rewrite sync-to-repo.sh to fix all syntax errors"
git push