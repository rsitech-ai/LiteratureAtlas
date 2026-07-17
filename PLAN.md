# Plan

## Context
- Remediate every repository-owned defect reproduced by the 2026-07-17 end-to-end audit across the macOS/iPad app, Swift state and persistence, Python analytics, Rust FFI, release verification, CI, accessibility, and runtime behavior.
- The user authorized local fixes. Push, PR creation, merge, Apple signing/notarization, and owner-controlled GitHub or legal actions remain outside this turn's authority.

## Assumptions
- The primary user is a researcher who imports a local PDF corpus, explores a trustworthy knowledge map, and expects derived analytics to match the current canonical corpus.
- `Output/` is user data and must not be reprocessed or destructively changed; isolated tests use fixtures, while the requested live contributor-app smoke may perform its normal ignored index refresh and local navigation-event append.
- macOS 26+ is the direct-download runtime target; iPadOS 26+ must still build and retain durable security-scoped folder access.

## Constraints
- Work on `feat/andrzej_fix_full_quality_audit`; preserve unrelated/user files and commit only intentional changes.
- Use focused failing tests or deterministic reproductions before behavioral fixes.
- Preserve explicit error reporting, cancellation, sandboxing, privacy, and distributed-build boundaries.
- External release blockers remain truthful blockers rather than being weakened or bypassed.

## Options considered
1. Apply narrow symptom patches only to the views and scripts named in the audit.
2. Fix each defect at its owning boundary (input validation, persistence transaction, cancellation primitive, derived-data freshness, UI semantics, release artifact verification), then run focused and full end-to-end verification.
3. Rewrite the app architecture and analytics pipeline before re-verification.

Chosen: 2 because it removes the root causes while keeping the change reviewable; option 1 would leave equivalent hidden failure paths and option 3 is disproportionate and regression-prone.

## Execution plan
1. Freeze the audit contract, branch, task plan, file ownership, and baseline evidence.
2. Add red tests for Swift persistence/source access/cancellation/analytics boundaries and implement the smallest passing state-layer fixes.
3. Add red tests for malformed analytics input, PCA rank, kNN memory behavior, output-path coherence, and audit failure semantics; implement passing Python fixes.
4. Add red tests for Rust zero-weight connected-component topology and release artifact checks; implement passing FFI/release fixes.
5. Fix derived-data freshness, placeholder trust, accessibility labels/chart descriptions, stable SwiftUI identity, menu commands, layout/log faults, render-time filesystem work, and idle animation behavior with focused proof.
6. Pin the dependency audit and supported dependency/runtime versions in the frozen environment and CI; update only documentation that is proven stale.
7. Run focused tests, then the full Swift/Python/Rust/release/security/build matrix.
8. Build and relaunch the macOS app, exercise the scenario matrix, inspect logs and process behavior, verify iPad archive/build, and review the complete diff.
9. Update audit evidence, TODO, PLAN results, and durable repository memory; commit locally only after all repository-owned gates are green.

## Test plan
- Swift: focused XCTest/Swift Testing red-green regressions, `swift test -Xswiftc -warnings-as-errors`, macOS and iPadOS Release builds, bundle launch, UI interaction, accessibility, persistence/relaunch, cancellation, and clean logs.
- Python: focused pytest red-green regressions, Ruff format/check, full pytest, isolated analytics rebuild and topic audit, import smoke, and dependency audit.
- Rust: focused red-green FFI test, `cargo fmt --check`, strict Clippy, tests, release build, and dependency audit.
- Release/CI: release-script policy tests, release validator with only documented external blockers, entitlement/privacy-manifest fixture checks, workflow validation, and SBOM refresh.
- Performance: Release-process idle sampling and targeted chart/layout log inspection before and after fixes.

## Risks and rollback
- Broad changes could couple independent failures -> use bounded ownership and merge one green slice at a time; revert only the isolated slice if its parent workflow regresses.
- Bookmark changes could break one platform -> keep a platform-neutral store with platform-specific options and verify macOS tests plus iPad build.
- Freshness validation could hide usable analytics -> distinguish current, stale, invalid, and unavailable states and provide a rebuild/recovery action.
- Cancellation changes could alter result ordering -> retain run identity checks and add cooperative cancellation tests.
- Dependency upgrades could break macOS scientific wheels -> frozen sync plus import and full analytics tests before accepting the lock.

## Memory impact
- Record only stable commands and newly established architecture rules: derived analytics must validate against the canonical corpus; persistence publishes only after durable writes; security-scoped source access is cross-platform; release verification inspects shipped entitlement/privacy values.

## Notes / Results
- Changes: Hardened cross-platform source bookmarks, transactional state writes, cooperative cancellation, analytics identity/freshness validation, Python numerical/input/scale boundaries, Rust zero-weight topology, accessibility/layout semantics, native navigation, distribution verification, CI dependency auditing, dead-code removal, documentation, and idle rendering.
- Tests run: 83 XCTest cases (one opt-in ingest smoke skipped) plus four Swift Testing bookmark cases; 50 Python tests with Ruff and pip-audit; seven Rust tests with fmt/strict Clippy/release build/RustSec; complete release-script policy; privacy/configuration gates; YAML parse; macOS and generic iOS Release builds; live six-destination 3,919-paper runtime, stale-analytics rejection, repeated accessibility/log inspection, and idle sampling.
- Tradeoffs: Kept the ambient Universe animation at a one-second cadence, reducing measured full-corpus idle CPU from 14–18% to 1.7–2.0% while preserving motion. The first cold accessibility capture still emits three AppKit window-control geometry diagnostics; source-attributed backtraces contain no app frame, and repeat traversal is clean, so native window controls were retained.
