# Plan

## Context
- Re-audit the exact `bde3e9f` `main` baseline end to end on 2026-07-17, fix every reproducible repository-owned defect, then publish the audited delta through a reviewed PR and merge only after local and hosted gates are green.
- The previous release/open-source pass is historical evidence, not proof for this run.

## Assumptions
- The primary runtime target is the native macOS 26+ `LiteratureAtlas` app built from `project.yml`/`LiteratureAtlas.xcodeproj`; the iPad target is build-verified but not the direct-download runtime target.
- Repository-provided local fixtures and generated test data may be used. No private corpus, Apple credential, notarization upload, public release, or irreversible UI action is authorized.
- Existing external blockers (approved app icon provenance, Developer ID key authorization, notarization, legal chain of title, and owner-controlled GitHub settings) remain blockers unless current evidence disproves them.

## Constraints
- Preserve user data under `Output/`, the active Python environment, and prior release evidence.
- Use a fresh `feat/andrzej_full_audit_2026_07_17` branch; commit only intentional audit/fix files.
- Use current official documentation for Apple platform/release claims and primary project dependencies.
- Runtime claims require a freshly built `.app`, real native interaction, persistence/relaunch proof, and focused log inspection.

## Options considered
1. Re-run the previous command matrix and report parity.
2. Reconstruct the product and integration flow from source, compare it with current official documentation, run static/dynamic/security/performance checks, execute a fresh native scenario matrix, fix reproduced issues, and then harden a PR.
3. Perform a clean-room architecture rewrite before verification.

Chosen: 2 because it can reveal stale assumptions and runtime regressions while keeping fixes evidence-driven and reviewable; option 1 is too shallow and option 3 is unjustified without findings.

## Execution plan
1. Inventory repository state, targets, dependencies, generated configuration, workflows, services, tests, release scripts, and known blockers.
2. Verify current primary documentation for Swift/SwiftUI/macOS release behavior and the Python/Rust dependencies actually used.
3. Run independent static architecture, correctness, security, dead-code, configuration, and supply-chain review workstreams.
4. Establish a fresh baseline with format/lint/build/test/release-policy/SBOM/dependency checks and capture exact warnings or failures.
5. Build and launch the macOS bundle, execute the full interaction/state matrix with reversible fixtures, inspect logs/process behavior, and verify relaunch persistence.
6. Reproduce and fix each repository-owned issue with a focused failing test or deterministic proof, then rerun the parent workflow.
7. Write the July 17 audit/security reports and update durable memory only with verified stable knowledge.
8. Run the complete fresh verification matrix, inspect the full diff against `origin/main`, and obtain independent review.
9. Commit intentional changes, push the branch, open a ready PR, inspect all hosted checks and review feedback, resolve findings, merge, and verify exact local/remote `main` parity.

## Test plan
- Swift: warning-as-error package tests, release builds for macOS/iPadOS, generated-project parity, and targeted regression tests for any Swift fix.
- Python: Ruff format/check, pytest, dependency audit, deterministic script validators, and boundary/invalid-input tests for any Python fix.
- Rust: `cargo fmt --check`, strict Clippy, tests, release build, audit, and FFI header/Swift boundary inspection.
- Release/supply chain: release-policy tests, release validator with only the documented icon blocker allowed, SBOM reproduction, workflow checks, secrets/license/document-link checks where locally available.
- Runtime: bundled app launch/process proof; six-destination navigation; settings/menus/toolbars/context/help/keyboard; folder ingest cancel and authorized-fixture success; search/filter/detail/export/recovery states; resize/light-dark/reduce-motion/accessibility sanity; quit/relaunch persistence; focused crash/error/warning log scan.

## Risks and rollback
- Runtime audit mutates local app data -> use isolated fixture/output locations where supported and preserve existing `Output/`; remove only audit-created disposable data through recoverable paths.
- Official documentation or hosted CI has changed -> record the current source/version and treat incompatibilities as findings rather than weakening gates.
- Broad fixes obscure causality -> one coherent fix at a time with focused proof and reviewable commits.
- External Apple/GitHub gates cannot be completed locally -> report `blocked:external` precisely and do not claim upload/notarization/App Store approval readiness.

## Memory impact
- Record only newly verified durable commands, architecture boundaries, runtime pitfalls, or release facts; do not duplicate the task report.

## Notes / Results
- Changes: Hardened canonical paper/chunk and project persistence, asynchronous
  cancellation/publication, managed-Python execution, DuckDB/JSON/audit input
  boundaries, versioned Rust FFI, release/notary evidence, SBOM identity, source
  parsing/deduplication, analytics edge cases, and SwiftUI accessibility/state flow.
- Tests run: Focused red/green regressions are complete. The frozen tree passed
  69 Swift XCTest cases plus four bookmark tests, 39 Python tests, six Rust tests,
  strict format/lint/warning gates, dependency audits, release policy, byte-stable
  XcodeGen output, isolated E2E analytics, native six-destination interaction and
  relaunch, accessibility semantics, and fresh macOS/iPadOS Release builds.
  PR review findings for stale duplicate topic exports and main-actor checksum
  hashing have focused regressions; incremental hashing also has a cancellation-
  latency regression. All pass the complete local quality matrix.
  Replacement hosted PR gates remain.
- Tradeoffs: The local contributor build keeps explicit checkout tooling, while
  distributed targets retain the self-contained sandbox boundary. The optional
  Rust accelerator still accepts only caller-contract-valid non-null pointers;
  the new ABI symbol prevents stale dylib signature confusion. Apple signing,
  notarization, icon/legal provenance, and owner GitHub settings remain external.
