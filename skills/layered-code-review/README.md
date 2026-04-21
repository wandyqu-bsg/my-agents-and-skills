# layered-code-review

面向全栈项目的分层代码审查 Copilot Skill。

支持 Java · Scala · JavaScript · TypeScript · JSP · React，五层递进审查，中文输出。

## 包含的审查层次

| 层次 | 内容 |
|---|---|
| Layer 0 | 安全扫描（硬编码密钥、注入风险、权限绕过） |
| Layer 2 | Bug 风险（null、分支覆盖、异常处理、事务） |
| Layer 3 | 设计合理性（读取相关类、继承约定、职责边界） |
| Layer 4 | 测试覆盖评估（场景清单，不自动生成代码） |
| Layer 1 | Clean Code & PMD 规范（最后输出，优先级最低） |

## 安装

### 前提条件

- VS Code 已安装并登录 [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat)
- Git

### 步骤

1. 克隆本仓库：
   ```bash
   git clone <本仓库地址> ~/skills/team-copilot-skills
   ```

2. 进入 skill 目录，运行安装脚本：
   ```bash
   cd ~/skills/team-copilot-skills/layered-code-review
   bash install.sh
   ```

3. **重启 VS Code**（首次安装后需要重启让 Copilot 识别新 skill）

4. 在 Copilot Chat 中输入 `/` 验证：`/layered-code-review` 出现在列表中即安装成功

### 更新

安装使用 symlink，更新只需：

```bash
cd ~/skills/team-copilot-skills
git pull
```

无需重新安装。

## 使用方式

| 场景 | 命令 |
|---|---|
| 审查所有本地未提交改动 | `/layered-code-review` |
| 审查已暂存的改动 | `/layered-code-review --staged` |
| 审查指定 commit | `/layered-code-review abc1234` |
| 审查 branch 差异 | `/layered-code-review main..HEAD` |

## 仓库结构

```
layered-code-review/
├── SKILL.md                  # Skill 主文件（触发流程、报告模板）
├── install.sh                # 安装脚本
├── README.md                 # 本文件
└── references/
    ├── layer0-security.md    # 安全扫描详细规则
    ├── layer1-clean-code.md  # Clean Code & PMD 规范
    ├── layer2-bugs.md        # Bug 风险分析规则
    ├── layer3-design.md      # 设计审查策略
    └── layer4-testing.md     # 测试覆盖评估准则
```
