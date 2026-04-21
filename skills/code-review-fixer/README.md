# code-review-fixer

`layered-code-review` 报告的配套修复 skill。读取刚完成的审查报告，与开发者确认后，对可自动处理的问题逐条修复，并内置"修复安全检查"防止引入新问题。

---

## 工作流位置

```
/layered-code-review   →   /code-review-fixer   →   /peer-review
   生成审查报告               确认并逐条修复             复核修复结果
```

---

## 功能特性

- 扫描报告中的 🔴 🟡 💭 💅 四个区块，生成分优先级的可修复清单
- 自动识别"需手动处理"的问题（安全类、跨文件重构、业务逻辑不明确、删除操作）
- **修复前安全检查**：分析调用方影响、相邻逻辑风险、副作用，避免修复引入新 bug
- 复杂修改展示 diff 预览后再写入，简单修改直接写入
- 完成后汇总修复状态，引导执行 `/peer-review` 复核

---

## 安装

### 前提条件

- VS Code 已安装并登录 [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat)
- 已安装 `layered-code-review` skill（code-review-fixer 依赖其输出）

### 步骤

1. 克隆本仓库：
   ```bash
   git clone <本仓库地址> ~/skills/team-copilot-skills
   ```

2. 进入 skill 目录，运行安装脚本：
   ```bash
   cd ~/skills/team-copilot-skills/code-review-fixer
   bash install.sh
   ```

3. **重启 VS Code**（首次安装后需要重启让 Copilot 识别新 skill）

4. 在 Copilot Chat 中输入 `/` 验证：`/code-review-fixer` 出现在列表中即安装成功

### 更新

安装使用 symlink，更新只需：

```bash
cd ~/skills/team-copilot-skills
git pull
```

无需重新安装。

---

## 使用方式

### 标准流程

```
# 1. 先执行 code review（生成报告）
/layered-code-review

# 2. 确认问题后，触发修复
/code-review-fixer

# 3. 修复完成后复核
/peer-review
```

### 触发方式

| 场景 | 命令 |
|---|---|
| 修复所有报告问题 | `/code-review-fixer` |
| 只修复必须修改的问题 | `/code-review-fixer --only-critical` |

### 交互流程

1. Skill 扫描报告，列出编号清单，标注可选/必须/需手动处理
2. **你回复** 编号（如 `1,3,5`）、`"全部"`、`"跳过可选"`（只修 🔴🟡）或 `"跳过"`
3. 对复杂修改，Copilot 会展示 diff 预览，等你确认后再写入
4. 全部完成后输出汇总，引导执行 `/peer-review`

---

## 各区块处理策略

| 报告区块 | 处理方式 |
|---|---|
| 🔴 必须修改 | 自动修复（高优先级） |
| 🟡 建议考虑 | 自动修复（中优先级） |
| 💭 改了更好 | 可选修复（低优先级，可整体跳过） |
| 💅 代码规范（Clean Code / PMD） | 可选修复（最低优先级） |
| 📋 测试覆盖 | 不自动修复，引导使用 `/ut-generator` |
| 🔐 Layer 0 安全类 | 显示改法，必须人工确认后处理 |
| 跨文件设计重构 | 标注"需手动处理"，不自动执行 |

---

## 仓库结构

```
code-review-fixer/
├── SKILL.md      # Skill 主文件（触发流程、修复规则）
├── install.sh    # 安装脚本
└── README.md     # 本文件
```
