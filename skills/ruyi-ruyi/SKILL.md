---
name: ruyi-ruyi
description: "Review the current Ruyi session, classify durable learnings into personal preferences, cross-project knowledge, or project documentation, and propose or apply minimal memory updates after explicit confirmation. Use when: summarize Ruyi session memory, update personal preferences, update cross-project knowledge, refresh project AI docs, clean up stale knowledge, or run ruyi-ruyi."
argument-hint: "Optional: focus area, requested memory layer, or gc [--older-than N]."
user-invocable: true
disable-model-invocation: true
---

# Ruyi Memory Review

## Purpose

Use this skill manually with `/ruyi-ruyi` after a meaningful Ruyi session. It converts durable,
verified learnings into the correct memory layer without copying the whole conversation into a
single file.

This skill is proposal-first. It must not write any memory or project documentation until the user
provides the exact confirmation phrase for the relevant layer.

## Memory Layers

| Layer | Store | Suitable content | Confirmation |
|---|---|---|---|
| Personal preferences | `~/.copilot/instructions.md` | Cross-workspace communication, coding, review, security, and workflow preferences | `✅ 确认写入` or `确认写入全局记忆` |
| Cross-project knowledge | `~/.copilot/knowledge/index.md` and a topic file | Upstream/downstream relationships, shared contracts, dispatch relationships, version dependencies, cross-project debugging boundaries, durable decisions, and open questions | `✅ 确认更新 knowledge` or `确认更新 knowledge` |
| Project documentation | The owning repository's `.github/`, `docs/`, module README, or README.detail | Durable project-specific business rules, architecture, implementation navigation, test guidance, and verified operational facts | `✅ 确认更新 project docs` |
| No persistence | None | Temporary task details, one-off commands, unverified hypotheses, full logs, secrets, and conversation narration | None |

`~/.copilot/knowledge/` is a routing and synthesis layer. Repository source code and repository-owned
documentation are authoritative for implementation facts.

## Procedure

### 1. Establish the session scope

Read the current conversation available to Ruyi. Use the session store only when the current
conversation is incomplete and the active local session index is available. Do not invent missing
turns or rely on summaries without source evidence.

Identify:

- User corrections that express a reusable preference.
- Confirmed facts or decisions that apply across repositories.
- Verified project-specific facts that future maintainers need.
- Open questions that should remain explicitly unresolved.
- Temporary details that must not be persisted.

### 2. Classify evidence

For every candidate, record:

```text
Candidate:
Layer:
Target:
Proposed section:
Why it is durable:
Evidence and sources:
Confidence: Confirmed / Likely / Needs confirmation
```

Use `Confirmed` only when the conversation includes direct source, configuration, command, or user
confirmation. Use `Likely` for a reasonable but incomplete inference. Use `Needs confirmation` when
the fact or ownership is unresolved; do not write it as a confirmed rule.

### 3. Route the target

#### Personal preference

Read the complete `~/.copilot/instructions.md` before proposing or writing. Preserve its standard
six-section structure:

1. `General & Communication Style`
2. `Architecture & Code Style`
3. `Debugging & Error Handling`
4. `Code Review & Testing`
5. `Security & Credentials`
6. `Learnt User Habits (Dynamic Append)`

Perform semantic deduplication. Place a new rule under the most relevant section; use section 6 only
when it does not fit sections 1-5. Never expose the full file contents or sensitive values.

#### Cross-project knowledge

Read `~/.copilot/knowledge/index.md` first, then only the relevant topic file. Do not load the
entire knowledge directory. Preserve the topic's existing Markdown structure and update `Sources`,
`Confidence`, `Last verified`, and `Status` when a confirmed fact changes.

Store only concise cross-project context. Do not copy repository implementation details that belong
in project docs. If no topic file exists, propose a new topic file and add its route to `index.md`.

#### Project documentation

Determine the owning repository and follow its local `.github/copilot-instructions.md` navigation
rules. Put the fact in the narrowest authoritative location:

- Project-wide navigation or invariants -> `.github/copilot-instructions.md` or scoped
  `.github/instructions/*.instructions.md`.
- Business rules -> the owning `docs/` business document.
- Module architecture and code entrypoints -> module `README.md` or `README.detail.md`.
- Debugging and operational guidance -> `docs/troubleshooting.md` or a focused `docs/` document.

