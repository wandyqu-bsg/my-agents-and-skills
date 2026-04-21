# Layer 1 — Clean Code & PMD 规范

> **注意：** Layer 1 的问题在报告中**最后输出**（`💅 代码规范` 区块），严重性通常为 💭 改了更好，除非违反了公开 API 命名约定或绕过了 PMD 规则（后者升为 🟡 建议考虑）。

---

## ⚠️ 特别禁止（升级为 🟡 建议考虑）

### 禁止用注释绕过 PMD
以下两种形式都不允许提交：
```java
@SuppressWarnings("PMD.CyclomaticComplexity")  // ❌ 不允许
@SuppressWarnings({"PMD.NcssCount", "PMD.ExcessiveMethodLength"})  // ❌
```
正确做法：重构代码让其符合规范，而不是压制警告。

### 禁止提交注释掉的死代码
```java
// fund.setOldField(value);  // ❌ 注释掉的旧代码不应提交
// TODO: remove this  // ❌ 遗留的 TODO 超过 3 个月未处理
```

---

## Java / Scala

### 命名规范
| 类型 | 规范 | 错误示例 | 正确示例 |
|---|---|---|---|
| 类名 | UpperCamelCase | `fundEntity` | `FundEntity` |
| 方法名 | lowerCamelCase，动词开头 | `Currency()` | `getCurrency()` |
| 常量 | UPPER_SNAKE_CASE | `currencyField` | `CURRENCY_FIELD` |
| 布尔方法 | `is` / `has` / `can` 前缀 | `onshore()` | `isOnshore()` |
| 泛型参数 | 单大写字母或描述性名称 | `t` | `T` 或 `TEntity` |

### 方法职责
- 方法超过 **30 行**需质疑（PMD `NcssCount`）
- 单个方法做了超过一件事（命名中含 `And` / `Or` 或注释中有多段逻辑）
- 圈复杂度超过 **10**（PMD `CyclomaticComplexity`）

### 代码可读性
- **魔法数字**：直接使用字面量数字（如 `if (type == 3)`），应提取为命名常量
- **过度嵌套**：超过 3 层 if/for 嵌套，考虑提前 return 或提取方法
- **否定逻辑**：`!isNotValid()` 这类双重否定难以理解，改写为肯定形式
- **重复代码**：同样的逻辑出现 2+ 次，考虑提取

### Scala 特有
- 避免 `var`，优先 `val`
- `Option` 应用 `map/flatMap/getOrElse` 处理，不用 `.get`（可能抛出 `NoSuchElementException`）
- `match` 表达式应覆盖所有 case（加 `case _ =>`）

---

## JavaScript / TypeScript

### 命名规范
| 类型 | 规范 |
|---|---|
| 变量/函数 | `lowerCamelCase` |
| 组件（React） | `UpperCamelCase` |
| 常量 | `UPPER_SNAKE_CASE` 或 `lowerCamelCase`（模块级常量） |
| 布尔变量 | `is` / `has` / `should` 前缀 |

### TypeScript 特有
- 避免 `any`：使用 `any` 类型相当于放弃类型检查，应定义具体类型或用 `unknown`
- 非空断言 `!` 滥用：`obj!.property` 只在确定不为 null 时使用，并加注释说明原因
- 类型声明应接近使用处，不要把所有类型堆在文件顶部

### 代码质量
- 函数超过 **20 行**需质疑（JSX 组件渲染函数超过 **50 行** 考虑拆分子组件）
- `console.log` 不应提交（调试日志）
- `var` 不应使用，改为 `let` / `const`
- `==` 改为 `===`（避免隐式类型转换）

---

## JSP

- Scriptlet（`<% %>`）中应避免复杂业务逻辑，应放到 ActionBean 或 helper 类中
- `<style>` 块应放在 `<head>` 内或通过布局组件注入，不要放在 body 中
- 内联事件处理器（`onclick="..."` 中超过 3 个函数调用）应提取为命名函数
