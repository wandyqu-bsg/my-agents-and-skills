# Ruyi Personal Memory Architecture

## 1. Purpose

This document defines the portable personal memory system used by the Ruyi agent. The design keeps reusable user preferences, cross-project relationships, and project-owned facts in separate authority domains so memory improves navigation without becoming an undocumented source of truth.

## 2. Components

```text
User request
    |
    v
Ruyi agent
    |-- task routing and evidence discipline
    |-- repository instruction and source verification
    |-- selective cross-project knowledge lookup
    |
    v
/ruyi-ruyi skill
    |-- inspect the mature session
    |-- classify durable candidates
    |-- deduplicate and attach evidence
    |-- propose exact updates
    |-- wait for layer-specific confirmation
    |
    +----------------------+----------------------+----------------------+
    |                      |                      |
    v                      v                      v
Personal rules       Cross-project knowledge   Project documentation
instructions.md      knowledge/index.md        owning repository
                     knowledge/<topic>.md      source/docs/tests
```

## 3. Memory Layers

### Layer 0: Current Session

Storage is the current conversation and, when available, the local Copilot session store. It contains temporary reproduction data, intermediate commands, open hypotheses, and decisions still under discussion. It is not synchronized by this repository.

### Layer 1: Personal Engineering Instructions

Repository source: `memory/instructions.md`.

Runtime destination: `~/.copilot/instructions.md`.

Store reusable cross-workspace rules about communication, architecture, debugging, review, testing, security, and workflow. Do not store application-specific facts, one-off ticket decisions, temporary failures, or unverified assumptions.

### Layer 2: Cross-Project Knowledge

Repository source: `memory/knowledge/index.md` and `memory/knowledge/<topic>.md`.

Runtime destination: `~/.copilot/knowledge/`.

Store concise relationships that span repositories or services: ownership, dispatch, shared contracts, version compatibility, cross-project diagnostics, durable decisions, and unresolved questions. The index is a router; topic files are summaries and pointers, not implementation manuals.

Each topic should expose:

- Scope and repository ownership.
- Canonical source paths.
- Query-routing rules.
- Shared concepts and contracts.
- Durable decisions and open questions.
- `Stability: high | medium | low`.
- `Last verified: YYYY-MM-DD`.
- `Sources` and `Confidence: Confirmed | Likely | Needs confirmation`.

### Layer 3: Project Knowledge

Storage remains in the owning repository's `.github/`, `docs/`, README files, source code, and tests. Project documentation and source code are authoritative for implementation behavior. Personal knowledge should contain only a concise pointer or cross-project relationship when needed.

### Layer 4: No Persistence

Never store secrets, credentials, private keys, full `.env` files, full logs, full request payloads, session transcripts, temporary commands, or unsupported hypotheses.

## 4. Retrieval Policy

Use progressive retrieval instead of loading all memory files for every request:

1. For a clearly repository-local question, read repository instructions, navigation docs, tests, and source. Skip cross-project topics unless ownership is unclear.
2. For an unclear ownership question, read `knowledge/index.md` first and use it to select a topic and repository.
3. For a cross-project question, read the relevant topic, then verify both repositories' current source, configuration, revision, and tests.
4. Treat knowledge as a routing and synthesis layer. Never use it to override repository source or higher-priority instructions.

## 5. Update Protocol

`/ruyi-ruyi` is proposal-first and manual. It must:

1. Establish the current session scope.
2. Separate durable evidence from temporary context.
3. Classify each candidate into one layer.
4. Read the complete target and deduplicate semantically.
5. Show the exact proposed text, evidence, source, confidence, and operation.
6. Wait for the exact confirmation phrase.
7. Apply the smallest Markdown-only change.
8. Report the updated target and verification metadata.

Confirmation phrases are intentionally separate:

| Layer | Confirmation |
|---|---|
| Personal instructions | `✅ 确认写入` or `确认写入全局记忆` |
| Cross-project knowledge | `✅ 确认更新 knowledge` or `确认更新 knowledge` |
| Project documentation | `✅ 确认更新 project docs` |
| Knowledge cleanup | `✅ 确认清理` |

A generic `yes`, `ok`, `同意`, or `写入` is not sufficient. One confirmation must not update multiple layers.

## 6. Authority and Conflict Resolution

For factual claims, use this order:

```text
System/developer instructions
    > repository instructions and source/docs/tests
    > cross-project knowledge
    > personal preferences
```

For communication preferences, apply personal rules only when they do not conflict with higher-priority instructions. If a memory candidate is uncertain, record `Needs confirmation` instead of upgrading it to a fact.

## 7. Portability Rules

- Use repository identifiers such as `backstop/app` and `fb-aws/account-recalculation`, not machine-specific checkout roots.
- Use repository-relative canonical paths inside topic files.
- `sync-to-repo.sh` normalizes the known Backstop checkout paths and refuses to copy a topic that still contains an unknown `/home/...`, `/Users/...`, or Windows drive absolute path.
- `sync-from-repo.sh` restores the committed source but does not delete local files absent from the repository.
- Runtime caches, logs, session state, and local settings are intentionally outside the portable source.

## 8. Lifecycle

### On a working computer

```bash
/ruyi-ruyi
bash scripts/sync-to-repo.sh
git diff --cached --stat
git commit -m "sync: update Ruyi memory"
git push
```

Review the staged diff before committing. The sync script does not commit or push.

### Project file staging convention

After a change is complete and focused validation has passed, use precise staging:

- Stage only new or modified files that are necessary for the current project task. For an intentionally deleted file, stage the deletion explicitly.
- Use exact repository-relative paths with `git add -- <path>` for new/modified files or `git add -u -- <path>` for deletions.
- Leave unrelated user changes, generated output, logs, caches, secrets, local settings, and ambiguous files unstaged.
- Report the staged paths so they are visible in the IDE's Git Local Changes/Staged Changes view. Staging does not authorize commit or push.

### On another computer

```bash
git clone git@github.com:wandyqu-bsg/my-agents-and-skills.git
cd my-agents-and-skills
chmod +x scripts/sync-from-repo.sh
bash scripts/sync-from-repo.sh
```

Restart VS Code after restoring custom agents or skills.

## 9. Maintenance

- Run `/ruyi-ruyi gc` to produce a proposal for stale or malformed Layer 2 topics.
- Age alone does not prove a topic is invalid; verify its canonical sources before cleanup.
- Keep project-specific details in the owning repository.
- Never create a commit or push as part of memory maintenance itself.
