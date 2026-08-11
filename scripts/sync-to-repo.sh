#!/bin/bash
# =============================================================================
# sync-to-repo.sh
# 将本地自定义的 Agents / Skills 同步到仓库目录（只同步文件，不提交远程）
# 用法: bash scripts/sync-to-repo.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

LOCAL_AGENTS_DIR="${HOME}/.config/Code/User/prompts"
LOCAL_SKILLS_DIR="${HOME}/.copilot/skills"
LOCAL_MEMORY_INSTRUCTIONS="${HOME}/.copilot/instructions.md"
LOCAL_MEMORY_KNOWLEDGE_DIR="${HOME}/.copilot/knowledge"
REPO_AGENTS_DIR="${REPO_DIR}/agents"
REPO_SKILLS_DIR="${REPO_DIR}/skills"
REPO_MEMORY_DIR="${REPO_DIR}/memory"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
step()  { echo -e "${BLUE}[STEP]${NC}  $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

normalize_knowledge() {
  local source_file="$1"
  local normalized_file="$2"
  sed -E \
    -e "s|${HOME}/\\.copilot|~/.copilot|g" \
    -e 's#/home/[^/[:space:]]+/dev/(backstop/app|fb-aws/account-recalculation)#\1#g' \
    "$source_file" > "$normalized_file"
}

print_list() {
  local title="$1"
  shift
  local items=("$@")
  echo "$title"
  if [ ${#items[@]} -eq 0 ]; then
    echo "  - (无)"
    return
  fi
  local item
  for item in "${items[@]}"; do
    echo "  - $item"
  done
}

[ -d "${REPO_DIR}/.git" ] || error "请在 my-agents-and-skills 仓库内运行脚本。"

mkdir -p "$REPO_AGENTS_DIR" "$REPO_SKILLS_DIR" "$REPO_MEMORY_DIR/knowledge"

info "仓库路径: ${REPO_DIR}"
step "扫描本地自定义 Agents / Skills ..."

local_agents=()
local_skills=()
local_memory=()
sync_agents=()
sync_skills=()
sync_memory=()
staged_paths=()

if [ -d "$LOCAL_AGENTS_DIR" ]; then
  while IFS= read -r -d '' file; do
    name="$(basename "$file")"
    local_agents+=("$name")
    dest="${REPO_AGENTS_DIR}/${name}"
    if [ ! -f "$dest" ] || ! cmp -s "$file" "$dest"; then
      cp "$file" "$dest"
      sync_agents+=("$name")
      staged_paths+=("agents/${name}")
    fi
  done < <(find "$LOCAL_AGENTS_DIR" -maxdepth 1 -type f -name "*.agent.md" -print0 | sort -z)
else
  warn "本地 Agents 目录不存在: $LOCAL_AGENTS_DIR"
fi

if [ -d "$LOCAL_SKILLS_DIR" ]; then
  while IFS= read -r -d '' entry; do
    rel_name="$(basename "$entry")"
    local_skills+=("$rel_name")
    dest="${REPO_SKILLS_DIR}/${rel_name}"

    if [ -d "$entry" ]; then
      if [ ! -d "$dest" ] || ! diff -qr "$entry" "$dest" >/dev/null 2>&1; then
        mkdir -p "$dest"
        cp -a "$entry"/. "$dest"/
        sync_skills+=("$rel_name/")
        staged_paths+=("skills/${rel_name}")
      fi
    elif [ -f "$entry" ]; then
      if [ ! -f "$dest" ] || ! cmp -s "$entry" "$dest"; then
        cp "$entry" "$dest"
        sync_skills+=("$rel_name")
        staged_paths+=("skills/${rel_name}")
      fi
    fi
  done < <(find "$LOCAL_SKILLS_DIR" -mindepth 1 -maxdepth 1 \( -type d -o -type f \) ! -name ".*" -print0 | sort -z)
else
  warn "本地 Skills 目录不存在: $LOCAL_SKILLS_DIR"
fi

if [ -f "$LOCAL_MEMORY_INSTRUCTIONS" ]; then
  local_memory+=("instructions.md")
  dest="${REPO_MEMORY_DIR}/instructions.md"
  if [ ! -f "$dest" ] || ! cmp -s "$LOCAL_MEMORY_INSTRUCTIONS" "$dest"; then
    cp "$LOCAL_MEMORY_INSTRUCTIONS" "$dest"
    sync_memory+=("instructions.md")
    staged_paths+=("memory/instructions.md")
  fi
else
  warn "本地个人 instructions 文件不存在: $LOCAL_MEMORY_INSTRUCTIONS"
fi

if [ -d "$LOCAL_MEMORY_KNOWLEDGE_DIR" ]; then
  normalized_knowledge_file="$(mktemp)"
  trap 'rm -f "$normalized_knowledge_file"' EXIT
  while IFS= read -r -d '' file; do
    rel_name="${file#${LOCAL_MEMORY_KNOWLEDGE_DIR}/}"
    display_name="knowledge/${rel_name}"
    local_memory+=("$display_name")
    dest="${REPO_MEMORY_DIR}/${display_name}"
    mkdir -p "$(dirname "$dest")"
    normalize_knowledge "$file" "$normalized_knowledge_file"
    if grep -qE '(^|[[:space:]`(])/(home|Users)/|[A-Za-z]:[\\/]' "$normalized_knowledge_file"; then
      warn "跳过 ${display_name}：仍包含未迁移的机器绝对路径，请改用 repository identifier。"
      continue
    fi
    if [ ! -f "$dest" ] || ! cmp -s "$normalized_knowledge_file" "$dest"; then
      cp "$normalized_knowledge_file" "$dest"
      sync_memory+=("$display_name")
      staged_paths+=("memory/${display_name}")
    fi
  done < <(find "$LOCAL_MEMORY_KNOWLEDGE_DIR" -type f -name "*.md" ! -name ".*" -print0 | sort -z)
else
  warn "本地 knowledge 目录不存在: $LOCAL_MEMORY_KNOWLEDGE_DIR"
fi

echo ""
print_list "扫描到的本地 Agents:" "${local_agents[@]}"
print_list "扫描到的本地 Skills:" "${local_skills[@]}"
print_list "扫描到的本地 Memory:" "${local_memory[@]}"
echo ""
print_list "成功同步到仓库的 Agents:" "${sync_agents[@]}"
print_list "成功同步到仓库的 Skills:" "${sync_skills[@]}"
print_list "成功同步到仓库的 Memory:" "${sync_memory[@]}"
echo ""

if [ ${#local_agents[@]} -eq 0 ] && [ ${#local_skills[@]} -eq 0 ] && [ ${#local_memory[@]} -eq 0 ]; then
  warn "未检测到本地自定义 Agents/Skills 或 Ruyi Memory，可先创建后再同步。"
fi

if [ ${#sync_agents[@]} -eq 0 ] && [ ${#sync_skills[@]} -eq 0 ] && [ ${#sync_memory[@]} -eq 0 ]; then
  info "没有需要更新到仓库的文件，当前已经是最新同步状态。"
else
  git -C "$REPO_DIR" add -- "${staged_paths[@]}"
  info "本地 Agents/Skills/Memory 已同步到仓库目录（仅文件同步，未执行 git 提交/推送）。"
  info "本次同步的文件已执行 git add，便于你后续手动提交。"
fi

echo ""
info "如果你觉得这些 Agents/Skills 很好用，欢迎手动 git push 分享到远程仓库。"
