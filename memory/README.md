# Portable Ruyi Memory

本目录是 Ruyi 的可提交、可迁移个人记忆源。它只保存适合跨电脑恢复的 Markdown，不保存日志、缓存、会话状态、环境变量、凭据或私钥。

完整的分层架构、权威边界、检索策略和维护流程见 [`architecture.md`](architecture.md)。

## Runtime Mapping

| Repository source | Runtime destination | Purpose |
|---|---|---|
| `agents/ruyi.agent.md` | `~/.config/Code/User/prompts/ruyi.agent.md` | Active Ruyi custom agent |
| `skills/ruyi-ruyi/` | `~/.copilot/skills/ruyi-ruyi/` | Manual memory review skill |
| `memory/instructions.md` | `~/.copilot/instructions.md` | Personal engineering rules and preferences |
| `memory/knowledge/index.md` | `~/.copilot/knowledge/index.md` | Cross-project knowledge router |
| `memory/knowledge/*.md` | `~/.copilot/knowledge/*.md` | Concise cross-project topics |

The `sync-from-repo.sh` script applies this mapping after pulling the repository. The `sync-to-repo.sh` script copies changed runtime files back to this directory and stages only the files it synchronized. Neither script commits or pushes automatically.

For knowledge topics, `sync-to-repo.sh` normalizes the known Backstop checkout paths to repository identifiers. A topic that still contains an unknown machine-specific absolute path is skipped with a warning so it is not committed as non-portable knowledge.

## Memory Layers

1. **Current session**: temporary conversation context, reproduction details, hypotheses, and intermediate commands. It stays in the session and is not synchronized.
2. **Personal preferences**: reusable communication, engineering, debugging, review, testing, and security rules in `instructions.md`.
3. **Cross-project knowledge**: durable ownership, dispatch, contract, version, debugging-boundary, and decision summaries in `knowledge/`.
4. **Project knowledge**: repository-local source, tests, README files, `.github/`, and `docs/`. This repository remains authoritative for its own implementation facts.

## Update Protocol

- Ruyi only proposes durable memory changes after evidence and semantic deduplication.
- Personal preference updates require the exact confirmation `✅ 确认写入` or `确认写入全局记忆`.
- Cross-project knowledge updates require the exact confirmation `✅ 确认更新 knowledge` or `确认更新 knowledge`.
- Project documentation updates require the exact confirmation `✅ 确认更新 project docs`.
- A generic `yes`, `ok`, `同意`, or `写入` is not sufficient.
- `sync-from-repo.sh` restores the committed memory source. It does not delete local memory files that are absent from the repository.

## Portability and Authority

- Knowledge topics use repository identifiers and repository-relative canonical paths where possible. Machine-specific checkout roots are not treated as durable facts.
- Source code, tests, deployment configuration, and repository-owned documentation remain authoritative over this memory layer.
- A topic must distinguish `Confirmed`, `Likely`, and `Needs confirmation` claims and include `Stability`, `Last verified`, and `Sources` metadata when it describes cross-project facts.
- Memory maintenance never creates a git commit or pushes to a remote repository.

## Deliberately Excluded

Do not place these in this directory:

- `.env` files, API keys, passwords, tokens, certificates, or private keys;
- full logs, request payloads, session transcripts, or Copilot caches;
- machine-specific runtime settings unless they are intentionally documented as portable configuration;
- temporary hypotheses or one-off command output;
- detailed implementation copied from another repository when a canonical source pointer is enough.

## Manual Workflow

After a meaningful Ruyi session, invoke `/ruyi-ruyi`. Review its exact proposal and confirm only the memory layer you intend to update. Then run:

```bash
bash scripts/sync-to-repo.sh
git diff --cached --stat
git commit -m "sync: update Ruyi memory"
git push
```

On another computer, run:

```bash
bash scripts/sync-from-repo.sh
```

Restart VS Code after restoring the agent or skill files.
