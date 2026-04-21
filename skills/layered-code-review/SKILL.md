---
name: layered-code-review
description: "对本地 git 改动或指定 commit 进行分层代码审查，中文输出。支持 Java/Scala/JavaScript/TypeScript/JSP/React 全栈项目。按五个层次审查（安全扫描、Bug风险、设计合理性、Clean Code规范、测试评估），结果按严重性排列。Use when: code review, 审查代码, review changelist, review commit, 代码审查, 查看改动, 提交前审查, pre-PR review, 分层review"
argument-hint: "可选: commit ID 或 branch 范围（如 main..HEAD）。不填则审查本地未提交的所有改动"
---

# 分层代码审查 (Layered Code Review)

面向全栈项目的深度代码审查工具，支持 Java · Scala · JavaScript · TypeScript · JSP · React。
五层递进审查，中文输出结构化报告，问题按严重性分级。

---

## 触发方式

| 场景 | 调用示例 |
|---|---|
| 审查本地所有未提交改动（默认） | `/layered-code-review` |
| 审查已暂存的改动 | `/layered-code-review --staged` |
| 审查指定 commit | `/layered-code-review abc1234` |
| 审查 branch 差异 | `/layered-code-review main..HEAD` |
| 审查单个文件 | `/layered-code-review -- path/to/file.java` |

---

## 执行流程

### 第一步 — 获取变更集

根据参数执行对应 git 命令：

| 参数 | 命令 |
|---|---|
| 无参数 | `git diff HEAD` |
| `--staged` | `git diff --cached` |
| commit ID（如 `abc1234`） | `git show abc1234` |
| 范围（如 `main..HEAD`） | `git diff main..HEAD` |
| 单文件（如 `-- foo.java`） | `git diff HEAD -- foo.java` |

> **若变更超过 500 行**，先运行 `git diff --stat HEAD`（或 `git show --stat`）获取文件摘要，优先审查改动行数最多、影响最广的文件。

---

### 第二步 — 识别技术栈

扫描改动文件的扩展名，按如下分类应用对应规则集：

| 文件类型 | 技术栈 | 特别关注 |
|---|---|---|
| `.java` | Java 后端 / Spring | PMD、NPE、事务、类型安全 |
| `.scala` | Scala 自动化 | 函数式风格、不可变性、Option 处理 |
| `.js` / `.jsx` | JavaScript / React | XSS、undefined、异步错误 |
| `.ts` / `.tsx` | TypeScript / React | 类型声明、null 安全、any 滥用 |
| `.jsp` | JSP 前端 | EL 表达式注入、scriptlet 安全 |
| `.properties` / `.conf` / `.yml` / `.json` | 配置文件 | 硬编码密钥、IP、localhost URL |

---

### 第三步 — 分层审查

按以下顺序**执行**五层审查（注意：**输出时 Layer 1 排最后**）：

---

#### Layer 0 — 安全扫描（最高优先级，快速扫描）
> 详细规则见 [layer0-security.md](./references/layer0-security.md)

- 配置文件中的硬编码密钥 / token / 密码
- 硬编码的 IP 地址或 localhost URL（不应提交到共享代码库）
- SQL 注入 / XSS / EL 表达式注入风险
- 权限检查被注释掉或被绕过
- 不安全的反序列化、文件路径拼接

---

#### Layer 2 — Bug 风险分析（检查逻辑覆盖与健壮性）
> 详细规则见 [layer2-bugs.md](./references/layer2-bugs.md)

- 条件分支是否完整（null/undefined、空集合、边界值）
- 关键路径的异常处理是否存在且不吞掉异常
- 类型转换是否有 `instanceof` 保护；强转后 NPE 风险
- 并发/事务边界问题（Java：`@Transactional` 遗漏、多线程共享状态）
- Scala：`Option` / `Either` 未 match 完整

---

#### Layer 3 — 设计与架构合理性（需读取相关类）
> 详细规则见 [layer3-design.md](./references/layer3-design.md)

**读取关联上下文（按优先级）：**
1. 改动类的**父类 / 实现的接口**
2. **调用了改动方法的类**（谁在使用我改的代码）
3. 同 package 下的**同级类**（用于风格对比）

审查要点：
- 改动模式是否与项目现有风格一致（继承体系、命名约定、事务方式）
- 改动范围是否合理（职责过重 / 改动面过广 / 耦合不必要的类）
- default 方法、接口扩展方式是否符合项目惯例
- 前端：组件结构、state 管理方式是否与项目其他组件一致

---

#### Layer 4 — 测试覆盖评估
> 详细规则见 [layer4-testing.md](./references/layer4-testing.md)

- 改动的行为是否已有 UT 覆盖，缺口在哪
- 给出需要覆盖的**测试场景清单**（边界条件、异常路径、正常路径）
- 评估测试价值 vs 维护代价（trivial getter/setter 不建议写测试）
- **如需生成测试骨架，调用 `/create-ut` skill**

---

#### Layer 1 — Clean Code & PMD 规范（检查但**最后输出**）
> 详细规则见 [layer1-clean-code.md](./references/layer1-clean-code.md)

- 命名规范（类名、方法名、变量名是否准确传达意图）
- 方法长度 / 圈复杂度超标
- **⚠️ 禁止**：以 `@SuppressWarnings("PMD.xxx")` 注释绕过 PMD 规则
- **⚠️ 禁止**：注释掉的死代码提交到代码库
- 重复代码、魔法数字、过度嵌套

---

### 第四步 — 输出报告

以下是**报告模板（中文）**，严格按此结构输出：

```
## 代码审查报告

### 概述
[2–4 句总体评价：整体印象、最大风险点、做得好的地方]

---

### 🔴 必须修改
（不修改会导致 bug、安全漏洞、数据问题）

[问题列表]

### 🟡 建议考虑
（有明显改进空间，需要判断是否在本次修改）

[问题列表]

### 💭 改了更好（不改影响不大）
（小优化，不修改不影响功能和维护性）

[问题列表]

---

### 📋 测试覆盖建议
[Layer 4 输出]

### 💅 代码规范（Clean Code / PMD）
[Layer 1 输出]

---

### ⬇️ 下一步行动
按优先级排列的修改清单（编号）
```

**每条问题的格式：**
```
🔴 **[类别]: [简短标题]**
`文件路径`，第 N 行：问题描述。

**原因：** 风险或影响说明。

**修改建议：** 具体改法或示例代码。
```

---

## 审查原则

1. **具体到行** — 每条意见必须有文件名和行号，不写泛泛类别
2. **解释原因** — 告诉开发者为什么这是问题，每条意见都是一次学习机会
3. **给出建议** — 发现问题的同时提供改法，"建议 X，因为 Y"
4. **肯定好的做法** — 发现清晰的模式或巧妙的实现时明确指出
5. **一次完整输出** — 不分多次，一次给出完整报告
6. **中文输出** — 所有报告内容使用中文，代码示例保留原语言