Do not write an app fact only to personal knowledge. If a module README needs a full refresh, use
the repository's `create-module-readme` skill after the user approves project-doc updates.

### 4. Deduplicate, route, and assess impact

Before proposing any write, perform these checks in order.

#### 4.1 Semantic deduplication

Read the complete target file or topic, then compare the candidate semantically, not just lexically.

- Same meaning and same wording: skip it; do not propose a duplicate.
- Same meaning with different or improved wording: propose `UPDATE`.
- Contradicts or supersedes an existing entry: propose `UPDATE` or `REMOVE` with the conflict stated.
- Entirely new information: propose `ADD`.

#### 4.2 Layer routing

Choose the narrowest authoritative target and never write the same fact to multiple layers:

| Content type | Target layer | Target location |
|---|---|---|
| Personal workflow, formatting, tone, or communication preference | Layer 1 | `~/.copilot/instructions.md` and the relevant section |
| Reusable knowledge spanning two or more projects | Layer 2 | `~/.copilot/knowledge/<topic>.md` |
| Project-specific rules, architecture, navigation, or business facts | Layer 3 | The owning repository's `.github/`, `docs/`, or module README |
| Ephemeral, speculative, sensitive, or source-only data with no navigation value | Layer 4 | Do not persist; inform the user when relevant |

If a fact appears to fit multiple layers, keep the implementation/business fact in the most
authoritative project source and keep only a concise cross-project pointer or relationship in Layer
2. Personal preferences never override system, developer, or repository instructions.

#### 4.3 Conflict resolution

For factual authority, use this order:

```text
System/developer instructions > repository instructions and source/docs
> cross-project knowledge > personal preferences
```

For communication preferences, apply Layer 1 only where it does not conflict with higher-priority
instructions. If a candidate would override a higher-priority rule, flag the conflict explicitly
and request confirmation before proposing the override. If it is lower-priority, write it only to
the appropriate layer and note which higher-priority source governs the conflicting context.

#### 4.4 Stability assessment for Layer 2

Every Layer 2 topic file must contain a machine-readable date in the form `Last verified: YYYY-MM-DD`
and a stability value. New or updated durable entries should record their metadata near the entry:

```markdown
Stability: high | medium | low
Last verified: YYYY-MM-DD
Sources: <paths, URLs, commits, or conversation references>
Confidence: Confirmed | Likely | Needs confirmation
```

Use these default GC review intervals:

| Stability | Meaning | Default review interval |
|---|---|---:|
| `high` | Language specifications, stable cloud behavior, stable protocols | 12 months |
| `medium` | Team architecture decisions and internal conventions | 6 months |
| `low` | Internal service contracts or third-party API shapes likely to change | 3 months |

Retain an existing stability value unless the user explicitly changes it. Missing or malformed
metadata is a cleanup finding, not permission to invent a verification date.

#### 4.5 Source and scope check

- Confirm current source paths, repository revision, configuration, and tests when the candidate is a
  technical fact.
- Mark uncertain or stale claims as `Needs confirmation`.
- Do not modify source code as part of this skill.

### 5. Generate the Memory Update Proposal

Present the exact text that would be written. Never paraphrase the `Proposed Text` field.

```markdown
## Memory Update Proposal

### 1. Personal preference
- Operation: ADD | UPDATE | REMOVE
- Layer: Personal Preference
- Target: `~/.copilot/instructions.md`
- Section: `## ...`
- Original Text: ...                 # UPDATE / REMOVE only
- Proposed Text: ...                 # ADD / UPDATE only
- Evidence: ...
- Confidence: Confirmed | Likely | Needs confirmation
- Confirmation required: `✅ 确认写入`

### 2. Cross-project knowledge
- Operation: ADD | UPDATE | REMOVE
- Layer: Cross-project Knowledge
- Target: `~/.copilot/knowledge/<topic>.md`
- Section / Topic: `## ...`
- Original Text: ...                 # UPDATE / REMOVE only
- Proposed Text: ...                 # ADD / UPDATE only
- Stability: high | medium | low
- Last verified: YYYY-MM-DD
- Sources: ...
- Evidence: ...
- Confidence: Confirmed | Likely | Needs confirmation
- Confirmation required: `✅ 确认更新 knowledge`

