# Layer 4 — 测试覆盖评估

> **注意：** 此文件目前由 `/ut-generator` skill 使用，用于指导生成测试骨架代码。
> `layered-code-review` skill 的 Layer 4 已精简为轻量提示，不再引用本文件。
> 如需生成单元测试，请在 layered-code-review 完成后执行 `/ut-generator`。

---

## 评估原则

测试的目的是**保护行为，而不是覆盖行**。评估时始终问：
1. 这段改动的**行为变化**是什么？
2. 如果这个行为将来被意外破坏，会有测试失败吗？
3. 这个测试的**维护代价**是否合理？（不为 getter/setter/trivial delegate 写测试）

---

## 需要 UT 覆盖的情况

### 必须覆盖（对应 🔴 / 🟡）
- 新增的业务逻辑分支（if/else、条件判断）
- 覆写了父类方法，且新增了副作用（如修改关联对象、触发持久化、触发 recalc）
- 工具方法 / 判断方法（如 `isOnshoreBalanceDrivenHedgeFundProduct()`）被多处调用
- 边界条件：null 输入、空集合、相同值（early return 是否正常）
- 异常路径：关键操作失败时的处理

### 建议覆盖（对应 🟡）
- 条件分支中某些路径目前没有 test 覆盖（用 coverage 工具确认）
- 涉及数据变更的方法（币种变更 → 关联账户更新 → 重新计算触发）

### 不建议覆盖（维护代价 > 价值）
- 纯 getter / setter（无逻辑）
- Trivial delegate（方法仅调用另一个方法，没有额外逻辑）
- 前端 JSP / HTML 渲染逻辑（改用 E2E 测试覆盖）
- 配置文件内容（属于部署验证范畴）

---

## 测试场景清单模板

对每一段需要覆盖的改动，给出如下格式的场景清单：

```
**[方法名 / 功能模块]**

✅ 正常路径：
- [ ] 场景描述（如：currency 已是目标值时，is-same-value early return，不触发账户更新）
- [ ] 场景描述（如：onshore balance-driven product，currency 变化，所有相关账户都被更新）

⚠️ 边界条件：
- [ ] currency 参数为 null 时的行为
- [ ] getFundAccounts() 返回空集合时不触发 poison

❌ 异常 / 错误路径：
- [ ] persistence 更新失败时事务是否回滚
```

---

## Java 测试要点

### 覆写方法（@Override）
- 测试父类约定（super 行为）是否仍被保持
- 测试子类新增行为的每个分支（如 `isOnshoreBalanceDrivenHedgeFundProduct` 为 true/false 两种情况）

### 涉及副作用的方法
- 使用 mock 验证副作用是否按预期调用（`verify(persistenceManager).updateEntity(account)`）
- 验证副作用在不满足条件时**不被调用**（`verifyNoMoreInteractions`）

### 权限检查
- 有 `hasRole` 检查的逻辑：测试"有权限"和"无权限"两种情况

---

## JavaScript / TypeScript 测试要点

### 工具函数（纯函数）
- 直接单元测试，覆盖正常值、边界值、类型异常

### 包含 DOM 操作的函数
- 使用 `jsdom` 或 React Testing Library 模拟 DOM 环境
- 验证事件处理结果（form submit 是否被阻止）

### 包含用户确认弹窗（`confirm()`）
- Mock `window.confirm`，分别测试用户点"确认"和"取消"两种路径

---

## Scala 测试要点

- 优先写纯函数的属性测试（ScalaCheck）
- `Future` / 异步代码用 `ScalaFutures` 或 `Await.result`
- 数据库操作用内存 DB 或 TestContainers 隔离

---

## 评估输出格式

在报告的 `📋 测试覆盖建议` 区块中，按如下结构输出：

```
### 📋 测试覆盖建议

**需要新增测试的地方：**
1. `FundEntity.setCurrency` — 覆盖以下场景：
   - same-value early return 不触发账户更新
   - non-onshore product 不触发账户更新  
   - onshore product：所有关联账户被更新，poison 被触发
   - currency 为 null 时的行为

2. `PortfolioFundCurrencyEditableTest.test` — 覆盖：
   - entity 不是 Product → 返回 true
   - entity 是 Product 且不是 onshore balance-driven → 返回 false
   - entity 是 Product 且 onshore balance-driven 且用户有 LOCAL_ADMIN → 返回 true
   - entity 是 Product 且不是 Fund 实例（防御性测试）

**已有覆盖（无需新增）：**
- `isOnshoreBalanceDrivenHedgeFundProduct` 中的 `isOnshore()` 和 `isBalanceDrivenTMVHF()` 应已有独立测试

**测试价值低，不建议覆盖：**
- `ManagePortfolioFundActionBean.isOnshoreBalanceDrivenHedgeFundProduct`（trivial delegate）
- JSP 页面的渲染逻辑
```
