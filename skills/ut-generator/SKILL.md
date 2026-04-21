---
name: ut-generator
description: "分析代码改动，评估 UT 必要性，列出测试覆盖点，与开发者确认后生成单元测试骨架代码。支持 Java（JUnit 5 + Mockito）和 TypeScript/JavaScript（Jest）。Use when: 生成单元测试、generate unit tests、create UT、需要补充 UT、写测试代码"
argument-hint: "可选：指定要生成测试的文件路径，默认分析所有改动"
---

# 单元测试生成器 (UT Generator)

分析代码改动，评估测试必要性，与开发者确认后生成单元测试骨架代码。

---

## 执行步骤

### Step 1 — 分析改动

获取变更集（`git diff HEAD`），对每个有业务逻辑改动的文件：

1. 读取改动文件的完整内容（重点是改动的方法/函数）
2. 识别技术栈（`.java` → JUnit 5 + Mockito，`.ts`/`.js` → Jest）
3. 按以下标准评估测试必要性：

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

### Step 2 — 列出覆盖点并确认

展示分析结果，格式如下：

```
======================================
📋 UT 覆盖分析
======================================

[必须覆盖]
1. ClassA.methodX()
   测试场景：
   ✅ 正常路径：条件 A 时返回预期结果
   ✅ 正常路径：条件 B 时触发副作用
   ⚠️  边界条件：参数为 null 时的行为
   ❌ 异常路径：依赖服务失败时的处理

2. ClassB.methodY()
   测试场景：
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

**等待用户回复。**

### Step 3 — 生成测试骨架

根据用户确认的覆盖点生成测试骨架。

#### Java（JUnit 5 + Mockito）规范

```java
class ClassATest {

    @Mock
    private DependencyX dependencyX;  // 列出所有需要 mock 的依赖

    @InjectMocks
    private ClassA classA;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void should_returnExpectedResult_when_conditionA() {
        // given
        // TODO: 设置 mock 返回值

        // when
        // TODO: 调用被测方法

        // then
        // TODO: 验证返回值 / 副作用
    }

    @Test
    void should_triggerSideEffect_when_conditionB() {
        // given
        // when
        // then
        verify(dependencyX).someMethod(/* expected args */);
    }
}
```

**规范说明：**
- 测试类命名：`{被测类名}Test.java`
- 文件路径：`src/test/java/{同包路径}/{类名}Test.java`
- 方法命名：`should_{预期结果}_when_{触发条件}`（英文，下划线分隔）
- 只生成骨架，`// given / when / then` 区块内写 `// TODO` 注释，不填完整断言
- 每个 `@Test` 方法只测试一个行为
- 有 mock 依赖时写明 `verify()` 调用或断言方向

#### TypeScript/JavaScript（Jest）规范

```typescript
import { ClassA } from './ClassA';

describe('ClassA', () => {
    let classA: ClassA;
    let mockDependency: jest.Mocked<DependencyX>;

    beforeEach(() => {
        mockDependency = { someMethod: jest.fn() } as any;
        classA = new ClassA(mockDependency);
    });

    describe('methodX', () => {
        it('should return expected result when condition A', () => {
            // given
            // TODO

            // when
            // TODO

            // then
            // TODO
        });
    });
});
```

### Step 4 — 输出汇总

```
======================================
✅ 测试骨架已生成
======================================
已创建：
  📄 src/test/java/.../ClassATest.java（N 个测试方法）
  📄 src/test/java/.../ClassBTest.java（M 个测试方法）

已跳过（低价值）：
  - ClassC.getX()

下一步：补充 // TODO 处的具体断言实现。
======================================
```

---

## 约束

- 只生成骨架，不生成完整断言实现（避免生成看起来正确但实际错误的断言）
- 若目标测试文件已存在，在文件末尾追加新方法，不覆盖已有测试
- 不为 trivial 代码生成测试，并明确说明原因
