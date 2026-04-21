# Layer 0 — 安全扫描规则

最高优先级。所有 Layer 0 问题归入 **🔴 必须修改**，不做例外。

---

## 全技术栈通用

### 硬编码凭证
扫描以下模式（不区分大小写）：
- 变量名包含 `password`, `secret`, `token`, `apikey`, `api_key`, `credential`, `private_key`，且被直接赋值为字符串字面量
- 属性文件中直接写明密钥值（非 `${?ENV_VAR}` 占位形式）

**✅ 安全做法（占位符）：**
```properties
langfuse.secret.key=${?LANGFUSE_SECRET_KEY}
```
**❌ 危险做法：**
```properties
langfuse.secret.key=sk-lf-94562f2d-bffb-4cc0-a76d-aacd783b8609
```

### 硬编码 IP / localhost URL
- 代码或配置中出现具体的内网 IP（如 `192.168.x.x`, `10.x.x.x`）
- `localhost` / `127.0.0.1` 作为字面量提交到共享配置（而非通过环境变量注入）
- 调试用的测试 URL 提交进代码库（如 `host = "https://localhost:8080/backstop/"`）

---

## Java / Scala

### SQL 注入
- 使用字符串拼接构建 SQL（`"SELECT ... WHERE id = " + id`）
- 应改用 `PreparedStatement` / 框架参数绑定

### 不安全的反序列化
- 直接反序列化不受信任的输入，且没有类型白名单

### 权限绕过
- 认证/授权检查被注释掉
- 绕过现有 `hasRole` / `@Secured` 等检查的代码路径

### 路径遍历
- 使用用户输入拼接文件路径（`new File(baseDir + userInput)`）

---

## JavaScript / TypeScript / React

### XSS（跨站脚本）
- `dangerouslySetInnerHTML={{ __html: userInput }}` 直接使用用户数据
- `element.innerHTML = userInput`
- `eval(userInput)` 或 `new Function(userInput)`
- `document.write(userInput)`

### 敏感信息暴露
- 前端代码中硬编码 API key（即使是"公开" key，也不能写死在 bundle 里）
- `console.log` 输出敏感数据（密码、token、PII）

---

## JSP

### EL 表达式注入
- `${param.xxx}` 未经转义直接输出到页面（应使用 `<c:out>` 或 JSTL 转义）
- Scriptlet 中直接输出 `request.getParameter()` 到 HTML

### `<script>` 标签内嵌服务端数据（JSON 注入）
在 `<script>` 块中直接输出服务端对象到 JS 变量，是一类特殊的 XSS 风险：
```jsp
<%-- ❌ 危险：JSONObject.toString() 不转义 HTML 特殊字符 --%>
window.BSG.config = ${bean.getConfig()};

<%-- 如果 getName() 返回 "</script><script>alert(1)//"，会提前关闭 script 标签 --%>
window.BSG.name = '${bean.getName()}';
```
**修复方式：** 在服务端对 JSON 字符串做 HTML-safe 转义：
```java
// 替换危险字符，防止提前关闭 <script> 标签
return jsonObject.toString()
    .replace("<", "\\u003c")
    .replace(">", "\\u003e")
    .replace("&", "\\u0026");
```
字符串值应使用 `bs:escapeJS()` 逐字段转义，或通过 `data-*` 属性传递并在 JS 中读取。

### 不安全的 include
- `<jsp:include page="${param.page}"/>` — 用户可控的 include 路径

---

## 配置文件（.properties / .conf / .yml）

- 生产环境的密钥不应提交，应替换为 `${?ENV_VAR}` 形式
- AMQP / DB connection string 中的明文密码
- 内网服务地址作为硬编码值（应从环境变量读取，支持多环境部署）
