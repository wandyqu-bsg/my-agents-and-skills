# 🤖 My Agents & Skills

> 个人 GitHub Copilot Agents 和 Skills 的统一管理仓库。  
> 换设备时一键恢复，也可分享给团队成员直接使用。

---

## 📁 仓库结构

```
my-agents-and-skills/
├── agents/                    # 自定义 Copilot Agents (.agent.md)
│   └── ruyi.agent.md          # Ruyi senior technical partner
├── skills/                    # 自定义 Copilot Skills (目录或文件)
│   └── ruyi-ruyi/             # Ruyi personal memory review workflow
├── memory/                    # 可迁移的个人规则与跨项目 knowledge 源
│   ├── instructions.md
│   └── knowledge/
├── scripts/
│   ├── sync-to-repo.sh        # ⬆️  本地 → 仓库（备份）
│   └── sync-from-repo.sh      # ⬇️  仓库 → 本地（恢复/同步）
└── README.md
```

---

## 🚀 快速开始

### 第一步：Clone 仓库

```bash
git clone git@github.com:wandyqu-bsg/my-agents-and-skills.git
cd my-agents-and-skills
```

### 第二步：赋予脚本执行权限（只需第一次）

```bash
chmod +x scripts/sync-to-repo.sh
chmod +x scripts/sync-from-repo.sh
```

---

## 📖 两个脚本的使用说明

### ⬆️ `sync-to-repo.sh` — 本地备份到仓库

**场景**：你在当前设备新建或修改了 Agent、Skill 或 Ruyi Memory，想同步保存到 GitHub。

```bash
bash scripts/sync-to-repo.sh
```

**脚本会做什么：**
1. 扫描本地 `~/.config/Code/User/prompts/*.agent.md`，复制变更文件到 `agents/`
2. 扫描本地 `~/.copilot/skills/` 下的 Skills（支持目录和文件），复制变更内容到 `skills/`
3. 同步本地 `~/.copilot/instructions.md` 到 `memory/instructions.md`
4. 同步本地 `~/.copilot/knowledge/*.md` 到 `memory/knowledge/`
5. 列出扫描到的本地 Agents/Skills/Memory
6. 列出本次成功同步到仓库的 Agents/Skills/Memory
7. 对本次同步到仓库的文件自动执行 `git add`
8. 不执行 `git commit` / `git push`

> `knowledge` 中的跨项目 source path 应使用 repository identifier（例如 `backstop/app`），不要提交某台电脑的 `/home/...` 绝对路径。

如需提交远程仓库，请手动执行：

```bash
git add agents skills memory scripts README.md
git commit -m "sync: update agents skills and memory"
git push
```

---

### ⬇️ `sync-from-repo.sh` — 从仓库恢复到本地

**场景 A**：换了新设备，clone 完仓库后执行此脚本，立即恢复所有 Agents / Skills。  
**场景 B**：团队成员分享了新的 Agent / Skill 到仓库，你想同步到本地。

```bash
bash scripts/sync-from-repo.sh
```

**脚本会做什么：**
1. 自动执行 `git pull` 拉取最新仓库内容
2. 将 `agents/*.agent.md` 复制到本地 `~/.config/Code/User/prompts/`
3. 将 `skills/` 下的 Skills（目录或文件）复制到本地 `~/.copilot/skills/`
4. 将 `memory/instructions.md` 恢复到 `~/.copilot/instructions.md`
5. 将 `memory/knowledge/*.md` 恢复到 `~/.copilot/knowledge/`
6. 列出扫描到的仓库 Agents/Skills/Memory，以及本次成功同步到本地的内容
7. 不删除本地存在但仓库中没有的文件
8. 提示重启 VS Code

> ⚠️ **执行完毕后请重启 VS Code**，新的 Agents / Skills 才会生效。

---

## 🔄 日常工作流

