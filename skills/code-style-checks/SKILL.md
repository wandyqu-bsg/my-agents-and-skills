---
name: code-style-checks
description: "根据代码改动智能选择并执行本地静态检查（checkstyle / style-checks / static-analysis-checks / functional-test-checks / npm-lint），与用户确认后运行，失败时自动分析并修复，最多重试 3 次。Use when: 本地检查、静态检查、checkstyle、pmd、spotbugs、style check、lint、ant check、pre-commit checks、提交前检查"
argument-hint: "可选：commit ID 或文件路径（-- path/to/Foo.java）。不填则分析本地所有未提交改动"
---

# 代码风格检查 (Code Style Checks)

根据本地代码改动，智能识别需要执行哪些静态检查，与用户确认后逐项执行，并在失败时自动尝试修复。

**适用场景：**
- PR Workflow Step 5：提交代码前的最后质量门禁
- 独立运行：单独对当前改动执行静态检查

---

## 支持的检查命令与触发条件

| 命令 | 触发文件 | 检查内容 |
|---|---|---|
| `ant checkstyle` | `src/**/*.java`、`test/**/*.java`、`integration-test/**/*.java` | Java 代码风格（命名、格式、导入）|
| `ant style-checks` | `fitnesse/**` 或 `integration-test-scala/**/*.scala` 或 `integration-test/**/*.scala` | checkstyle + FitNesse 格式验证 + Scalastyle（集成测试）|
| `ant static-analysis-checks` | 任何 `.java` 文件 | PMD 规则 + SpotBugs 潜在 Bug（⚠️ 需先编译）|
| `ant functional-test-checks` | `functional-test/**/*.scala` | Functional test Scalastyle（via sbt）|
| `ant npm-lint` | `react-apps/**` | React / JS / TS 代码规范 |

> **去重规则**：`style-checks` 已包含 `checkstyle`，若两者均触发，只运行 `style-checks`，跳过单独的 `ant checkstyle`。

> **`static-analysis-checks` 说明**：包含 PMD + SpotBugs，SpotBugs 需要先完成 Java 编译（依赖 `package-backstop-jars`）。若编译未完成，此步可能耗时较长或报错。

---

## 执行流程

### Step 0 — 空变更守卫

**在执行任何检查之前**，先判断是否存在可分析的内容：

- **无参数时**：运行 `git diff HEAD --stat`，若输出为空，**立即停止**，输出：

  ```
  ⚠️ 未检测到任何代码改动。

  当前工作区没有未提交的变更（git diff HEAD 为空）。

  你可以通过以下方式使用本 skill：

  | 场景                   | 命令示例                                |
  |----------------------|---------------------------------------|
  | 检查本地所有未提交改动（默认）      | `/code-style-checks`                       |
  | 检查指定 commit          | `/code-style-checks abc1234`               |
  | 检查指定文件               | `/code-style-checks -- path/to/Foo.java`   |
  ```

- **指定 commit ID 时**：运行 `git show --stat <id>`，若报错，停止并提示。

---

### Step 1 — 获取变更文件列表

根据参数执行对应命令，获取**文件路径列表**（非 diff 内容）：

| 参数 | 命令 |
|---|---|
| 无参数 | `git diff HEAD --name-only` |
| commit ID | `git show --name-only --format="" <id>` |
| 文件路径 | 直接使用指定文件 |

---

### Step 2 — 智能匹配检查命令

逐一检查变更文件路径，按以下规则匹配需要运行的检查（按依赖顺序排列）：

```
checks_to_run = []

# Rule 1: Java 文件 → checkstyle（后续若 style-checks 也被触发则跳过）
if any file matches: src/**/*.java, test/**/*.java, integration-test/**/*.java
  add "ant checkstyle"

# Rule 2: FitNesse 或 集成测试 Scala → style-checks（包含 checkstyle，去重 Rule 1）
if any file matches: fitnesse/** OR integration-test-scala/**/*.scala OR integration-test/**/*.scala
  add "ant style-checks"
  remove "ant checkstyle"  ← 去重

# Rule 3: 任何 Java 文件 → static-analysis-checks（PMD + SpotBugs）
if any file matches: **/*.java
  add "ant static-analysis-checks"

# Rule 4: functional-test Scala → functional-test-checks
if any file matches: functional-test/**/*.scala
  add "ant functional-test-checks"

# Rule 5: react-apps → npm-lint
if any file matches: react-apps/**
  add "ant npm-lint"
```

---

### Step 3 — 与用户确认

输出检查计划，询问用户确认：

