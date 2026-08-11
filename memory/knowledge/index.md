# Personal Cross-Project Knowledge Index

> This directory stores concise, cross-project context for Ruyi. It is a routing and synthesis layer, not a replacement for repository documentation or source code.

## Topics

| Topic | Knowledge file | Use when | Stability | Last verified | Canonical sources |
|---|---|---|---|---|---|
| Account recalculation | [`account-recalculation.md`](account-recalculation.md) | Cross-project impact, app/Lambda dispatch, shared contracts, version compatibility, or cross-project debugging | medium | 2026-08-11 | Backstop app and `fb-aws/account-recalculation` docs and source |

## Repository Identifiers

Use these stable repository identifiers instead of machine-specific checkout paths:

- `backstop/app`: Backstop application repository.
- `fb-aws/account-recalculation`: AWS account-recalculation service repository.

The local checkout root may differ on every computer. Resolve it from the current workspace, repository metadata, or the topic's canonical source pointers before making technical claims.

## Retrieval Rules

1. Read this index first only when a request may involve cross-project context or ownership is unclear.
2. Read the matching knowledge file only for cross-project impact, shared contracts, version relationships,
   cross-project debugging boundaries, or dispatch relationships.
3. For a clearly repository-local question, follow the repository's own instructions and documentation
   without loading the topic file.
4. Treat repository source code and repository-owned documentation as authoritative for implementation facts.
5. Use this directory for cross-project relationships, stable decisions, verified invariants, and pointers to canonical sources.
6. Mark uncertain or stale information as `Needs confirmation` instead of presenting it as fact.

## Maintenance Rules

- Add a knowledge entry only when it is durable and useful across multiple conversations or projects.
- Do not copy long business explanations, source code, full incident logs, or repository documentation into this directory.
- Each durable entry should include scope, status, confidence, sources, and last-verified date.
- Repository-specific details belong in the owning repository's `.github/`, `docs/`, or module README files.
- Cross-repository contracts and decisions may be summarized here, with one canonical owner identified for each item.
- Never store credentials, tokens, private keys, full payloads, or full logs.
