# Plan

## Context
- The user requested an end-to-end SwiftUI polish audit for LiteratureAtlas.
- Recent work changed the app shell and Knowledge Universe graph, so launch behavior, navigation, visual polish, animation cost, and real UI workflows need fresh evidence.
- The repo is a SwiftPM macOS/iOS package; current audit target is the macOS SwiftUI app.

## Assumptions
- "End to end" means repo-wide audit coverage across build, tests, launch, primary navigation, major workflows, visual states, logs, and performance signals.
- App Store/release-candidate readiness is not the target unless signing/notarization/release packaging is explicitly requested.
- The app may require Apple Foundation Models availability for the full UI; unavailable model state is still a valid state to audit.

## Constraints
- Do not overwrite unrelated user work.
- Keep app code changes out of scope unless a concrete blocker or high-confidence polish defect is reproduced.
- Use `swiftui-polish-auditor` plus macOS build/test routing.
- Use a project-local audit report under `docs/audits/`.
- Use the weakest truthful readiness label.

## Options considered
1. Static source audit only.
2. Build/test/launch plus source-guided feature matrix and runtime smoke.
3. Full release hardening with signing, notarization, Instruments traces, accessibility automation, and packaging.

Chosen: 2 because it matches the request, gives real evidence beyond tests, and avoids claiming release-candidate quality without release-gate work.

## Execution plan
1. Establish project baseline: git state, package shape, app target, entry point, workflow map.
2. Add/update the macOS `script/build_and_run.sh` and Codex Run action for reproducible launch.
3. Run build/test quality gates: Swift build/test plus existing Python/Rust checks where feasible.
4. Launch the app through the run script and capture screenshot/process evidence.
5. Exercise primary navigation/workflows: Ingest, Universe, Q&A, Trading, Projects, Analytics, paper detail/glossary where reachable.
6. Inspect runtime logs and process health after smoke.
7. Perform a code-first SwiftUI polish/performance scan for obvious body work, global animations, unstable identity, and blocking overlays.
8. Write `docs/audits/polish-audit-2026-06-29.md` with feature matrix, evidence, issues, and readiness label.
9. Update TODO, MEMORY if durable workflow/tooling knowledge changed, and reflection notes.

## Test plan
- `./script/build_and_run.sh --verify`
- `swift build`
- `swift test`
- Existing available lint/test checks from `MEMORY.md` where dependencies are present.
- Runtime screenshot and process check.
- Unified log sample for app process after launch/smoke.

## Risks and rollback
- Risk: Foundation Models unavailable blocks full UI smoke.
  - Rollback: classify full workflow smoke as blocked and audit unsupported state honestly.
- Risk: UI automation cannot reliably click native SwiftUI controls by coordinates.
  - Rollback: use screenshots, Accessibility metadata, process/log evidence, and code-backed workflow matrix without overstating verification.
- Risk: run script launch semantics differ from `swift run`.
  - Rollback: compare with direct `swift run` only for diagnosis, keeping the script as the canonical app-bundle path.

## Memory impact
- Record the new canonical run script and audit report location if verified.

## Notes / Results
- Changes: added the reproducible macOS app-bundle run script and Codex Run action; fixed bundle-launched data loading by routing repo-relative paths through `AppPaths`; made the Knowledge Universe inspector scrollable; stripped visible markdown bold markers from cluster labels with `DisplayText`; reduced always-on Universe animation cadence; replaced an unavailable SF Symbol with standard folder symbols; wrote the audit report at `docs/audits/polish-audit-2026-06-29.md`.
- Tests run: `./script/build_and_run.sh --verify` passed; `swift test` passed with 51 tests and 1 existing opt-in ingestion smoke skipped; `.venv/bin/python -m ruff check analytics/` passed; `.venv/bin/python -m pytest analytics/tests -v` passed with 9 tests; `cargo test --manifest-path analytics/ffi/Cargo.toml` passed with 3 tests.
- Tradeoffs: full native tab-walk UI automation was not completed because the available tooling was simulator-oriented or produced a shallow AX tree; import/export and expensive write actions were source-reviewed but not executed; debug Universe still shows about 25% CPU after launch and needs Release/Instruments follow-up before any release-quality performance claim.
