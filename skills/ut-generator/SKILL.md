---
name: ut-generator
description: "分析代码改动，评估 UT 必要性，列出测试覆盖点，与开发者确认后生成完整单元测试代码。支持 Java（JUnit 5 + Mockito）和 TypeScript/JavaScript（Jest）。Use when: 生成单元测试、generate unit tests、create UT、需要补充 UT、写测试代码"
argument-hint: "可选：commit ID、branch 范围（如 main..HEAD）、或文件路径（-- path/to/Foo.java）。不填则分析本地所有未提交改动"
---

# 单元测试生成器 (UT Generator)

分析代码改动，识别测试场景，与开发者确认覆盖点后生成完整可运行的单元测试代码。
支持 Java（JUnit 5 + Mockito）· TypeScript/JavaScript（Jest）。

---

## 触发方式

| 场景 | 调用示例 |
|---|---|
| 分析本地所有未提交改动（默认） | `/ut-generator` |
| 分析已暂存的改动 | `/ut-generator --staged` |
| 分析指定 commit | `/ut-generator abc1234` |
| 分析 branch 差异 | `/ut-generator main..HEAD` |
| 针对指定文件分析/补全 UT | `/ut-generator -- path/to/Foo.java` |

---

## 执行步骤

### Step 0 — 预检与模式判断

**在执行任何分析之前**，先解析参数、判断触发模式并做前置安全检查。

#### 0.1 触发模式识别

| 参数形式 | 模式 | 说明 |
|---|---|---|
| 无参数 | **Mode A**：本地改动 | `git diff HEAD` |
| `--staged` | **Mode A**：暂存改动 | `git diff --cached` |
| commit ID / range | **Mode A**：commit 分析 | `git show <id>` / `git diff <range>` |
| `-- path/to/Foo.java` | **Mode B**：指定文件 | 读取文件 + 检测是否有 git 改动 |

#### 0.2 空变更守卫（Mode A 适用）

**无参数时**，运行 `git diff HEAD --stat`；若输出为空，**立即停止**，不执行后续步骤，输出：

```
⚠️ 未检测到任何代码改动。

当前工作区没有未提交的变更（git diff HEAD 为空）。

你可以通过以下方式使用本 skill：

| 场景                       | 命令示例                                    |
|--------------------------|------------------------------------------|
| 分析本地所有未提交改动（默认）          | `/ut-generator`                          |
| 分析已暂存的改动                 | `/ut-generator --staged`                 |
| 分析指定 commit              | `/ut-generator abc1234`                  |
| 分析 branch 与主干的差异         | `/ut-generator main..HEAD`               |
| 针对指定 Java 文件分析/补全 UT     | `/ut-generator -- path/to/Foo.java`      |
```

**指定 commit ID 时**，运行 `git show --stat <id>`；若报错（commit 不存在），停止并提示检查 ID。

**指定 branch range 时**，运行 `git diff --stat <range>`；若为空，停止并提示该 range 内没有差异。

#### 0.3 文件模式预检（Mode B 适用）

当用户指定了文件路径（`-- path/to/Foo.java`）时：

1. 读取该文件的完整内容
2. 推断对应测试文件路径（`src/test/java/.../{ClassName}Test.java`）
3. 检查测试文件是否已存在：
   - **已存在**：读取现有测试文件，分析当前覆盖情况，后续重点提出**补全/优化建议**
   - **不存在**：对该文件内所有有业务逻辑的方法做**全量 UT 分析**
4. 同时检查该文件是否有 git 未提交的改动（`git diff HEAD -- <file>`），若有，将改动部分纳入分析重点

---

### Step 1 — 分析代码

根据触发模式获取目标代码：

| 模式 | Git 命令 |
|---|---|
| 无参数 | `git diff HEAD` |
| `--staged` | `git diff --cached` |
| commit ID | `git show <id>` |
| branch range | `git diff <range>` |
| 指定文件 | 读取文件内容 + `git diff HEAD -- <file>` |

> **若变更超过 500 行**，先运行 `git diff --stat` 获取文件摘要，优先分析改动行数最多的文件。

对每个目标文件：

1. **识别技术栈**：`.java` → JUnit 5 + Mockito；`.ts`/`.js` → Jest
2. **分析被测方法的职责**：
   - 这个方法的核心职责是什么？输入/输出是什么？
   - 依赖了哪些外部组件（数据库、HTTP、Service、事件发布等）？这些是需要 Mock 的候选
3. **按以下标准评估测试必要性**：

**必须覆盖（高价值）：**
- 新增/修改了有条件分支的业务方法
- 覆写了父类方法且新增了副作用
- 多处调用的工具方法 / 判断方法
- 涉及数据持久化、外部系统调用的方法

**不建议覆盖（低价值）：**
- 纯 getter / setter（无逻辑）
- Trivial delegate（仅转发调用，无附加逻辑）
- 前端 JSP / HTML 渲染逻辑
- 配置文件变更