```
======================================
🔍 本地静态检查计划
======================================
根据改动文件，建议执行以下检查（共 N 项）：

  1. ant checkstyle           ← Java 代码风格（src/com/.../Foo.java 等 X 个文件）
  2. ant static-analysis-checks  ← PMD + SpotBugs（⚠️ 需先编译，可能较慢）
  3. ant npm-lint             ← React/TS lint（react-apps/ 下 Y 个文件）

是否执行以上检查？
- "全部"：执行所有检查
- "跳过 N"：跳过第 N 项，执行其余项（如 "跳过 2" 跳过 static-analysis-checks）
- "取消"：退出不执行
======================================
```

**等待用户回复。**

按用户回复过滤最终执行列表后，进入 Step 4。

---

### Step 4 — 逐项执行检查

对每个检查命令：

1. 在项目根目录（`build.xml` 所在目录）执行命令
2. 捕获完整输出（stdout + stderr）
3. 根据退出码判断通过 / 失败

**通过时：** 输出 `✅ [N/总数] ant <command> 通过`，继续下一项。

**失败时：** 进入 **Step 5 — 自动修复循环**。

---

### Step 5 — 自动修复循环（最多 3 次）

失败时，进入修复循环，**每个失败的检查最多重试 3 次**：

#### 修复前分析

读取失败命令的完整输出，**精确识别错误**：

- `checkstyle`：输出包含 `[WARN]` 或 `[ERROR]`，含文件路径 + 行号 + 规则名
- `style-checks`（Scalastyle）：输出包含 `error file=` 或 `warning file=`
- `style-checks`（FitNesse）：输出包含 FitNesse 文件路径和格式错误描述
- `static-analysis-checks`（PMD）：输出包含 `Rule violated:` 或文件路径 + 行号 + 规则
- `static-analysis-checks`（SpotBugs）：输出包含 bug 描述 + 类名 + 行号
- `functional-test-checks`（Scalastyle via sbt）：输出包含 `[error]` 或 `[warn]` + 文件路径
- `npm-lint`：输出包含文件路径 + 行号 + 规则名（eslint / prettier 格式）

#### 修复原则

- **最小化修改**：只修改报告指出的文件和行，不顺手重构周边代码
- **修改后不重新运行 review**：直接重新执行同一 ant 命令验证
- **不能自动修复的错误**（SpotBugs 发现的逻辑 Bug、业务不明确的 PMD 规则违反）：记录为"需手动处理"，不进行自动修改

#### 重试格式

```
❌ ant checkstyle 失败（第 1/3 次尝试）
--------------------------------------
错误分析：
  - src/com/backstopsolutions/.../Foo.java 第 42 行：变量名不符合 camelCase 规范（localVariable → localFoo）
  - src/com/backstopsolutions/.../Bar.java 第 87 行：缺少空行（method block before close brace）

正在修复 2 处错误...
✅ 已修复：src/com/.../Foo.java 第 42 行
✅ 已修复：src/com/.../Bar.java 第 87 行

重新执行 ant checkstyle...
```

若第 3 次仍失败，输出：

```
❌ ant checkstyle 在 3 次尝试后仍未通过
--------------------------------------
剩余未解决的错误：
  [完整错误列表]

⚠️  请手动检查并修复以上问题后，重新运行 /code-style-checks。
--------------------------------------
```

标记此检查为 ❌，继续执行剩余的其他检查项。

---

### Step 6 — 汇总输出

所有检查执行完毕后输出结果汇总：

**全部通过时：**

```
======================================
✅ 本地静态检查全部通过
======================================
  ✅ ant checkstyle
  ✅ ant static-analysis-checks
  ✅ ant npm-lint

代码质量已验证，可以进行下一步：

  @commit-code
======================================
```

**有检查未通过时：**

```
======================================
⚠️  部分检查未通过，需手动处理
======================================
  ✅ ant checkstyle（第 2 次尝试后通过）
  ❌ ant static-analysis-checks（3 次尝试后仍失败）
  ✅ ant npm-lint

❌ 需手动处理的检查：
  ant static-analysis-checks — 剩余错误：[简短描述]

请修复以上问题后，重新运行 /code-style-checks 或手动执行对应命令。
======================================
```

---

## 约束

- 不执行 git 操作（add / commit / push）
- 不执行与静态检查无关的命令（编译、测试、打包等）
- 自动修复只做最小化改动，不顺手重构
- `static-analysis-checks` 失败时若错误属于 SpotBugs 潜在逻辑 Bug，标记为"需手动处理"，不自动修改
