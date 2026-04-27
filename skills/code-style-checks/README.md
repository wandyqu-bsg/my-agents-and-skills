# code-style-checks

代码风格检查 Copilot Skill。根据代码改动智能判断需要执行哪些检查，与开发者确认后逐项执行，失败时自动分析并尝试修复。

---

## 功能简介

| 能力 | 说明 |
|---|---|
| 智能匹配 | 根据改动文件类型，自动识别适用的检查命令，不做无关检查 |
| 用户确认 | 展示检查计划（含每项的触发文件），等待用户确认或跳过 |
| 自动修复 | 检查失败时，分析错误信息并自动修复，最多重试 3 次 |
| 汇总报告 | 全部完成后输出每项结果及修复记录 |

---

## 支持的检查命令

| 命令 | 触发文件 | 检查内容 |
|---|---|---|
| `ant checkstyle` | `src/**/*.java`, `test/**/*.java`, `integration-test/**/*.java` | Java 代码风格（命名、格式、导入）|
| `ant style-checks` | `fitnesse/**` 或 `integration-test-scala/**/*.scala` 或 `integration-test/**/*.scala` | checkstyle + FitNesse 格式 + Scalastyle（集成测试）|
| `ant static-analysis-checks` | 任何 `.java` 文件 | PMD 规则 + SpotBugs 潜在 Bug（⚠️ 需先编译）|
| `ant functional-test-checks` | `functional-test/**/*.scala` | Functional test Scalastyle（via sbt）|
| `ant npm-lint` | `react-apps/**` | React / JS / TS 代码规范 |

> `style-checks` 包含 `checkstyle`，若两者均触发，自动去重，只运行 `style-checks`。

---

## 安装

### 前提条件

- VS Code 已安装并登录 [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat)
- 项目根目录存在 `build.xml`（Ant 构建文件）

### 步骤

1. 进入本目录，运行安装脚本：

   ```bash
   cd /path/to/code-style-checks
   bash install.sh
   ```

2. **重启 VS Code**（首次安装后必须）

3. 在 Copilot Chat 中输入 `/code-style-checks` 验证安装成功

### 分发给他人

> 本目录（`code-style-checks/`）可直接整体拷贝给他人，对方运行 `bash install.sh` 即完成安装。

---

## 使用方式

| 场景 | 命令 |
|---|---|
| 检查本地所有未提交改动 | `/code-style-checks` |
| 检查指定 commit | `/code-style-checks abc1234` |
| 检查指定文件 | `/code-style-checks -- path/to/Foo.java` |

---

## 工作流

```
Step 0  空变更守卫（无改动则停止）
Step 1  获取变更文件列表（git diff --name-only）
Step 2  智能匹配检查命令（基于文件路径规则）
Step 3  展示检查计划，等待用户确认
          ↓ 用户选择：全部 / 跳过 N 项 / 取消
Step 4  逐项执行检查
          通过 → 继续下一项
          失败 → Step 5 修复循环
Step 5  自动修复循环（最多 3 次/项）
          第 1/2/3 次：分析错误 → 修复文件 → 重新执行检查
          3 次后仍失败 → 标记为需手动处理，继续其他检查
Step 6  汇总输出（全部通过 / 部分失败）
          全部通过 → 提醒执行 @commit-code
```

---

## 修复能力说明

| 检查命令 | 常见错误类型 | 自动修复能力 |
|---|---|---|
| `ant checkstyle` | 命名规范、空行、import 顺序 | ✅ 通常可自动修复 |
| `ant style-checks`（Scalastyle） | Scala 命名、空格、import | ✅ 通常可自动修复 |
| `ant style-checks`（FitNesse） | FitNesse 格式 | ✅ 通常可自动修复 |
| `ant static-analysis-checks`（PMD） | 代码质量规则违反 | ⚠️ 部分可修复 |
| `ant static-analysis-checks`（SpotBugs） | 潜在逻辑 Bug | ❌ 需手动处理（复杂逻辑）|
| `ant functional-test-checks` | Scala 风格 | ✅ 通常可自动修复 |
| `ant npm-lint` | ESLint / Prettier 规则 | ✅ 通常可自动修复 |

---

## 结构

```
code-style-checks/
├── SKILL.md      # Skill 主文件（触发逻辑、修复策略）
├── README.md     # 本文件
└── install.sh    # 安装脚本（创建 symlink 到 ~/.copilot/skills/）
```