4. **拆解测试场景（三类）**：
   - ✅ **Happy Path（正常路径）**：输入合法 → 期望的正常输出
   - ❌ **Error / Exception Path（异常路径）**：输入非法或外部依赖失败 → 应抛出什么异常或如何处理
   - ⚠️ **Edge Case（边界情况）**：空值、null、空集合、最大/最小值、重复数据...

---

### Step 2 — 列出覆盖点并确认

展示分析结果，等待用户确认后再生成代码。格式如下：

```
======================================
📋 UT 覆盖分析
======================================

[必须覆盖]

1. ClassA.methodX()
   职责：[一句话描述]
   外部依赖（需要 Mock）：DependencyX、DependencyY

   测试场景矩阵：
   场景                          | 输入条件          | 期望结果
   -------------------------------|------------------|---------------------------
   ✅ 正常路径：所有参数合法        | 合法 request      | 返回预期 Result，副作用发生
   ✅ 正常路径：条件 B             | flag=false        | 走另一分支，不调用 Dep
   ❌ 异常路径：request 为 null    | null              | 抛 IllegalArgumentException
   ❌ 异常路径：外部依赖失败        | Dep 抛异常        | 异常向上传递，无副作用
   ⚠️  边界条件：集合为空           | emptyList         | 返回空结果而非 NPE

2. ClassB.methodY()
   ...

[不建议覆盖]
- ClassC.getX()：纯 getter，无逻辑
- ActionBean.delegateMethod()：trivial delegate

======================================
请确认：
- 回复"全部"生成所有必须覆盖的测试
- 回复编号（如 1,2）指定要生成哪些
- 回复"跳过"不生成测试
======================================
```

**等待用户回复后，再执行 Step 3。**

---

### Step 3 — 生成完整测试代码

根据用户确认的覆盖点，**直接生成完整可运行的测试代码**，严格遵循以下规范。

#### 核心原则

- **AAA 模式**：每个测试方法严格分为 Arrange / Act / Assert 三段，注释用 `// given` / `// when` / `// then`
- **行为测试**：测试可观察的输出（返回值、抛出的异常、verify 调用），不验证内部实现细节
- **单一职责**：每个 `@Test` 方法只验证一个行为
- **避免过度 Mock**：只 Mock 外部边界（Repository、HTTP 服务、消息队列、时钟），不 Mock 简单工具类和 POJO

#### Mock 策略

```
✅ 应该 Mock 的：
   - 数据库（Repository / DAO / Manager 中涉及 DB 的方法）
   - 外部 HTTP 服务
   - 消息队列、事件发布
   - 文件系统、Clock（时间相关）

❌ 不应该 Mock 的：
   - 被测类本身的内部逻辑
   - 简单工具类（StringUtils 等）
   - 纯数据对象（POJO、DTO）
```

#### Java（JUnit 5 + Mockito）规范

```java
@ExtendWith(MockitoExtension.class)
class ClassATest {

    @Mock
    private DependencyX dependencyX;

    @Mock
    private DependencyY dependencyY;

    @InjectMocks
    private ClassA classA;

    @Test
    void shouldReturnExpectedResultWhenConditionA() {
        // given
        SomeRequest request = buildValidRequest();
        SomeEntity entity = buildEntity();
        when(dependencyX.findById(request.getId())).thenReturn(Optional.of(entity));

        // when
        SomeResult result = classA.methodX(request);

        // then
        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo(ExpectedStatus.CONFIRMED);
        verify(dependencyY).publish(any(SomeEvent.class));
    }

    @Test
    void shouldThrowIllegalArgumentExceptionWhenRequestIsNull() {
        // given / when / then
        assertThatThrownBy(() -> classA.methodX(null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("request must not be null");
    }

    @Test
    void shouldNotPublishEventWhenDependencyXFails() {
        // given
        SomeRequest request = buildValidRequest();
        when(dependencyX.findById(request.getId()))
                .thenThrow(new RuntimeException("DB error"));

        // when / then
        assertThatThrownBy(() -> classA.methodX(request))
                .isInstanceOf(RuntimeException.class);

        verify(dependencyY, never()).publish(any());
    }

    // ── 私有辅助方法 ──────────────────────────────

    private SomeRequest buildValidRequest() {
        // TODO: 构建合法请求对象
        return new SomeRequest(/* ... */);
    }

    private SomeEntity buildEntity() {
        // TODO: 构建实体对象
        return new SomeEntity(/* ... */);
    }
}
```

**Java 规范说明：**
- 测试类命名：`{被测类名}Test.java`
- 文件路径：`src/test/java/{同包路径}/{类名}Test.java`
- 方法命名：`should{预期结果}When{触发条件}()`（**驼峰命名，无下划线**）
  - ✅ `shouldReturnOrderResultWhenAllInputsAreValid()`
  - ✅ `shouldThrowIllegalArgumentExceptionWhenRequestIsNull()`
  - ✅ `shouldNotPublishEventWhenOrderSaveFails()`
  - ❌ `should_return_result_when_valid()`（下划线格式，不符合规范）
