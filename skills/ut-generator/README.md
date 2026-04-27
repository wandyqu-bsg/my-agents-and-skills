# ut-generator

分析代码改动，评估测试必要性，与开发者确认覆盖点后生成完整单元测试代码的 Copilot Skill。

支持 Java（JUnit 5 + Mockito）· TypeScript/JavaScript（Jest）。

## 核心特性

- **三种触发模式**：分析 git 改动（commit / changelist / staged）、指定文件全量分析
- **空变更守卫**：无改动时立即停止并引导用户正确使用
- **场景矩阵分析**：自动识别 happy path / error path / edge case
- **完整代码生成**：直接生成可运行的测试代码（含真实断言），不只是骨架
- **文件模式智能检测**：自动判断目标测试文件是否已存在，给出补全或新建建议
- **自动运行并修复**：生成代码后自动执行测试，失败时解析原因并修复，最多循环 3 轮直到全部通过

## 触发方式

| 场景 | 命令示例 |
|---|---|
| 分析所有本地未提交改动（默认） | `/ut-generator` |
| 分析已暂存的改动 | `/ut-generator --staged` |
| 分析指定 commit | `/ut-generator abc1234` |
| 分析 branch 差异 | `/ut-generator main..HEAD` |
| 针对指定 Java 文件分析/补全 UT | `/ut-generator -- path/to/Foo.java` |

## 安装

### 前提条件

- VS Code 已安装并登录 [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat)
- Git

### 步骤

1. 进入 skill 目录，运行安装脚本：
   ```bash
   cd path/to/team-copilot-skills/ut-generator
   bash install.sh
   ```

2. **重启 VS Code**（首次安装后需要重启让 Copilot 识别新 skill）

3. 在 Copilot Chat 中输入 `/` 验证：`/ut-generator` 出现在列表中即安装成功

### 更新

安装使用 symlink，更新只需：

```bash
cd path/to/team-copilot-skills
git pull
```

无需重新安装。

## 工作流说明

### 典型使用场景

**场景 1：完成 code review 后补充 UT**
```
1. 运行 /layered-code-review 审查代码
2. 运行 /code-review-fixer 修复问题
3. 代码没问题后，运行 /ut-generator 生成测试
```

**场景 2：对某个文件补充 UT**
```
/ut-generator -- src/main/java/com/example/OrderService.java
```
Skill 会自动检测 `OrderServiceTest.java` 是否存在：
- 已存在：分析当前测试覆盖缺口，给出补全建议
- 不存在：对整个类所有业务方法进行全量分析

**场景 3：分析一个已提交的 commit**
```
/ut-generator d3e955f
```

### 交互流程

```
Step 1: Skill 自动分析代码，识别需要测试的方法和场景
        ↓
Step 2: 展示"场景矩阵"（happy path / error / edge case），等待用户确认
        ↓（用户回复"全部" / 编号 / "跳过"）
Step 3: 直接生成完整测试代码（含真实断言）
        ↓
Step 4: 自动运行测试，失败则解析原因并修复，最多 3 轮
        ↓
Step 5: 汇总：已通过/跳过的文件、测试方法数、设计思路说明
```

### 自动运行命令

| 项目类型 | 运行命令 |
|---|---|
| Ant 项目（含 `build.xml`） | `ant compile-junit-tests run-junit-test -Dtestclass=<完整类名>` |
| Maven 项目（含 `pom.xml`） | `mvn test -Dtest=<类名> -q` |
| Gradle 项目 | `./gradlew test --tests <完整类名>` |
| TypeScript/Jest | `pnpm test -- --testPathPattern="<测试文件路径>"` |

> 3 轮修复后仍不通过的测试方法会被标注 `@Disabled("需人工排查: <原因>")` 并在汇总中说明。

## Java 测试规范

| 规范项 | 说明 |
|---|---|
| 框架 | JUnit 5 + Mockito + AssertJ |
| 类命名 | `{被测类名}Test.java` |
| 文件路径 | `src/test/java/{同包路径}/{类名}Test.java` |
| 方法命名 | `should{预期结果}When{触发条件}()`（**驼峰，无下划线**） |
| 断言风格 | `assertThat()`, `assertThatThrownBy()` |
| Mock 原则 | 只 Mock 外部边界（DB, HTTP, MQ），不 Mock 被测类内部逻辑 |
| 结构 | 每个 `@Test` 严格遵循 `// given / // when / // then` |

示例方法名：
- `shouldReturnOrderResultWhenAllInputsAreValid()`
- `shouldThrowIllegalArgumentExceptionWhenRequestIsNull()`
- `shouldNotPublishEventWhenOrderSaveFails()`

## 仓库结构

```
ut-generator/
├── SKILL.md      # Skill 主文件（执行流程、规范、设计理念）
├── install.sh    # 安装脚本
└── README.md     # 本文件
```
