# commit-code

智能提交代码的 Copilot Skill——自动分析改动、拆分 commits、推送到远程，并生成英文 MR 说明。

支持 Java · Scala · TypeScript · React 全栈项目，按功能层次自动拆分 commits，中英文交互。

---

## 功能特性

| 功能 | 说明 |
|---|---|
| 🛡️ 空改动守卫 | 无任何改动时立即停止，清晰提示使用方式 |
| 🔍 智能分析 | 读取本地 diff 与未推送 commits，理解改动意图 |
| 📦 多 commit 拆分 | 按依赖顺序拆分：重构 → 后端 → 配置 → 前端 → UT → Scala 测试 |
| 🤝 用户确认 | 拆分方案展示后等待确认，支持反复调整直到满意 |
| 🚀 顺序提交推送 | 确认后自动按顺序 `git add` + `git commit`，最后一次性 `git push` |
| 🔗 MR 链接生成 | Push 成功后可选生成 GitLab MR 创建链接 |
| 📋 英文 MR Message | 生成结构化英文 MR 说明，可直接粘贴到 Jira comment |

---

## 安装

### 前提条件

- VS Code 已安装并登录 [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat)
- Git（已配置 remote 和分支）

### 步骤

1. 进入此 skill 目录，运行安装脚本：
   ```bash
   cd path/to/commit-code
   bash install.sh
   ```

2. **重启 VS Code**（首次安装后需要重启让 Copilot 识别新 skill）

3. 在 Copilot Chat 中输入 `/` 验证：`/commit-code` 出现在列表中即安装成功

### 更新

安装使用 symlink，更新只需：

```bash
git pull
```

无需重新安装。

---

## 使用方式

### 基本使用

在 VS Code Copilot Chat 中直接触发：

```
/commit-code
```

也可以附带说明改动意图（可选）：

```
/commit-code 这次主要是重构 FundEntity 的货币验证逻辑，然后基于此支持 Local Admin 修改产品货币
```

### 触发场景

| 场景 | 说明 |
|---|---|
| 有本地未提交的改动 | 修改了文件但未 `git add` / `git commit` |
| 有本地未推送的 commits | 已 `git commit` 但未 `git push` |
| 混合状态 | 同时有 local diff 和 unpushed commits，统一处理 |

### 典型工作流

```
1. 开发完成，直接触发 /commit-code
2. AI 分析改动，展示拆分建议（含文件列表和 commit message）
3. 确认方案（或告知调整意见）
4. AI 按顺序自动 commit 并 push
5. 可选：生成英文 MR message 粘贴到 Jira
```

---

## Commit Message 规范

本 skill 遵循团队规范生成 commit message：

- **格式：** `{工单号} {英文描述}`
- **工单号：** 从分支名自动提取（`FB-103348-mike.wang` → `FB-103348`）
- **英文描述：** 动词原形开头，首字母大写，≤ 72 字符

**示例：**
```
FB-103348 Refactor FundEntity to extract currency validation logic
FB-103348 Support Local Admin to Change Product Currency
FB-103348 Add unit tests for currency change flow
```

---

## Commit 拆分策略

改动按以下依赖顺序分组（空分组自动省略）：

| 顺序 | 分组 | 文件范围 |
|---|---|---|
| 1 | 代码重构（先铺路） | 仅含结构性改动，无新业务逻辑 |
| 2 | 后端功能 | `src/` 下 `.java`/`.groovy`，排除 `src/test/` |
| 3 | 配置/其他 | `.properties`/`.yml`/`.xml`/`.json` 等 |
| 4 | 前端 | `react-apps/` 下 `.ts`/`.tsx`/`.js`/`.jsx`/`.css` |
| 5 | Java 单元测试 | `src/test/` 下测试文件 |
| 6 | Scala 自动化测试 | `functional-test/` / `integration-test-scala/` |

> **合并规则：** 重构与后端功能难以区分时（同一个类内既有结构调整又有新逻辑），自动合并为单个 commit，不强行拆分。

---

## 仓库结构

```
commit-code/
├── SKILL.md      # Skill 主文件（触发流程、拆分策略、输出模板）
├── install.sh    # 安装脚本
└── README.md     # 本文件
```
