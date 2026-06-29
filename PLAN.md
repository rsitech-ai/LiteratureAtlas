# Plan

## Context
- The user requested a fresh end-to-end SwiftUI polish audit for LiteratureAtlas after the sidebar responsiveness fix.
- Current target is the macOS SwiftPM SwiftUI app launched as `dist/LiteratureAtlas.app`.
- Recent weak spots: sidebar click-through, Knowledge Universe animation/CPU, bridge analysis, Analytics warnings, native control reachability, logs, and visual consistency.

## Assumptions
- "End to end" means macOS app bundle launch, primary route navigation, representative safe control clicks, logs, performance samples, source-backed feature matrix, and broad test gates.
- Destructive, expensive, or external side-effect actions may be opened/cancelled or source-reviewed, but not executed if they mutate the corpus, launch long AI jobs, export files, or require manual file selection.
- Release-candidate performance is not claimed unless a Release/Instruments pass is completed.

## Constraints
- Do not overwrite unrelated user work.
- Keep code changes scoped to concrete audit findings.
- Use `script/build_and_run.sh` for macOS launch evidence.
- Use the weakest truthful readiness label.

## Options considered
1. Static audit only.
2. Build/test/runtime interaction audit with safe control sweep and log/performance review.
3. Full release-candidate audit with Release/Instruments, signing/notarization, and complete macOS UI automation.

Chosen: 2 because it matches the request and gives live evidence without executing unsafe side effects or claiming release readiness.

## Execution plan
1. Run build/test gates: app bundle verify, Swift tests, Python lint/tests, Rust FFI tests.
2. Launch the app and capture baseline screenshot/process/log state.
3. Click through all root sidebar routes and capture/record resulting states.
4. Exercise safe visible controls per route: segmented controls, toggles, text inputs where non-destructive, sheets/dialog cancel paths, and disabled states.
5. Inspect source for remaining high-risk SwiftUI patterns: expensive work in `body`, unstable `ForEach` identity, global overlays, and duplicate IDs.
6. Inspect runtime logs after interaction sweep.
7. Write `docs/audits/polish-audit-2026-06-29-round2.md` with commands, matrix, interaction coverage, visual/performance notes, and readiness label.
8. Update TODO, MEMORY/reflection if durable knowledge changes.

## Test plan
- `./script/build_and_run.sh --verify`
- `swift test`
- `.venv/bin/python -m ruff check analytics/`
- `.venv/bin/python -m pytest analytics/tests -v`
- `cargo test --manifest-path analytics/ffi/Cargo.toml`
- Runtime route/control sweep via the launched `.app`
- Unified log scan after the sweep

## Risks and rollback
- Risk: macOS AX/screenshot automation can lose foreground to other apps.
  - Rollback: verify by app process/window title, force `frontmost`, and record automation limitations honestly.
- Risk: expensive actions such as ingestion, rebuilding analytics, or AI generation mutate data or run too long.
  - Rollback: validate their disabled/cancel/safe paths and source-review the execution path.
- Risk: Debug performance overstates cost.
  - Rollback: report debug samples as smoke evidence only, not release performance.

## Memory impact
- Record only durable workflow or architecture findings discovered during this pass.

## Notes / Results
- Changes: added shared chart plot geometry guards, ignored non-finite width measurements, clamped chart hover overlay frames, and converted factor exposure area fills to line marks to remove oversized CoreAnimation paint layers.
- Tests run: `./script/build_and_run.sh --verify` passed; `swift build` passed; `swift test` passed with 51 tests and 1 expected opt-in ingestion smoke skipped; `.venv/bin/python -m ruff check analytics/` passed; `.venv/bin/python -m pytest analytics/tests -v` passed with 9 tests; `cargo test --manifest-path analytics/ffi/Cargo.toml` passed with 3 tests; final strict unified log scan was clean.
- Tradeoffs: route automation through AppleScript AX remains flaky for some immediate title reads, so Trading/Projects are marked partial rather than fully certified; destructive/export/rebuild/AI actions were source/visual reviewed but not executed.
