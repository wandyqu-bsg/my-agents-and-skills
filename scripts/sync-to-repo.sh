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
REPO_AGENTS_DIR="${REPO_DIR}/agents"
REPO_SKILLS_DIR="${REPO_DIR}/skills"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
step()  { echo -e "${BLUE}[STEP]${NC}  $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

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

mkdir -p "$REPO_AGENTS_DIR" "$REPO_SKILLS_DIR"

info "仓库路径: ${REPO_DIR}"
step "扫描本地自定义 Agents / Skills ..."

local_agents=()
local_skills=()
sync_agents=()
sync_skills=()
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

echo ""
print_list "扫描到的本地 Agents:" "${local_agents[@]}"
print_list "扫描到的本地 Skills:" "${local_skills[@]}"
echo ""
print_list "成功同步到仓库的 Agents:" "${sync_agents[@]}"
print_list "成功同步到仓库的 Skills:" "${sync_skills[@]}"
echo ""

if [ ${#local_agents[@]} -eq 0 ] && [ ${#local_skills[@]} -eq 0 ]; then
  warn "未检测到本地自定义 Agents/Skills，可先在 VS Code 中创建后再同步。"
fi

if [ ${#sync_agents[@]} -eq 0 ] && [ ${#sync_skills[@]} -eq 0 ]; then
  info "没有需要更新到仓库的文件，当前已经是最新同步状态。"
else
  git -C "$REPO_DIR" add -- "${staged_paths[@]}"
  info "本地内容已同步到仓库目录（仅文件同步，未执行 git 提交/推送）。"
  info "本次同步的文件已执行 git add，便于你后续手动提交。"
fi

echo ""
info "如果你觉得这些 Agents/Skills 很好用，欢迎手动 git push 分享到远程仓库。"
