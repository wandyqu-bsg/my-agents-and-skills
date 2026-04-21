---
name: layered-code-review
description: "对本地 git 改动或指定 commit 进行分层代码审查，中文输出。支持 Java/Scala/JavaScript/TypeScript/JSP/React 全栈项目。按六个层次审查（安全扫描、Bug风险、并发安全、设计合理性、Clean Code规范、性能扫描），结果按严重性排列。Use when: code review, 审查代码, review changelist, review commit, 代码审查, 查看改动, 提交前审查, pre-PR review, 分层review"
argument-hint: "可选: commit ID 或 branch 范围（如 main..HEAD）。不填则审查本地未提交的所有改动"
---

# 分层代码审查 (Layered Code Review)

面向全栈项目的深度代码审查工具，支持 Java · Scala · JavaScript · TypeScript · JSP · React。
六层递进审查，中文输出结构化报告，问题按严重性分级。

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

### 第零步 — 预检与上下文建立

#### 0.1 空变更集检测（前置守卫）

**在执行任何审查之前**，先根据参数判断是否存在可审查的内容：

- **无参数时：** 运行 `git diff HEAD --stat`，若输出为空，**立即停止**，输出以下提示并不再执行后续步骤：

  ```
  ⚠️ 未检测到任何代码改动。

  当前工作区没有未提交的变更（git diff HEAD 为空）。

  你可以通过以下方式使用本 skill：

  | 场景                   | 命令示例                              |
  |----------------------|-----------------------------------|
  | 审查本地所有未提交改动（默认）      | `/layered-code-review`            |
  | 审查已暂存的改动             | `/layered-code-review --staged`   |
  | 审查指定 commit          | `/layered-code-review abc1234`    |
  | 审查 branch 与主干的差异     | `/layered-code-review main..HEAD` |
  | 仅审查某个文件              | `/layered-code-review -- path/to/file.java` |
  ```

- **指定 commit ID 时：** 运行 `git show --stat <id>`，若报错（commit 不存在），同样停止并提示用户检查 ID 是否正确。
- **指定 range 时：** 运行 `git diff --stat <range>`，若输出为空，停止并提示该 range 内没有差异。

#### 0.2 建立改动意图上下文

通过以下方式理解本次改动的目的，**带着预期再看代码**，避免将合理的设计决策误判为问题：

**场景一：无参数（本地 diff，开发者自查）**

无 commit message 可读，从代码本身推断意图：
- 扫描改动的文件名和 package，判断属于哪个功能模块
- 观察新增/删除的类、方法、配置，总结改动的主要动作

在报告"概述"开头输出一段推断结论，供开发者确认：
> *"本次改动推断意图：[对改动的一句话总结]"*

**场景二：指定 commit ID 或 range（TL 审查）**

先运行 `git log --format="%s%n%b" <id 或 range>` 读取 commit message：
- 如果 message 充分（> 20 字），以此为上下文基础
- 如果 message 过于简短或仅有 Ticket 号，补充从代码变更推断的意图
- 将 Ticket 号（如 `FB-12345`）记录在报告中，方便对照需求

---

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

### 第二步 — 识别技术栈与改动范围合理性

#### 2.1 识别技术栈

扫描改动文件的扩展名，按如下分类应用对应规则集：

| 文件类型 | 技术栈 | 特别关注 |
|---|---|---|
| `.java` | Java 后端 / Spring | PMD、NPE、事务、类型安全 |
| `.scala` | Scala 自动化 | 函数式风格、不可变性、Option 处理 |
| `.js` / `.jsx` | JavaScript / React | XSS、undefined、异步错误 |
| `.ts` / `.tsx` | TypeScript / React | 类型声明、null 安全、any 滥用 |
| `.jsp` | JSP 前端 | EL 表达式注入、scriptlet 安全 |
| `.properties` / `.conf` / `.yml` / `.json` | 配置文件 | 硬编码密钥、IP、localhost URL |

#### 2.2 改动范围合理性评估

在进入逐层审查前，先在宏观层面判断改动边界：

- **单一职责**：这次改动是否只做一件事？若同时涉及 UI 渲染逻辑、业务计算和 API 响应格式，记录在报告概述中，提示考虑拆分。
- **遗漏文件检测**：新增/修改了业务逻辑，是否有对应的测试文件改动？配置变更是否同步更新了文档或示例？
- **架构越界**：改动是否出现跨层访问（如 Controller 直接操作数据库，JSP 内嵌大量业务逻辑）？
- **影响范围**：改动的类/方法是否被多处调用？是否需要通知其他模块的负责人？