- 优先使用 AssertJ 风格断言：`assertThat()`, `assertThatThrownBy()`
- 有副作用时写明 `verify()` 调用，反向验证用 `verify(dep, never()).method())`
- 类末尾用私有辅助方法（`buildXxx()`）构建测试数据，保持测试方法简洁
- **填充完整断言代码，不写 `// TODO`（构建测试数据的辅助方法可酌情保留 `// TODO`）**

#### TypeScript/JavaScript（Jest）规范

```typescript
import { ClassA } from './ClassA';
import { DependencyX } from './DependencyX';

describe('ClassA', () => {
    let classA: ClassA;
    let mockDependencyX: jest.Mocked<DependencyX>;

    beforeEach(() => {
        mockDependencyX = {
            findById: jest.fn(),
        } as unknown as jest.Mocked<DependencyX>;
        classA = new ClassA(mockDependencyX);
    });

    describe('methodX', () => {
        it('should return expected result when condition A is met', () => {
            // given
            const request = { id: '123', userId: 'user-1' };
            mockDependencyX.findById.mockResolvedValue({ id: '123', status: 'ACTIVE' });

            // when
            const result = await classA.methodX(request);

            // then
            expect(result).toBeDefined();
            expect(result.status).toBe('CONFIRMED');
        });

        it('should throw error when request is null', () => {
            expect(() => classA.methodX(null)).toThrow('request must not be null');
        });
    });
});
```

---

### Step 4 — 输出汇总

生成完成后，输出以下汇总：

```
======================================
✅ 单元测试已生成
======================================
已创建/追加：
  📄 src/test/java/.../ClassATest.java（N 个测试方法）
  📄 src/test/java/.../ClassBTest.java（M 个测试方法）

已跳过（低价值）：
  - ClassC.getX()：纯 getter，无逻辑

--------------------------------------
设计思路说明
--------------------------------------
ClassA.methodX()：
  - 识别了 DependencyX（DB 查询）和 DependencyY（事件发布）为外部依赖，均做 Mock
  - 覆盖了 N=2 个正常路径分支：[条件A] / [条件B]
  - 覆盖了异常路径：request 为 null（IllegalArgumentException）
  - 验证了副作用约束：DB 失败时事件不应发布（verify never）
  - 采用 AAA 结构，每个 @Test 只验证一个行为

...
======================================
```

---

## UT 设计理念参考

> 以下是执行分析时应遵循的核心设计原则。

### 六步分析法

```
1. 分析被测方法的职责和边界（输入/输出/外部依赖）
        ↓
2. 列出所有测试场景（happy path + error path + edge case）
        ↓
3. 确定哪些需要 Mock（只 Mock 外部边界）
        ↓
4. 用 AAA 模式编写每个测试（Arrange / Act / Assert）
        ↓
5. 测试行为而非实现细节（可观察的输出，而非内部调用序列）
        ↓
6. 命名清晰，每个测试只验证一个行为
```

### FIRST 原则

| 原则 | 含义 |
|------|------|
| **Fast** | 运行快，毫秒级，不依赖网络/数据库 |
| **Independent** | 测试之间互不依赖，顺序无关 |
| **Repeatable** | 任何环境运行结果一致 |
| **Self-validating** | 有明确的 pass/fail，不需要人工判断 |
| **Timely** | 和代码同步写，不拖到最后 |

### 好的 UT vs 坏的 UT

```java
// ❌ 测试实现细节（脆弱，重构就挂）
verify(orderService, times(1)).buildOrder(request);
verify(orderService, times(1)).validateInternal(request);

// ✅ 测试可观察的行为（健壮，重构不影响）
assertThat(result.getStatus()).isEqualTo(OrderStatus.CONFIRMED);
verify(eventPublisher).publish(any(OrderCreatedEvent.class));
```

```java
// ❌ 过度 Mock，测试验证的是 Mock 本身
when(stringUtils.isEmpty(any())).thenReturn(false);
when(order.getId()).thenReturn("123");
assertThat(result).isNotNull(); // 无意义

// ✅ 只 Mock 外部边界，断言有意义的值
when(orderRepository.save(any())).thenReturn(savedOrder);
assertThat(result.getOrderId()).isEqualTo(savedOrder.getId());
```

> **如果你发现需要大量 Mock 才能测一个方法，说明这个方法职责太多，应先重构。**

---

## 约束

- 若目标测试文件已存在，在文件末尾追加新方法，不覆盖已有测试
- 不为 trivial 代码生成测试，并明确说明原因
- 每个 `@Test` 方法只验证一个行为，不在一个方法里测多个场景
- Java 方法命名严格遵循驼峰规范，不使用下划线分隔
