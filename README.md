# 🤖 My Agents & Skills

> 个人 GitHub Copilot Agents 和 Skills 的统一管理仓库。  
> 换设备时一键恢复，也可分享给团队成员直接使用。

---

## 📁 仓库结构

```
my-agents-and-skills/
├── agents/                    # 自定义 Copilot Agents (.agent.md)
├── skills/                    # 自定义 Copilot Skills (目录或文件)
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

**场景**：你在当前设备新建或修改了 Agent / Skill，想同步保存到 GitHub。

```bash
bash scripts/sync-to-repo.sh
```

**脚本会做什么：**
1. 扫描本地 `~/.config/Code/User/prompts/*.agent.md`，复制变更文件到 `agents/`
2. 扫描本地 `~/.copilot/skills/` 下的 Skills（支持目录和文件），复制变更内容到 `skills/`
3. 列出扫描到的本地 Agents/Skills
4. 列出本次成功同步到仓库的 Agents/Skills
5. 对本次同步到仓库的文件自动执行 `git add`
6. 不执行 `git commit` / `git push`

如需提交远程仓库，请手动执行：

```bash
git add agents skills scripts README.md
git commit -m "sync: update agents and skills"
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
4. 列出扫描到的仓库 Agents/Skills，以及本次成功同步到本地的内容
5. 提示重启 VS Code

> ⚠️ **执行完毕后请重启 VS Code**，新的 Agents / Skills 才会生效。

---

## 🔄 日常工作流

```
┌─────────────────────────────────────────────────────────────┐
│  在当前设备新建 / 修改了 Agent 或 Skill                      │
│                          │                                  │
│                          ▼                                  │
│          bash scripts/sync-to-repo.sh                       │
│          （仅同步本地文件到仓库目录）                        │
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

> 脚本只做**增量同步**（仅复制新增或有变更的文件），不会删除你本地已有的文件。

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
A: 不会。`sync-to-repo.sh` 只负责同步文件到仓库目录。是否提交和推送由你手动决定。

**Q: 支持 Windows 吗？**  
A: 脚本为 Bash 脚本，适用于 macOS / Linux。Windows 用户请使用 WSL2 或 Git Bash 执行。

---

## 📜 License

MIT © [wandyqu-bsg](https://github.com/wandyqu-bsg)