> 若发现明显问题，在报告"概述"中用一句话指出，不需要单独列为 🔴 问题（除非确实是架构违规）。

---

### 第三步 — 分层审查

按以下顺序**执行**六层审查（注意：**输出时 Layer 1 排最后**）：

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

**逻辑正确性：**
- 条件分支是否完整（null/undefined、空集合、边界值）
- 关键路径的异常处理是否存在且不吞掉异常
- 类型转换是否有 `instanceof` 保护；强转后 NPE 风险
- Scala：`Option` / `Either` 未 match 完整

**并发与事务安全（重点检查清单）：**
- Java Spring Bean 中是否存在**可变实例变量**（非 `final`、非线程安全）被多线程共享
- `@Transactional` 是否遗漏；事务方法是否被**同类内部调用**（Spring AOP 代理穿透）
- `ThreadLocal` 使用后是否 `remove()`，防止线程池场景下的数据泄漏
- 项目惯用的 `ThreadCacheManager.beginContext()` 是否与对应的 `endContext()` 配对，并在 `finally` 块中执行
- 状态机 / 状态切换方法（如 `switchToNetReturn()` / `switchToGrossReturn()`）在异常路径下是否能恢复到正确状态
- 有没有在循环中修改共享集合而缺少同步保护

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

#### Layer 4 — 测试覆盖提示

简单评估改动是否需要补充测试（无需展开分析）：

- 若本次改动包含新增的业务逻辑、分支条件或对外暴露的接口，在报告中输出一行提示：
  > 📋 **测试覆盖**：本次改动建议补充单元测试。如需生成测试骨架，请执行 `/ut-generator` skill 并指向本次改动文件。
- 若改动仅涉及配置、样式、JSP 文本等无需 UT 的内容，跳过此提示。

---

#### Layer 5 — 性能与可扩展性扫描
> 详细规则见 [layer5-performance.md](./references/layer5-performance.md)

> 不追求极致性能，只识别**明显的性能陷阱**。

**Java / Scala 重点检查：**
- **N+1 查询**：`for` 循环 / `stream()` 内是否调用了数据库查询方法（Repository、Manager、DAO 方法）？应改为批量查询
- **大数据量无保护**：查询结果直接 `.toList()` 、`findAll()` 等，没有分页或 limit 限制，当数据量增长后会打垮内存
- **重复计算**：同一个代价较高的计算（如权限校验、数据库查询、外部服务调用）在同一请求生命周期内被多次调用，可以缓存到局部变量
- **流操作误用**：`.toList()` 后立即再次 `.stream()` 遍历；对同一集合多次全量迭代（应合并为一次）
- **不必要的序列化/反序列化**：在循环中反复 JSON 序列化同一对象

**JavaScript / TypeScript 重点检查：**
- 渲染循环中有同步的昂贵操作（DOM 查询、大数组 filter/map 嵌套）
- 未防抖的事件监听器（scroll、resize、input）

> 若发现性能问题，按严重程度归入 🔴 / 🟡，在问题描述中注明"**性能**"类别。

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

### 📋 测试覆盖
[Layer 4 输出：若需要，输出一行引导提示；否则跳过此节]

### 💅 代码规范（Clean Code / PMD）
[Layer 1 输出]

---

### ⬇️ 下一步行动
按优先级排列的修改清单（编号）
```

**每条问题的格式：**

🔴 必须修改（直接指出，语气清晰）：
```
🔴 **[类别]: [简短标题]**
`文件路径`，第 N 行：问题描述。

**原因：** 风险或影响说明。

**修改建议：** 具体改法或示例代码。
```

🟡 建议考虑 / 💭 改了更好（确认意图 + 开放式建议，语气协作）：
```
🟡 **[类别]: [简短标题]**
`文件路径`，第 N 行：我理解这里的意图是 [X]，这样写在 [Y 场景] 下可能会有 [Z 问题]。

**建议：** 可以考虑 [具体改法]，这样 [带来的好处]。你觉得这个方向合适吗？
```

---

## 审查原则

1. **具体到行** — 每条意见必须有文件名和行号，不写泛泛类别
2. **解释原因** — 告诉开发者为什么这是问题，每条意见都是一次学习机会
3. **给出建议** — 发现问题的同时提供改法，"建议 X，因为 Y"
4. **肯定好的做法** — 发现清晰的模式或巧妙的实现时明确指出
5. **一次完整输出** — 不分多次，一次给出完整报告
6. **中文输出** — 所有报告内容使用中文，代码示例保留原语言
