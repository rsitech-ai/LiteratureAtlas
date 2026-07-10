# Reflection Entry

## Task
- **ID/Title:** SwiftUI polish audit
- **Date:** 2026-06-29
- **Scope:** repo-wide

## Plan and Risks
- **Planned approach:** Run a macOS SwiftUI audit using build/test/runtime evidence, feature matrix coverage, source-level polish scan, and an app-local report.
- **Top failure hypotheses:**
  1. App launches but real UI smoke is blocked by Foundation Models availability or accessibility automation limits.
  2. Recent animated universe work remains responsive in debug but still carries avoidable runtime cost.
  3. Long-running actions or global overlays can block interaction or hide failure states.
- **Success criteria:** Produce a truthful readiness label, evidence paths, command results, and concrete issues/follow-ups without overstating unverified workflows.

## Candidate Attempts
| Candidate | Summary | Outcome | Signals | Why selected / rejected |
|---|---|---|---|---|
| A | Static source audit only | Rejected | Would miss launch/runtime regressions | Insufficient for the requested end-to-end audit |
| B | Build/test/launch plus source-guided UI smoke | Selected | Matches skill contract and repo constraints | Gives evidence without requiring release packaging |
| C | Full release-candidate audit | Deferred | Would require signing/notarization/accessibility/performance profiling scope | Too broad for the current request unless explicitly requested |

## Reflection
- **Failure modes observed:** Proper `.app` launch initially showed 0 papers/0 clusters, the Universe inspector compressed selected-cluster content, visible graph labels leaked raw markdown bold markers, and debug CPU remained elevated after animation cadence reductions.
- **Root cause:** Repo-relative data paths were derived from current working directory, which differs for bundled app launches; inspector content had a fixed panel without scrolling; generated cluster names were displayed raw; the animated Universe still performs continuous TimelineView/canvas work in debug.
- **Fix that resolved it:** Added `AppPaths` and switched `AppModel`, `PromptStore`, and Analytics folder opening to repo-root resolution; wrapped the cluster inspector in a `ScrollView`; added `DisplayText.clusterName` for visible cluster labels; reduced Universe timeline cadence.
- **What improved score/quality:** The launched bundle now displays the real corpus, the graph reads as a graph rather than a dot cloud, selected cluster details remain usable, and the audit has a reproducible run path.
- **Useful command-level evidence:** `./script/build_and_run.sh --verify`; `swift test` passed 51 tests with 1 existing opt-in smoke skipped; `.venv/bin/python -m ruff check analytics/` passed; `.venv/bin/python -m pytest analytics/tests -v` passed 9 tests; `cargo test --manifest-path analytics/ffi/Cargo.toml` passed 3 tests; `cargo test --manifest-path analytics/rust/Cargo.toml` failed because the manifest is absent.
- **Branch comparison insight (if multiple attempts):** Not applicable.

## Reusable Lesson
- **Pattern that worked:** Launch the actual `.app` bundle early in SwiftUI audits; direct SwiftPM execution can hide bundle/CWD path bugs.
- **Pattern to avoid:** Treating screenshots or passing unit tests as enough evidence for native app polish when animated surfaces and app-bundle behavior are part of the user problem.
- **Where to apply next:** Future LiteratureAtlas UI work should use `script/build_and_run.sh --verify`, screenshot the actual app bundle, sample logs/process health, and avoid new repo-relative current-directory lookups.

## Decision
- **Final chosen approach:** Evidence-backed macOS polish audit with a generated report.
- **Commit/rollback decision:** Keep the audit fixes; no rollback needed.
- **Next step / follow-up:** Run Release/Instruments profiling for Knowledge Universe and add a macOS UI smoke harness for sidebar navigation, inspector, and paper-detail flows.
