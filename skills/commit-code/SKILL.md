---
name: commit-code
description: "智能拆分 commits、按团队规范生成 commit message、确认后推送到远程并输出英文 MR 说明。Use when: 提交代码、git commit、push 代码、创建 MR、commit and push、生成 commit message、智能拆分 commit、push commits"
argument-hint: "可选：说明本次改动的主要意图，或留空由 AI 自动分析"
---

# 提交代码 (Commit Code)

智能分析本地改动，按功能层次拆分为多个 commits，用户确认后推送到远程，并可生成英文 MR 说明（用于粘贴到 Jira）。

---

## Commit Message 规范

- **格式：** `{工单号} {英文描述}`
- **工单号来源：** 当前分支名中提取前两段（`FB-103348-mike.wang` → `FB-103348`）
- **英文描述：** 首字母大写，动词原形开头，描述改动内容和意图
- **总长度：** ≤ 72 个字符（含工单号和空格）
- **不使用** `feat:` / `fix:` 等 conventional commits 前缀

**示例：**
```
FB-103348 Refactor FundEntity to extract currency validation logic
FB-103348 Support Local Admin to Change Product Currency
FB-103348 Add unit tests for PortfolioFundCurrencyEditableTest
```

---

## 执行步骤

### Step 0 — 前置守卫（空改动检测）

**在执行任何操作之前**，先检测是否存在可提交的内容：

```bash
git rev-parse --abbrev-ref HEAD          # 获取当前分支名
git diff HEAD --stat                     # 检查本地未提交改动
git log origin/<branch>..HEAD --oneline  # 检查本地未推送 commits
```

- **两者均为空** → **立即停止**，输出以下提示并不再执行后续步骤：

  ```
  ⚠️ 未检测到任何代码改动。

  当前工作区没有未提交的变更，也没有未推送的 commits。

  你可以通过以下方式使用本 skill：

  | 场景                    | 说明                                         |
  |-------------------------|----------------------------------------------|
  | 有本地未提交的改动      | 直接修改文件后触发 /commit-code              |
  | 有已 commit 未推送的内容 | 本地有 git commit 但未 push 时触发           |
  | 混合状态                | 本地 diff + unpushed commits 均会被纳入处理  |
  ```

- **只要有一类改动存在**（本地 diff 或未推送 commits）→ 继续执行

若工单号无法从分支名中提取（分支名不含 `-` 分隔的两段），告知用户并请求手动提供工单号。

---

### Step 1 — 收集完整改动信息

```bash
git remote get-url origin               # 获取 remote URL（用于构建 MR 链接）
git diff HEAD                           # 本地未提交的完整 diff
git log origin/<branch>..HEAD --oneline # 未推送 commits 列表（若有）
git show <commit-hash>                  # 对每个未推送 commit 读取详细 diff
```

将以下两类改动合并进行统一分析：
- **Local diff**：`git diff HEAD` 中的文件改动
- **Unpushed commits**：本地已 commit 但未 push 的改动

> 若改动文件超过 30 个，先用 `git diff HEAD --stat` 获取文件列表概览，优先读取改动量最大的文件内容。

---

### Step 2 — 智能分析与多 Commit 拆分

分析所有改动文件，按以下**依赖顺序**分组（空分组自动省略）：

| 提交顺序 | 分组名称 | 文件判断规则 |
|---|---|---|
| 1 | **代码重构** | 仅包含结构性改动的文件（rename、move、extract method、无新业务逻辑）|
| 2 | **后端功能** | `src/` 下 `.java` / `.groovy`，排除 `src/test/` 路径 |
| 3 | **配置 / 其他** | `.properties` / `.yml` / `.xml` / `.json` / `build.xml` 等 |
| 4 | **前端** | `react-apps/` 下 `.ts` / `.tsx` / `.js` / `.jsx` / `.css` |
| 5 | **Java 单元测试** | `src/test/` 下的测试文件 |
| 6 | **Scala 自动化测试** | `functional-test/` 或 `integration-test-scala/` 下的文件 |

