# SwiftUI Polish Audit Report: LiteratureAtlas

## Scope

- Date: 2026-06-29
- Auditor: Codex
- Platform: macOS
- Project: repository-root SwiftPM package
- App target: SwiftPM executable product `LiteratureAtlas`
- Runtime path: `dist/LiteratureAtlas.app`
- Configuration: Debug for build/test/runtime smoke; Release performance is not claimed
- Readiness target: end-to-end polish smoke, not release-candidate packaging

Official Apple references consulted during the audit:

- https://developer.apple.com/documentation/Xcode/understanding-and-improving-swiftui-performance
- https://developer.apple.com/documentation/xcode/improving-app-responsiveness

## Audit Contract

- Primary workflows inferred from the app: Ingest, Knowledge Universe, Q&A, Trading Lens, Projects, Analytics, paper detail, topic glossary, imports/exports, and long-running background actions.
- Recent suspected weak spots: animated universe runtime cost, graph inspector behavior, large corpus rendering, app-bundle launch paths, and unsupported Foundation Models state.
- "Done" for this pass: commands and runtime evidence captured, primary surfaces inspected where possible, blockers and risks classified, and weakest truthful readiness label assigned.

## Commands And Evidence

| Check | Command or Tool | Result | Evidence |
| --- | --- | --- | --- |
| Project discovery | source/package inspection | Pass | SwiftPM package with `Sources/LiteratureAtlas`, `Tests/LiteratureAtlasTests`, `analytics/`, `analytics/ffi/` |
| Build/run script | `./script/build_and_run.sh --verify` | Pass after fix | Builds and launches `dist/LiteratureAtlas.app`; process `LiteratureAtlas` present |
| Swift build | `swift build` | Pass | Run by build script |
| Swift tests | `swift test` | Pass | 51 tests, 1 existing opt-in ingestion smoke skipped, 0 failures |
| Python lint | `.venv/bin/python -m ruff check analytics/` | Pass | `All checks passed!` |
| Python tests | `.venv/bin/python -m pytest analytics/tests -v` | Pass | 9 passed |
| Rust FFI tests | `cargo test --manifest-path analytics/ffi/Cargo.toml` | Pass | 3 passed |
| Stale Rust CLI gate | `cargo test --manifest-path analytics/rust/Cargo.toml` | Blocked | `analytics/rust/Cargo.toml` does not exist |
| Launch data load | app bundle launch | Fixed, verified | Before: app showed 0 papers; after: 3919 papers and 72 clusters |
| UI smoke | running app screenshot/navigation | Partial pass | Universe graph and inspector verified; full tab walk limited by native UI automation |
| Logs | `/usr/bin/log show --last 1m --style compact --predicate 'process == "LiteratureAtlas"'` | Pass | No crash; missing-SF-Symbol fault fixed and absent from latest filtered sample |
| Performance | `ps -o pid,ppid,stat,etime,pcpu,pmem,rss,command -ax` | Caution | Debug Universe samples remained about 25% CPU; RSS varied after relaunch |
| Accessibility automation | AppleScript/System Events and XcodeBuildMCP attempt | Blocked | XcodeBuildMCP snapshot requires simulator defaults; AX tree was not useful enough for full macOS tab walk |

## Feature Matrix

| Workflow / Feature | State Tested | Status | Notes |
| --- | --- | --- | --- |
| App launch | `dist/LiteratureAtlas.app` | Verified after fix | App now resolves repo `Output/` and shows real corpus counts from a launched bundle |
| App shell / sidebar | default launch | Source-reviewed, visually smoke-tested | Sidebar renders native controls; full tab-click automation remains incomplete |
| Ingest | source review and attempted navigation | Source-reviewed | File importer and ingest writes were not exercised to avoid unintended corpus writes |
| Knowledge Universe | existing corpus, graph, inspector | Verified | Graph is readable, clickable, and inspector no longer compresses/overlaps; labels strip obvious markdown bold markers |
| Topic glossary/export controls | source review | Source-reviewed | Glossary/export controls render in Universe; export side effects were not executed |
| Q&A | source review | Source-reviewed | Foundation Models availability/log activity observed; prompt workflow not fully exercised |
| Trading Lens | source review | Source-reviewed | Kept as a separate specialist surface; main Universe is general-purpose |
| Projects | source review | Source-reviewed | No runtime project mutation tested |
| Analytics | source review plus backend tests | Source-reviewed | Analytics backend tests pass; UI recompute/write actions not executed |
| Paper detail | graph selection path | Partial | Cluster inspector verified; individual paper detail not fully walked |
| Long-running actions | source review | Source-reviewed | Build Universe and naming actions remain explicit button actions |
| Empty/error states | bundle empty-data regression | Fixed | App-bundle path bug was the concrete empty state found and fixed |
| Import/export integrations | source review | Not executed | External file/document side effects require manual validation |

