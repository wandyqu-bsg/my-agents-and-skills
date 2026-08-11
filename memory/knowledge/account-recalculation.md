# Account Recalculation Cross-Project Knowledge

## Scope

This topic covers the account-recalculation domain across:

- `backstop/app`: the Backstop application repository.
- `fb-aws/account-recalculation`: the AWS service repository.

This file records cross-project context and navigation. Detailed formulas, implementation flow, deployment instructions, and incident analysis remain in the canonical repository documents listed below.

## Canonical Sources

### Backstop app (`backstop/app`)

- Fund-accounting documentation index: `docs/fund-accounting/README.md`
- Business return definitions and formulas: `docs/fund-accounting/account-return-business-rules.md`
- Account recalculation request lifecycle: `docs/fund-accounting/account-recalculation/request-lifecycle.md`
- Return interceptor analysis: `docs/fund-accounting/account-recalculation/return-interceptor-analysis.md`
- Detailed SimpleReturnCalculator analysis: `docs/fund-accounting/account-return/simple-return-calculator-analysis.md`
- Allocation module navigation and lifecycle: `src/com/backstopsolutions/fundbutter/fundaccounting/allocation/README.md`
- Gen 2/3 implementation and AWS dispatch: `src/com/backstopsolutions/fundbutter/fundaccounting/allocation/newrecalc/README.md`
- Scoped navigation rules: `.github/instructions/account-recalculation.instructions.md`
- Repository-wide navigation and verification rules: `.github/copilot-instructions.md`

### AWS service (`fb-aws/account-recalculation`)

- Service purpose and local deployment: `README.md`
- Lambda performance and timeout analysis: `docs/account-recalc-lambda-optimization.md`
- Backstop submodule contract surface: `backstop/`
- AWS service repository instructions: `Needs confirmation` when the current checkout has no top-level `.github/copilot-instructions.md`.

## Shared Concepts

- Account Return calculation and account recalculation are related but distinct concerns: return metrics are calculated within recalculation flows, while request creation, scheduling, locking, routing, and execution provide the surrounding lifecycle.
- Backstop app owns the monolith-side trigger, request, scheduling, calculator routing, persistence, and domain integration behavior.
- The AWS repository owns Lambda-specific entrypoints, build/deployment, AWS runtime constraints, heartbeat/timeout behavior, and service-local operational concerns.
- The `backstop` submodule in the AWS repository is a versioned snapshot. Its source and documentation may differ from the standalone `backstop/app` checkout; verify the submodule revision before making cross-repository claims.
- Cross-repository behavior must be checked against both repositories when the question concerns request payloads, status/reason text, result persistence, timeout/retry behavior, or version compatibility.

## Query Routing

- Account Return formula or metric semantics -> Backstop app business instructions and return-calculation implementation.
- Recalculation request creation, consolidation, lock, or Gen routing -> Backstop app allocation and newrecalc modules.
- Lambda entrypoint, Gradle build, deployment, memory, timeout, heartbeat, or AWS logs -> AWS repository source and docs.
- A change that crosses the app/Lambda boundary -> read this file, then inspect both repositories and identify the canonical contract source before concluding.

## Durable Decisions

- `Needs confirmation`: Add a single versioned cross-repository API/event contract document and designate its canonical owner.
- `Needs confirmation`: Define the supported compatibility relationship between the Backstop app revision and the AWS service's `backstop` submodule revision.

## Open Questions

- Which repository is the canonical owner for the app-to-Lambda request and status contract?
- Which logs and correlation identifiers are required for end-to-end troubleshooting across the app and Lambda?
- Which runtime limits and fund-size routing thresholds are committed product behavior versus temporary operational guidance?

## Verification

- Status: Initial routing map; not a complete domain specification.
- Stability: medium.
- Confidence: Confirmed for repository boundaries and source pointers; Needs confirmation for cross-project ownership questions.
- Last verified: 2026-08-11
- Sources checked: Backstop app instructions/module docs and AWS account-recalculation README/optimization doc.
- Source roots: repository identifiers above; local checkout paths are intentionally omitted for portability.
