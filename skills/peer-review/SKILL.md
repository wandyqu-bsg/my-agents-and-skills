---
name: peer-review
description: "快速浅层代码复核，只运行安全扫描（Layer 0）和 Bug 风险分析（Layer 2）。用于修复代码后的快速验证，不做设计和规范审查。Use when: 快速复核、验证修复结果、quick review、浅层 review、peer review、复核代码"
argument-hint: "可选：commit ID 或文件路径，默认审查本地所有未提交改动"
---

# 快速浅层复核 (Peer Review)

修复代码后的快速验证，只扫描安全漏洞和 Bug 风险，不做设计与规范审查。

**适用场景：**
- `code-review-fixer` 执行后验证修复结果
- PR Workflow 中的中间验证节点
- 对已经过完整 review 的代码做快速二次确认

---

## 执行步骤

### Step 1 — 获取变更集

与 `layered-code-review` 相同的 diff 命令，依据参数决定：

| 参数 | 命令 |
|---|---|
| 无参数 | `git diff HEAD` |
| commit ID | `git show <id>` |
| 文件路径 | `git diff HEAD -- <path>` |

### Step 2 — 执行两层扫描

**仅执行 Layer 0 和 Layer 2，其余层跳过。**

#### Layer 0 — 安全扫描
> 规则详见 `~/.copilot/skills/layered-code-review/references/layer0-security.md`

重点：硬编码凭证、IP/localhost URL、XSS/注入风险、权限绕过。

#### Layer 2 — Bug 风险分析
> 规则详见 `~/.copilot/skills/layered-code-review/references/layer2-bugs.md`

重点：null 安全、条件分支覆盖、异常处理、类型转换安全。

### Step 3 — 输出结果

**通过时（无新问题）：**
```
======================================
✅ 复核通过
======================================
Layer 0 安全扫描：未发现问题
Layer 2 Bug 风险：未发现问题

可继续下一步。
======================================
```

**发现问题时：**
```
======================================
⚠️  复核发现问题，需处理后再继续
======================================
[按 layered-code-review 的问题格式输出，只包含 🔴 和 🟡 级别]

建议执行 /code-review-fixer 处理以上问题。
======================================
```

---

## 约束

- 只扫描 Layer 0 和 Layer 2，不输出设计建议、规范问题或测试评估
- 发现问题时不自动修复，输出清单后停止，等待后续处理
- 结果只有"通过"或"发现问题"两种状态，不输出模糊结论