**分析规则：**
- 每个文件只归入一个分组，同一文件不重复出现
- **重构与后端功能难以区分时**（如同一个类内既有结构调整又有新业务逻辑），合二为一，不强行拆分，message 体现主要意图
- 若只有一类改动，直接生成单个 commit，不需要拆分
- 对未推送 commits 中已有的文件，保持其原有分组逻辑，不重复提交

**等待用户确认前，输出建议方案：**

```
======================================
📋 检测到改动，建议拆分为 N 个 commits（按提交顺序）：

Commit 1/N：重构
  Message:  FB-XXXXXX Refactor FundEntity to extract currency validation
  文件 (2): src/com/.../FundEntity.java
            src/com/.../CurrencyValidator.java

Commit 2/N：后端功能
  Message:  FB-XXXXXX Support Local Admin to Change Product Currency
  文件 (3): src/com/.../PortfolioController.java
            src/com/.../CurrencyService.java
            src/com/.../FundCurrencyDto.java

Commit 3/N：Java 单元测试
  Message:  FB-XXXXXX Add unit tests for currency change flow
  文件 (1): src/test/com/.../PortfolioControllerTest.java

======================================
是否使用此拆分方案？
- 回复"确认"直接使用
- 或告诉我调整意见（如合并某些 commits、调整文件归属、修改 message）
======================================
```

若用户提出修改意见，调整方案并重新展示，直到用户确认。

---

### Step 3 — 按顺序执行提交

用户确认方案后，**逐个 commit** 执行以下命令：

```bash
# 对每个 commit（按确认的顺序）：
git add <该 commit 的文件列表（空格分隔，使用相对路径）>
git commit -m "<确认的 commit message>"
```

全部 commit 完成后，一次性推送：

```bash
git push origin <当前分支名>
```

**错误处理：**
- 任何命令失败 → 立即停止，展示完整错误信息，不继续执行后续命令，不自动重试
- **禁止** `git push --force` 或任何改写历史的操作
- 若 push 因远程有新 commit 而失败，提示用户先执行 `git pull --rebase` 后再触发本 skill

输出每个 commit 的执行结果（hash + message），最后展示 push 结果。

---

### Step 4 — 生成 MR 信息（可选）

Push 成功后，询问用户：

```
✅ 已成功推送 N 个 commits 到远程。

是否需要生成 MR 信息（可直接粘贴到 Jira comment）？
- 回复"是"或"生成"即可
- 回复"否"或"不用"跳过
```

用户确认后，输出：

**1. GitLab MR 创建链接（解析方式按优先级）：**

- **GitLab push 输出中包含 URL**（最可靠）：直接使用 `git push` 输出中的链接
- **手动构建**（备选）：从 `git remote get-url origin` 解析 host / namespace / project：
  ```
  https://<gitlab-host>/<namespace>/<project>/-/merge_requests/new?merge_request[source_branch]=<branch>&merge_request[target_branch]=main
  ```
  若主分支不确定是 `main` 还是 `master`，展示两个选项供用户选择。

**2. 英文 MR Message**（用于 Jira comment 或 MR description）：

```
**[FB-XXXXXX] <MR Title — 简短描述本次改动的核心目标>**

**Summary:**
<2–3 句话描述本次改动的背景和目标>

**Changes:**
- <改动点 1，动词开头>
- <改动点 2>
- <改动点 3（如有）>

**Commits:**
- `<hash1>` <commit message 1>
- `<hash2>` <commit message 2>
```

MR message 使用英文，语言简洁专业，面向 code reviewer。

---

**最终完整输出格式：**

```
======================================
✅ 提交完成
======================================
分支：<branch-name>

Commits 已推送：
  <hash1> FB-XXXXXX Refactor ...
  <hash2> FB-XXXXXX Support ...
  <hash3> FB-XXXXXX Add unit tests ...

🔗 创建 MR（复制链接到浏览器打开）：
<MR URL>

📋 MR Message（可粘贴到 Jira）：
<英文 MR message>
======================================
```

---

## 约束

- `git add` 和 `git commit` **只在用户明确确认拆分方案后**才执行
- **禁止** `git push --force` 或任何改写历史的操作（如 `--amend`、`rebase -i`）
- Commit message 超过 72 字符时必须重新生成，不得截断
- 发生任何 git 错误立即停止并告知用户，不自动重试
- 同一文件不能出现在多个 commits 中
