---
name: commit-code
description: "按团队规范生成 commit message，与开发者确认后提交代码并推送到远程，输出 GitLab MR 创建链接。Use when: 提交代码、git commit、push 代码、创建 MR、commit and push、生成 commit message"
argument-hint: "可选：commit message 草稿，或留空由 AI 自动生成"
---

# 提交代码 (Commit Code)

按团队规范生成 commit message，确认后提交代码并输出 GitLab MR 链接。

---

## Commit Message 规范

- **格式：** `{工单号} {英文描述}`
- **工单号来源：** 当前分支名中提取前两段（`FB-103348-mike.wang` → `FB-103348`）
- **英文描述：** 首字母大写，动词原形开头，描述改动内容和意图
- **总长度：** ≤ 72 个字符（含工单号和空格）
- **不使用** `feat:` / `fix:` 等 conventional commits 前缀

**示例：**
```
FB-103348 Support Local Admin to Change Product Currency
FB-103348 Fix null currency cascade issue on FundEntity
FB-103348 Add unit tests for PortfolioFundCurrencyEditableTest
```

---

## 执行步骤

### Step 1 — 收集信息

```bash
git rev-parse --abbrev-ref HEAD    # 获取当前分支名
git diff HEAD --stat               # 查看改动文件列表
git remote get-url origin          # 获取 remote URL（用于构建 MR 链接）
```

- 从分支名提取工单号（取 `-` 分隔的前两段）
- 若 `git diff HEAD` 无输出，检查是否有已暂存但未提交的改动（`git diff --cached --stat`）
- 若均无改动，告知用户当前没有可提交的内容并终止

### Step 2 — 生成 Commit Message

读取 `git diff HEAD`（或 `git diff --cached`）了解具体改动内容，综合改动范围生成候选消息：

```
======================================
建议的 commit message（共 XX 字符）：

  FB-XXXXXX Describe the main change here

字符计数说明：工单号 + 空格 + 描述 = XX 字符（≤ 72）
======================================
是否使用此消息？
- 回复"确认"直接使用
- 或告诉我修改意见（我将重新生成）
======================================
```

**等待用户确认。**

若用户提出修改意见，重新生成并再次展示，直到用户确认。
若工单号无法从分支名提取，告知用户并请求手动提供。

### Step 3 — 执行提交

用户确认 commit message 后，按顺序执行：

```bash
git add -A
git commit -m "<确认的 commit message>"
git push origin <当前分支名>
```

捕获每条命令的完整输出：
- 若任何命令失败，立即展示错误信息并停止，不继续执行后续命令
- `git push` 成功后解析输出中是否包含 GitLab 返回的 MR URL

### Step 4 — 生成 MR 链接

**解析方式（按优先级）：**

1. **GitLab 推送输出中包含 URL**（最可靠）：直接使用 `git push` 输出中的链接

2. **手动构建 URL**（备选）：
   从 `git remote get-url origin` 解析 host / namespace / project，构建：
   ```
   https://<gitlab-host>/<namespace>/<project>/-/merge_requests/new?merge_request[source_branch]=<branch>&merge_request[target_branch]=main
   ```
   注意：若项目主分支不是 `main`，尝试 `master`；若不确定，在 URL 中展示两个选项

**最终输出：**

```
======================================
✅ 提交完成
======================================
分支：<branch-name>
Commit：<short-hash> <commit-message>

🔗 创建 MR（复制链接到浏览器打开）：
<MR URL>
======================================
```

---

## 约束

- `git add` 和 `git commit` 只在用户确认 commit message 后执行
- **禁止** `git push --force` 或任何改写历史的操作
- commit message 超过 72 字符时必须重新生成，不得截断
- 发生任何错误立即停止并告知用户，不自动重试
