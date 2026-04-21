# Layer 5 — 性能与可扩展性扫描

> **原则：** 不追求极致性能，只识别**明显的性能陷阱**。发现问题时先估算实际影响，避免过度优化。性能问题也要**具体到行**，说明在什么数据量/并发量下会成为瓶颈。

发现的性能问题按严重程度归入 🔴 / 🟡，在问题描述中注明"**[性能]**"类别。

---

## Java / Scala

### N+1 查询（最常见、最严重）

**模式：** `for` 循环或 `stream()` 内调用了数据库查询方法（带有 `find`、`get`、`load`、`query`、`fetch` 等词语的 Repository / Manager / DAO 方法）。

**示例：**
```java
// ❌ N+1：每个 holding 都触发一次 DB 查询
for (Holding holding : holdings) {
    Account account = accountManager.findByHolding(holding); // DB call in loop
    // ...
}

// ✅ 批量查询
Map<Holding, Account> accountsByHolding = accountManager.findByHoldings(holdings);
```

**如何识别：** 看循环体内调用的方法名，若对应类是 Manager / Repository / DAO，高度可疑。

**严重性：** 🔴（数据量增长后线性劣化，生产常见 bug）

---

### 大数据量无保护

**模式：** 直接查询全量数据后在内存中处理，无分页或 limit 限制。

```java
// ❌ 如果 account 有 100 万条记录，直接打垮 JVM 堆
List<Transaction> all = transactionManager.findAll(accountId);
return all.stream().filter(...).collect(toList());

// ✅ 加分页
Page<Transaction> page = transactionManager.findAll(accountId, PageRequest.of(0, 1000));
```

**特别关注：**
- `findAll()` / `getAll()` 方法调用
- 返回 `List<T>` 的查询方法，但没有任何翻页参数
- 在 API 响应中返回无上限的集合

**严重性：** 🟡（当前数据量小时不会触发，但上线后数据增长会出问题）

---

### 同一请求内重复计算

**模式：** 同一次 HTTP 请求中，代价较高的操作被调用多次（权限检查、数据库查询、外部 API 调用、复杂计算）。

```java
// ❌ getOwner() 调用了数据库查询，被多次调用
config.put("moneyPrecision", getOwner().getMoneyPrecision().orElse(2));
config.put("percentPrecision", getOwner().getPercentagePrecision().orElse(2));
// 若 getOwner() 每次都 DB 查询，这里调用了两次

// ✅ 缓存到局部变量
Owner owner = getOwner();
config.put("moneyPrecision", owner.getMoneyPrecision().orElse(2));
config.put("percentPrecision", owner.getPercentagePrecision().orElse(2));
```

**如何判断是否重复：** 看方法是否有 `ThreadCache` / `@Cacheable` / 局部变量缓存保护。如果没有任何缓存机制，且方法名暗示有 IO（如 `find`、`load`、`fetch`），则标记。

**严重性：** 🟡

---

### 流操作误用

```java
// ❌ toList() 后立即再次 stream()（两次全量遍历）
List<Item> items = source.stream().filter(...).toList();
items.stream().map(...).collect(toList()); // 应合并为一次 stream

// ❌ 在一个集合上多次 filter/map（应合并）
List<A> a = list.stream().filter(x -> x.isA()).toList();
List<B> b = list.stream().filter(x -> x.isB()).toList();
// ✅ 用 Collectors.partitioningBy 或 groupingBy 一次遍历
```

---

### 循环内序列化/反序列化

```java
// ❌ 在 stream 里每次都序列化同一个对象
periods.stream().map(period -> {
    JSONObject shared = buildSharedConfig(); // 每次重建
    shared.put("period", period.toString());
    return shared;
})

// ✅ 把不变的部分提到循环外
JSONObject sharedConfig = buildSharedConfig();
periods.stream().map(period -> {
    JSONObject obj = (JSONObject) sharedConfig.clone();
    obj.put("period", period.toString());
    return obj;
})
```

---

## Scala

### 不必要的集合转换

```scala
// ❌ toList 后再次迭代
val ids = entities.map(_.id).toList
ids.foreach(...)  // 本可以直接 entities.map(_.id).foreach(...)

// ❌ Seq → List → Seq 多次转换
```

### Future 并行度浪费

```scala
// ❌ 顺序 await 多个独立的 Future
val a = await(futureA)
val b = await(futureB)  // 本可以并行

// ✅ 并行启动
val (a, b) = await(futureA.zip(futureB))
```

---

## JavaScript / TypeScript

### 渲染循环中的昂贵操作

```javascript
// ❌ 每次渲染都触发 DOM 查询
items.forEach(item => {
    const container = document.querySelector('.container'); // DOM query in loop
    container.appendChild(render(item));
});

// ✅ 提到循环外
const container = document.querySelector('.container');
items.forEach(item => container.appendChild(render(item)));
```

### 嵌套 filter/map 的大数组操作

```javascript
// ❌ 两次全量遍历
const filtered = items.filter(x => x.active);
const mapped = filtered.map(x => x.value);

// ✅ 用 reduce 一次完成（数据量大时有意义）
const result = items.reduce((acc, x) => {
    if (x.active) acc.push(x.value);
    return acc;
}, []);
```

### 未防抖的高频事件

```javascript
// ❌ scroll 事件不加防抖会在每帧触发
window.addEventListener('scroll', () => {
    loadMoreData(); // 可能触发网络请求
});

// ✅ debounce
window.addEventListener('scroll', debounce(() => loadMoreData(), 200));
```

---

## 常见性能问题速查

| 问题 | 关键词 / 触发点 | 严重性 |
|------|----------------|--------|
| 循环内 DB 查询（N+1） | `for` + `find*/get*/load*` | 🔴 |
| 无限制全量查询 | `findAll()` / `getAll()` 无分页参数 | 🟡 |
| 同请求重复查询 | 方法多次调用，无缓存 | 🟡 |
| `toList()` 后再 `stream()` | `.toList().stream()` | 💭 |
| 循环内 JSON 序列化 | `new JSONObject()` 在 stream/for 内 | 💭 |
| 高频事件无防抖 | `scroll`/`resize` + 网络请求 | 🟡 |
