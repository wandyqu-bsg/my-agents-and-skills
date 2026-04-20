#!/bin/bash
# =============================================================================
# sync-from-repo.sh
# 将仓库中的 Agents / Skills 同步到本地 VS Code 目录
# 用法: bash scripts/sync-from-repo.sh
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

[ -d "${REPO_DIR}/.git" ] || error "请在 my-agents-and-skills 仓库目录中运行脚本。"
command -v git >/dev/null 2>&1 || error "未检测到 git，请先安装。"

mkdir -p "$LOCAL_AGENTS_DIR" "$LOCAL_SKILLS_DIR"

info "仓库路径: ${REPO_DIR}"
step "拉取远程仓库最新内容 ..."
cd "$REPO_DIR"
git pull --ff-only

step "扫描仓库中的 Agents / Skills ..."

repo_agents=()
repo_skills=()
sync_agents=()
sync_skills=()

if [ -d "$REPO_AGENTS_DIR" ]; then
  while IFS= read -r -d '' file; do
    name="$(basename "$file")"
    repo_agents+=("$name")
    dest="${LOCAL_AGENTS_DIR}/${name}"
    if [ ! -f "$dest" ] || ! cmp -s "$file" "$dest"; then
      cp "$file" "$dest"
      sync_agents+=("$name")
    fi
  done < <(find "$REPO_AGENTS_DIR" -maxdepth 1 -type f -name "*.agent.md" -print0 | sort -z)
else
  warn "仓库 Agents 目录不存在: $REPO_AGENTS_DIR"
fi

if [ -d "$REPO_SKILLS_DIR" ]; then
  while IFS= read -r -d '' entry; do
    rel_name="$(basename "$entry")"
    [ "$rel_name" = ".gitkeep" ] && continue
    [ "$rel_name" = "README.md" ] && continue
    repo_skills+=("$rel_name")

    dest="${LOCAL_SKILLS_DIR}/${rel_name}"
    if [ -d "$entry" ]; then
      if [ ! -d "$dest" ] || ! diff -qr "$entry" "$dest" >/dev/null 2>&1; then
        mkdir -p "$dest"
        cp -a "$entry"/. "$dest"/
        sync_skills+=("$rel_name/")
      fi
    elif [ -f "$entry" ]; then
      if [ ! -f "$dest" ] || ! cmp -s "$entry" "$dest"; then
        cp "$entry" "$dest"
        sync_skills+=("$rel_name")
      fi
    fi
  done < <(find "$REPO_SKILLS_DIR" -mindepth 1 -maxdepth 1 \( -type d -o -type f \) ! -name ".*" -print0 | sort -z)
else
  warn "仓库 Skills 目录不存在: $REPO_SKILLS_DIR"
fi

echo ""
print_list "扫描到的仓库 Agents:" "${repo_agents[@]}"
print_list "扫描到的仓库 Skills:" "${repo_skills[@]}"
echo ""
print_list "成功同步到本地的 Agents:" "${sync_agents[@]}"
print_list "成功同步到本地的 Skills:" "${sync_skills[@]}"
echo ""

if [ ${#repo_agents[@]} -eq 0 ] && [ ${#repo_skills[@]} -eq 0 ]; then
  warn "仓库中暂未发现可同步的 Agents/Skills。"
fi

if [ ${#sync_agents[@]} -eq 0 ] && [ ${#sync_skills[@]} -eq 0 ]; then
  info "本地已是最新，无需同步。"
else
  info "远程仓库中的 Agents/Skills 已同步到本地目录。"
fi

warn "请重启 VS Code，使新同步的 Agents/Skills 生效。"
