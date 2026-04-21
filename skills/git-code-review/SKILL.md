---
name: git-code-review
description: 'Read local git changelists (staged, unstaged, or a commit range) and perform a thorough code review. Use when: reviewing my changes before committing, reviewing a branch diff, reviewing staged changes, doing a pre-PR review, checking my local work, git diff review, changelist review.'
argument-hint: 'Optional: branch or commit range (e.g. main..HEAD). Defaults to staged + unstaged changes.'
---

# Git Code Review Skill

Expert code review over local git changes. Focuses on correctness, security, maintainability, and performance — not style preferences.

## When to Use

- Before committing or opening a PR
- To review staged (`git diff --cached`) or unstaged (`git diff`) changes
- To review a branch diff (`git diff main..HEAD`)
- Any time the user says "review my changes", "review my changelist", "review my diff"

## Procedure

### Step 1 — Collect the Diff

Run one of the following depending on context:

| Scenario | Command |
|---|---|
| Staged + unstaged (default) | `git diff HEAD` |
| Staged only | `git diff --cached` |
| Unstaged only | `git diff` |
| Branch vs base (argument provided) | `git diff <argument>` |
| Single file | `git diff HEAD -- <file>` |

Use the terminal to run the appropriate command. Capture the full diff output.

If the diff is large (>500 lines), also run `git diff --stat HEAD` first to get a file summary and review the most impactful files first.

### Step 2 — Understand Context

For each changed file, read enough surrounding code to understand:
- What the file/class/function is supposed to do
- Whether the change fits the existing patterns
- What tests (if any) cover this code

### Step 3 — Review Against Checklist

#### 🔴 Blockers (Must Fix)
- Security vulnerabilities (injection, XSS, auth bypass, secrets in code)
- Data loss or corruption risks
- Race conditions or deadlocks
- Breaking API/interface contracts
- Missing error handling for critical paths
- Null/undefined dereference without guard

#### 🟡 Suggestions (Should Fix)
- Missing input validation at system boundaries
- Unclear naming or confusing logic
- Missing or inadequate tests for changed behavior
- Performance issues (N+1 queries, unnecessary allocations, missing indexes)
- Code duplication that should be extracted

#### 💭 Nits (Nice to Have)
- Minor naming improvements
- Documentation gaps for non-obvious logic
- Alternative approaches worth considering

### Step 4 — Write the Review

Open with a **summary** (2–4 sentences): overall impression, biggest concern, what's good.

For each issue use this format:
```
🔴 **Category: Short Title**
File + line reference: what the problem is.

**Why:** explanation of the risk or impact.

**Suggestion:** concrete fix or alternative approach.
```

End with **next steps**: ordered list of what to fix first.

## Rules

1. **Be specific** — cite file names and line numbers, not vague categories.
2. **Explain why** — every comment teaches something.
3. **Suggest, don't demand** — "Consider X because Y".
4. **Praise good work** — call out clean patterns or clever solutions.
5. **One pass, complete feedback** — don't drip-feed comments.
6. **Skip style** — tabs vs spaces, brace placement, etc. are for linters.