```
┌─────────────────────────────────────────────────────────────┐
│  在当前设备新建 / 修改 Agent、Skill 或 Ruyi Memory             │
│                          │                                  │
│                          ▼                                  │
│          bash scripts/sync-to-repo.sh                       │
│          （同步文件并 git add，不 commit/push）               │
│                          │                                  │
│                          ▼                                  │
│      手动 git commit + git push（可选）                      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  换新设备 / 拉取团队最新 Agents & Skills                     │
│                          │                                  │
│                          ▼                                  │
│  git clone git@github.com:wandyqu-bsg/my-agents-and-skills  │
│  bash scripts/sync-from-repo.sh                             │
│  重启 VS Code ✅                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📂 本地目录说明

| 类型 | 本地路径 | 仓库路径 |
|------|----------|----------|
| Agents | `~/.config/Code/User/prompts/*.agent.md` | `agents/` |
| Skills | `~/.copilot/skills/`（目录或文件） | `skills/` |
| Personal instructions | `~/.copilot/instructions.md` | `memory/instructions.md` |
| Cross-project knowledge | `~/.copilot/knowledge/*.md` | `memory/knowledge/` |

> 脚本只做**增量同步**（仅复制新增或有变更的文件），不会删除你本地已有的文件。

## 🧷 项目文件 Git 约定

改动完成且窄范围验证通过后，只对属于当前项目、且确实属于本次任务的新增或修改文件执行精确 `git add`，使它们出现在 IDE 的 Git Local Changes/Staged Changes 视图中。

- 新增或修改文件：`git add -- path/to/file`
- 删除文件：`git add -u -- path/to/deleted-file`
- 不自动 stage 无关改动、日志、缓存、生成物、密钥、个人 IDE 配置或无法确认必要性的文件。
- staging 不等于 commit/push，提交和推送仍需单独确认。

## 🧠 Ruyi 个人记忆系统

Ruyi 使用分层记忆架构：

1. 当前会话：临时上下文、复现细节和未确认假设，不提交到仓库。
2. Personal instructions：跨工作区稳定的沟通、工程、调试、Review、测试和安全偏好。
3. Cross-project knowledge：跨仓库 ownership、dispatch、contract、version 和调试边界摘要。
4. Project knowledge：各业务仓库自己的源码、测试、README、`.github/` 和 `docs/`，仍然是实现事实的权威来源。

执行 `/ruyi-ruyi` 可以在会话结束后生成记忆更新提案。写入不同层需要不同的明确确认词，详情见 `memory/README.md` 和 `skills/ruyi-ruyi/SKILL.md`。

换电脑时执行 `sync-from-repo.sh` 会恢复 Ruyi agent、memory skill、个人 instructions 和 cross-project knowledge。

---

## 👥 团队成员使用方式

1. Clone 仓库（Public 仓库无需任何权限）：
   ```bash
   git clone git@github.com:wandyqu-bsg/my-agents-and-skills.git
   cd my-agents-and-skills
   chmod +x scripts/sync-from-repo.sh
   bash scripts/sync-from-repo.sh
   ```
2. 重启 VS Code，即可使用所有 Agents 和 Skills。
3. 想贡献新的 Agent / Skill？Fork 仓库 → 添加文件 → 发 Pull Request。

---

## ❓ 常见问题

**Q: Agent 里调用了某个 Skill，换设备后还能正常使用吗？**  
A: 可以。只要执行 `sync-from-repo.sh` 后，两者都会被恢复到对应目录，互相调用不受影响。

**Q: 脚本会覆盖我本地已有的文件吗？**  
A: 脚本使用增量对比，只有文件内容发生变更时才会覆盖，相同内容的文件不会被动。

**Q: `sync-to-repo.sh` 会自动推送到 GitHub 吗？**  
A: 不会。它只负责同步文件并对本次同步内容执行 `git add`。是否 `git commit` 和 `git push` 由你手动决定。

**Q: 个人记忆会把日志、Token 或当前电脑路径提交到仓库吗？**
A: 不会。记忆系统不同步日志、缓存、会话状态、凭据或私钥；跨项目 knowledge 应使用 repository identifier 和相对路径，避免机器绝对路径。

**Q: 支持 Windows 吗？**  
A: 脚本为 Bash 脚本，适用于 macOS / Linux。Windows 用户请使用 WSL2 或 Git Bash 执行。

---

## 📜 License

MIT © [wandyqu-bsg](https://github.com/wandyqu-bsg)