Status values: verified, fixed, partial, source-reviewed, blocked, not executed.

## Visual And Animation Review

- Layout: primary Universe layout is materially better than the earlier dot-field view. It now reads as a graph: larger nodes, visible edges, selectable inspector, pan/zoom support, and native side navigation.
- Readability: visible graph labels no longer show raw `**markdown**` markers. One long node label still truncates, which is acceptable for dense graph nodes but should gain tooltip/detail affordance in a future polish pass.
- Native macOS feel: the app bundle launches normally, menu bar integration is present, and controls use standard SwiftUI buttons/pickers where possible.
- Animation smoothness: animation cadence was reduced from 10 Hz/12 Hz to 6 Hz/8 Hz for the starfield/graph timelines. Motion remains continuous, but debug CPU is still higher than ideal.
- Interaction feedback: selected cluster state and right inspector are clear. The right inspector now scrolls, so content remains usable at the tested 1500 x 980 window size.
- Current content caveat: the app surface is general-purpose, but the loaded corpus is still trading-heavy, so some generated cluster labels remain trading-themed data labels.
- Screenshots:
  - `docs/audits/literatureatlas-launch-2026-06-29.png` captured the initial app-bundle empty-data regression.
  - `docs/audits/literatureatlas-universe-after-fix-2026-06-29.png` captured restored corpus counts and the fixed inspector.
  - `docs/audits/literatureatlas-final-universe-clean-names-2026-06-29.png` captured the final graph with cleaned labels.

## Performance Review

- Reproduction path: build and launch `dist/LiteratureAtlas.app`, open the default Knowledge Universe, wait about one minute.
- Baseline issue: pre-audit animated surfaces were reported as spinning/unusable and earlier runtime samples showed elevated debug CPU.
- Fixes applied:
  - Avoided app-bundle empty-data fallback by resolving repo paths through `AppPaths` instead of current working directory.
  - Reduced always-on `TimelineView` cadence for the Universe field and graph.
  - Made the cluster inspector scroll instead of compressing content.
- After: app remained interactive and rendered the 3919-paper corpus, but debug CPU samples after launch still hovered around 25%; RSS varied between samples after relaunch.
- Remaining risk: this is acceptable for a debug smoke pass, but not enough for a release-quality performance claim. A follow-up should run a Release build plus Instruments or a structured `sample` trace focused on `TimelineView`, canvas drawing, graph layout, and glow/shadow effects.

## Issues

| Severity | Area | Finding | Evidence | Fix / Next Action |
| --- | --- | --- | --- | --- |
| High | App-bundle launch | Proper `.app` launch resolved `Output/` from the process CWD and showed 0 papers/0 clusters. | Initial bundle smoke screenshot and runtime state. | Fixed with `AppPaths`; app now resolves repo root from env/CWD/bundle path and shows 3919 papers. |
| Medium | Universe inspector | Right panel compressed and overlapped content for selected clusters. | Runtime screenshot after first fix. | Fixed by wrapping inspector content in a `ScrollView`. |
| Medium | Universe graph readability | Generated topic labels showed raw markdown bold markers. | Runtime graph labels included `**...**`. | Fixed with `DisplayText.clusterName` on visible cluster labels. |
| Medium | Performance | Debug Knowledge Universe still uses about 25% CPU after launch samples. | `ps` samples around `pcpu 25.0` to `25.5`; RSS varied after relaunch. | Follow up with Release/Instruments profiling and further animation/backdrop throttling. |
| Low | Runtime logs | SwiftUI logged a missing SF Symbol fault for `point.3.connected.trianglepath`. | Unified log sample after launch. | Fixed by replacing project icons with standard folder symbols; latest filtered log sample no longer shows it. |
| Medium | Test/docs drift | `MEMORY.md` referenced `analytics/rust/Cargo.toml`, but that manifest is absent. | Cargo command fails with missing manifest. | Memory updated to treat Rust FFI as the only current Rust manifest. |
| Medium | UI automation coverage | Full native macOS tab walk was not automated end to end. | XcodeBuildMCP snapshot is simulator-oriented; AX tree shallow. | Add macOS-focused UI automation/accessibility identifiers or an app test harness. |
| Low | Data content | Current corpus still produces trading-heavy cluster labels. | Final Universe screenshot. | Expected from current corpus; validate with a broader corpus when available. |

## Final Readiness Label

- Label: **Smoke-clean for the primary Knowledge Universe path; not polish-ready/release-candidate.**
- Why: build, tests, lint, app-bundle launch, corpus load, graph readability, and inspector usability are now verified. The primary regression found during the audit was fixed.
- Remaining blockers: release performance profiling, full native UI workflow automation, and manual validation of file-import/export side effects.
- Next verification step: run a Release build under Instruments on the Knowledge Universe, then add a lightweight macOS UI smoke harness for tab navigation and inspector/paper-detail interactions.