### 3. Project documentation
- Operation: ADD | UPDATE | REMOVE
- Layer: Project Documentation
- Target: `<repository-relative path>`
- Section: `...`
- Original Text: ...                 # UPDATE / REMOVE only
- Proposed Text: ...                 # ADD / UPDATE only
- Sources: ...
- Evidence: ...
- Confidence: Confirmed | Likely | Needs confirmation
- Confirmation required: `✅ 确认更新 project docs`

### Not persisted
- ...
```

For `UPDATE`, always show both `Original Text` and `Proposed Text`. For `REMOVE`, propose moving the
entry to an `## Archived` section with its original text and deprecation reason; hard deletion is
not the default. Omit empty categories. If nothing passes relevance and deduplication checks, say:
`No memory update needed for this session.` and stop.

### 5.1 GC mode: `/ruyi-ruyi gc`

When invoked with `gc`, scan every topic file under `~/.copilot/knowledge/` except `index.md`.
When invoked with `gc --older-than N`, use a fixed `N`-month threshold; otherwise use the entry's
stability interval. Report stale, missing-metadata, malformed-date, and orphaned-index entries.

Produce a cleanup proposal without writing:

```markdown
## Knowledge Cleanup Proposal

| # | Topic file | Entry | Last verified | Stability | Issue | Suggested action |
|---:|---|---|---|---|---|---|
| 1 | `payment-gateway.md` | v1 REST contract | 2025-11-03 | low | service deprecated | REMOVE |
| 2 | `auth-flow.md` | OAuth2 PKCE flow | 2026-07-20 | high | current | KEEP |

Confirmation required: `✅ 确认清理`
```

`REMOVE` moves the exact entry to `## Archived` at the bottom of its topic file with the cleanup
date and reason. `KEEP` entries are not rewritten unless their metadata is missing or malformed.
GC must not infer that an old entry is invalid solely from age; it should recommend `Needs
confirmation` when source status cannot be verified.

### 6. Await confirmation and write

Write only the layer whose exact confirmation phrase appears in the user's next reply. A generic
`yes`, `ok`, `同意`, or `写入` is not confirmation. If multiple layers are proposed, each requires
its own phrase. `✅ 确认清理` applies only to the immediately preceding GC proposal.

#### 6.1 Anchor to the prior proposal

Retrieve the exact candidate text from the immediately preceding proposal. Do not regenerate,
paraphrase, or reconstruct it. If the proposal cannot be located in the current context, respond:

> ⚠️ 我无法在当前上下文中定位先前的提案内容。请重新执行 `/ruyi-ruyi` 以生成新的提案。

Never write content that was not explicitly shown in a prior proposal.

#### 6.2 Write execution

Before writing:

1. Re-read the current target file and verify its structure.
2. Re-check source paths, semantic duplication, and the proposed operation.
3. Abort if the target is missing, corrupted, or materially changed; generate a new proposal instead.
4. Apply the smallest Markdown-only change.
5. Preserve headings, ordering, links, and unrelated content.
6. For Layer 2, update `Last verified: YYYY-MM-DD` and retain/update `Stability` as applicable.

Apply operations as follows:

- `ADD`: insert the exact proposed text in the selected section.
- `UPDATE`: replace the exact `Original Text` with the exact `Proposed Text`.
- `REMOVE`: move the exact entry to `## Archived`, unless the user explicitly requests hard deletion
  in the confirmation response.

After writing, report the target, section, operation, sources, confidence, and verification date.
Do not create a commit or push changes.

#### 6.3 Prohibitions

- Do not modify source code files as part of this skill.
- Do not create a git commit or push changes.
- Do not write to more than one layer per confirmation phrase.
- Do not persist secrets, tokens, credentials, or PII.
- Do not persist unverified hypotheses as confirmed facts.

## Completion Checklist

- [ ] Current session evidence was separated from durable knowledge.
- [ ] Each candidate has one memory layer and one target.
- [ ] Repository source/docs remain authoritative for project facts.
- [ ] Existing target content was read and semantically deduplicated.
- [ ] No write occurred without the exact layer confirmation.
- [ ] No secrets, full logs, or temporary conversation details were persisted.
