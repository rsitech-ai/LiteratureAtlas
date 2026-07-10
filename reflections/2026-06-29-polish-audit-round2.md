# Reflection Entry

## Task
- **ID/Title:** SwiftUI polish audit round 2
- **Date:** 2026-06-29
- **Scope:** LiteratureAtlas macOS SwiftUI app

## Plan and Risks
- **Planned approach:** Run a fresh evidence-backed audit: build/test gates, real app launch, route/control sweep, logs, process samples, source risk scan, and an app-local report.
- **Top failure hypotheses:**
  1. Sidebar and bridge fixes solved click-through but another route/control still emits runtime warnings or blocks interaction.
  2. Debug animation CPU remains non-trivial but not stuck.
  3. Destructive or external workflows cannot be fully exercised safely and must be marked as not executed.
- **Success criteria:** Report the weakest truthful readiness label with command evidence, clicked-route evidence, log/performance state, and concrete remaining risks.

## Candidate Attempts
| Candidate | Summary | Outcome | Signals | Why selected / rejected |
|---|---|---|---|---|
| A | Static source review only | Rejected | User requested end-to-end audit | Not enough runtime evidence |
| B | Build/test/runtime safe sweep | Selected | Fits current app and avoids destructive work | Strong evidence without unsafe side effects |
| C | Release-candidate audit | Deferred | Requires Release/Instruments/signing scope | Too broad unless explicitly requested |

## Reflection
- **Failure modes observed:** Analytics emitted `Invalid frame dimension` and CoreAnimation bogus layer-size warnings; AppleScript AX title reads intermittently failed after some route clicks even while the app stayed alive.
- **Root cause:** The runtime warning was caused by unsafe chart layout geometry and filled factor exposure area charts over signed values; the AX failures were an automation reliability issue during chart-heavy/native SwiftUI transitions.
- **Fix that resolved it:** Added guarded chart plot geometry helpers, ignored non-finite measured widths, clamped hover overlay frames, and rendered factor exposure as line marks instead of filled areas.
- **What improved score/quality:** Final strict app log scan was clean; build/test gates passed; root routes verified where AX reads were reliable and partials were recorded honestly.
- **Useful command-level evidence:** `./script/build_and_run.sh --verify`, `swift test`, `.venv/bin/python -m ruff check analytics/`, `.venv/bin/python -m pytest analytics/tests -v`, `cargo test --manifest-path analytics/ffi/Cargo.toml`, strict `/usr/bin/log show` scan.
- **Branch comparison insight (if multiple attempts):** Not applicable.

## Reusable Lesson
- **Pattern that worked:** Treat Swift Charts plot frames as untrusted during layout/restoration and clamp before applying overlay frames or gesture math.
- **Pattern to avoid:** Do not use filled area charts for signed analytics series without explicit safe y domains; they can create huge paint layers.
- **Where to apply next:** Any new chart overlay or Analytics/Trading chart should use `ChartPlotGeometry.swift` helpers.

## Decision
- **Final chosen approach:** Fresh runtime-backed macOS SwiftUI polish audit.
- **Commit/rollback decision:** Keep and commit the chart/runtime hardening plus audit artifacts.
- **Next step / follow-up:** Add a native UI smoke harness for all six sidebar routes and high-risk buttons; run Release/Instruments before claiming release-candidate readiness.
