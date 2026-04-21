# Layer 2 — Bug 风险分析

审查改动代码的逻辑健壮性。关注条件覆盖、异常处理、类型安全，以及并发/事务边界。

---

## Java

### Null 安全
- 方法参数未做 null 检查就直接调用 `.equals()` / `.get()` / `.size()` 等
- 返回值可能为 null，调用方未判断
- `Optional` 调用了 `.get()` 而不是 `.orElse()` / `map()`
- 集合未判空就直接 `get(0)` 或 `iterator().next()`

**注意：** 改动代码对 null 的处理与超类/接口的约定是否一致？

### 条件分支覆盖
- `if/else` 链是否覆盖了所有有意义的状态？缺少 `else` 时是否有意为之？
- `switch` / `instanceof` 链没有 `default` / `else`
- 循环中的 `continue` / `break` 是否正确
- 迭代空集合的边界：集合为空时方法是否有正确的返回值

**示例：缺少 null 路径保护**
```java
// ❌ 风险：currency 为 null 时，super.setCurrency(null) 可能有副作用
if (currency != null && currency.equals(getCurrency())) {
    return;
}
super.setCurrency(currency);
// 后续代码在 currency == null 时仍会执行 isOnshoreBalanceDrivenHedgeFundProduct()
```

### 异常处理
- `catch (Exception e)` 吞掉异常（只记了 warn 日志，没有上报或重抛）
- 关键业务操作没有任何 try/catch
- `catch` 块中的异常处理改变了正常流程但没有文档说明

### 类型转换
- `(SomeType) entity` 强转前没有 `instanceof` 检查
- `instanceof` 检查通过，但紧接着又转成了更具体的类型（双重检查不完整）

**示例：**
```java
// ❌ 未检查是否 instanceof Fund
(((Fund) entity).isOnshoreBalanceDrivenHedgeFundProduct())
// ✅ 应加：entity instanceof Fund &&
```

### 事务 / 持久化
- `@Transactional` 方法内有循环调用 DB 操作（N+1 问题）
- 事务方法中抛出了 checked exception（Spring 默认不回滚 checked exception）
- 在事务外部调用了会修改持久化状态的方法

### 并发与线程安全（重点检查清单）

**Spring Bean 实例变量：**
- Spring Bean（`@Service`、`@Component`、`@Controller`）是单例，实例变量被所有请求共享
- 非 `final`、非线程安全（如 `ArrayList`、`HashMap`）的实例变量被多线程读写 → 🔴
- `static` 可变字段尤其危险，必须使用 `AtomicXxx` 或同步块

**Spring 事务代理穿透：**
- `@Transactional` 方法被**同类内部**的其他方法直接调用（`this.doSomething()`）
- Spring AOP 基于代理，内部调用绕过代理，事务不生效 → 🔴
- 解决方案：通过注入自身引用 (`@Autowired private SomeService self`) 或抽到另一个 Bean

**ThreadLocal 泄漏：**
- `ThreadLocal.set()` 后没有在 `finally` 中调用 `remove()`
- 线程池复用线程，上一次请求残留的 ThreadLocal 值会污染下一次请求

**项目惯用模式 `ThreadCacheManager`：**
- `ThreadCacheManager.beginContext(...)` 必须与 `endContext()` 配对
- `endContext()` 必须在 `finally` 块中执行，防止异常时缓存泄漏
- **示例（正确）：**
  ```java
  ThreadCacheManager.beginContext("*");
  try {
      // 业务逻辑
  } finally {
      ThreadCacheManager.endContext();
  }
  ```

**状态切换方法：**
- 修改对象内部状态（如 `switchToNetReturn()` / `switchToGrossReturn()`）的方法调用序列
- 若中间步骤抛出异常，对象会停留在错误状态，影响后续计算 → 🟡
- 应用 `try/finally` 保证状态恢复：
  ```java
  try {
      switchToNetReturn();
      obj.put("netFees", getReturnForPeriod(period));
  } finally {
      switchToGrossReturn(); // 确保无论是否异常都恢复到 gross 模式
  }
  ```

**集合并发修改：**
- 在循环中修改被多线程共享的集合，缺少同步保护
- 懒加载单例没有 double-checked locking 或 `volatile`

---

## Scala

### Option / Either / Try 处理
- `.get` 直接解包 `Option`（应用 `getOrElse` / `fold` / `map`）
- `match` 对 `Either` / `Try` 只处理了一侧
- `Future` 没有 `.recover` / `.recoverWith` 处理失败路径

### 集合操作
- 对可能空的 `List` 调用 `.head`（用 `.headOption`）
- `foldLeft` 中没有处理空集合的初始值

---

## JavaScript / TypeScript

### Null / Undefined
- 访问深层属性没有可选链（`obj.a.b.c` 应改为 `obj?.a?.b?.c`）
- `Array.find()` 返回值直接用属性访问，没有判断 `undefined`

### 异步错误处理
- `async` 函数没有 `try/catch` 或 `.catch()`
- `Promise` 没有 `.catch()` 处理 rejection（可能触发 `UnhandledPromiseRejection`）
- `await` 调用失败后的代码仍继续执行（缺少 early return）

### 类型断言
- TypeScript 中 `as SomeType` 强制转换，但实际运行时值不保证是该类型

### 事件处理
- 表单提交处理中，某些验证函数失败时没有阻止默认行为（`e.preventDefault()`），
  或者用了 `return false` 但在 DOM 事件的 `addEventListener` 里不生效

---

## JSP / 前后端交互

### 服务端渲染的数据注入到 JS
```javascript
// ❌ 如果 selectedCurrency 包含特殊字符（如引号），会破坏 JS 语法
if (currency !== '${selectedCurrency}') { ... }
```
考虑通过 `data-*` 属性传递服务端值，避免直接嵌入 JS 字符串。

### 前端验证与后端验证双重覆盖
- 前端有弹窗确认（如 `confirm(...)`），后端是否有对应的权限二次校验？
- 前端验证可被绕过（直接发请求），关键操作的权限检查必须在服务端
