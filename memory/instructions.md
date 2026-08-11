# Personal Engineering Instructions & User Preferences

> This file records universal engineering rules, code conventions, and explicit system preferences.
> Agents that read this file must follow these rules across all workspaces.

## 1. General & Communication Style

- 日常讨论使用中文；代码、注释、Commit、配置与配置字段必须保持英文。
- 拒绝无意义的对话客套话（如“好的，没问题”）；复杂方案优先给出“分层结论 + 置信度 + 验证方式”。

## 2. Architecture & Code Style

- **根因优先**：必须修复根因，严禁使用延长 timeout、增加 sleep 或扩大重试窗口等表面修复方式。
- **改动最小化**：优先进行局部、可回滚的修改，不要因为局部需求变动全局配置。
- **职责内聚**：后端业务规则是最终权威，UI/MCP/Agent/Skill 等层严禁弱化或重复校验业务规则。

## 3. Debugging & Error Handling

- **已知低频业务失败**：可压缩为单行结构化日志摘要。
- **未知/未预期异常**：必须保留完整堆栈信息以便诊断。
- **排障顺序**：真实现象/日志定界 -> 命令行/配置确认 -> 源码调用链 -> 最小复现/对照实验 -> 根因修复。

## 4. Code Review & Testing

- **Must Fix 标准**：必须提供用户可达缺陷、契约破坏或高置信度 Regression 的真实证据，严禁把所有建议都升格为 Must Fix。
- **测试范围**：对当前项目进行编译与窄范围 UT/Smoke 验证，升级 submodule 时严禁默认触发上游全量测试。
- **Review comment 表达**：明确说明请求的修改动作、代码问题及其后果；只有在修改非强制或影响不确定时，才使用建议或反问句。

## 5. Security & Credentials

- 严禁在输出或日志中暴露完整的 `.env` 文件、密钥、Token 或私钥。
- 类似 `BACKSTOP_TLS_VERIFY=false` 等绕过逻辑仅限本地临时诊断，绝不可作为长期方案。

## 6. Learnt User Habits (Dynamic Append)

<!-- 动态沉淀追加区：通过“✅ 确认写入”新增的规则将自动补充在此处或对应分类下。 -->
