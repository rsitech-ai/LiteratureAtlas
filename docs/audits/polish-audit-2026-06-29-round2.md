# LiteratureAtlas SwiftUI Polish Audit - Round 2

Date: 2026-06-29
Branch: `feat/andrzej_immersive-galaxy-ui`
App target: `dist/LiteratureAtlas.app`
Readiness label: **Smoke-clean with audit fixes; not release-candidate certified**

## Executive Status

- The app builds, launches, and stays responsive in the macOS app bundle.
- Root navigation is functionally fixed for the routes verified by live click evidence: Ingest, Universe, Q&A, and Analytics. Trading and Projects recovered cleanly by process/window state, but AppleScript title reads were intermittently unreliable immediately after those route clicks.
- The previous duplicate `ForEach` warning is not present in the final strict log scan.
- A real runtime polish issue was found and fixed during this audit: Analytics could emit CoreAnimation bogus layer-size warnings from unsafe chart geometry / filled factor charts.
- The final strict log scan after relaunch showed no `Invalid frame dimension`, bogus layer-size, duplicate `ForEach`, crash, SwiftUI, fatal, error, or fault lines.

## Changes Made During Audit

1. Added shared chart geometry guards in `Sources/LiteratureAtlas/Views/ChartPlotGeometry.swift`.
2. Guarded non-finite Analytics width measurements before using them for chart heights.
3. Clamped Swift Charts plot-frame dimensions/positions before applying hover-tracking overlay frames.
4. Replaced Analytics factor exposure filled `AreaMark`s with bounded `LineMark`s because negative factor scores were producing oversized CoreAnimation paint layers.
5. Hardened generic `onWidthChange` preference reduction against non-finite geometry values.

## Verification Commands

| Check | Result |
|---|---|
| `./script/build_and_run.sh --verify` | Passed; app launched as `dist/LiteratureAtlas.app` |
| `swift build` | Passed after source changes |
| `swift test` | Passed: 51 tests, 1 expected opt-in ingestion smoke skipped |
| `.venv/bin/python -m ruff check analytics/` | Passed |
| `.venv/bin/python -m pytest analytics/tests -v` | Passed: 9 tests |
| `cargo test --manifest-path analytics/ffi/Cargo.toml` | Passed: 3 tests |
| Strict unified log scan after final launch | Passed; no matching runtime faults/errors |

## Runtime Evidence

- Final process: `LiteratureAtlas` running from `dist/LiteratureAtlas.app`.
- Final window state: foreground, one window, title `Knowledge Universe`.
- Screenshots captured under `docs/audits/round2-*.png` for baseline, route states, Analytics after fix, and Universe final state.
- The AX route automation had intermittent `System Events` `window 1` read failures right after some clicks. Follow-up process checks showed the app remained alive with one window, and later title reads recovered.

## Interaction Coverage

| Area | Status | Notes |
|---|---|---|
| App launch | Verified | Bundle launch through repo script. |
| Sidebar: Ingest | Verified | Click changed title to `Literature Atlas`. |
| Sidebar: Universe | Verified | Click changed title to `Knowledge Universe`; final visible state is the universe map. |
| Sidebar: Q&A | Verified | Click changed title to `Q&A`. |
| Sidebar: Analytics | Verified after recovery | Visible Analytics state verified and final chart/log issue fixed. |
| Sidebar: Trading | Partial | Click automation hit transient AX read failure; process/logs stayed healthy. Needs manual user click confirmation or a native UI test harness for stronger proof. |
| Sidebar: Projects | Partial | Same AX read limitation as Trading. |
| Knowledge Universe controls | Source + visual verified | Resolution/lens/zoom controls are visible and native segmented controls; executing `Build universe`, `Export`, and naming actions was not done because they mutate or write artifacts. |
| Analytics backend actions | Source + visual verified | Reload/health/rebuild/install controls are visible; rebuild/install/open-folder actions were not executed during the polish audit. |
| AI/debate/generation actions | Not executed | These can be long-running or depend on model availability; source reviewed as button-gated. |

## Findings

### Fixed: Analytics produced oversized CoreAnimation paint layers

Severity: High polish/performance risk.

Before the fix, the app logged:

```text
Ignoring bogus layer size (1203.000000, 468261.000000)
```

The likely trigger was a filled factor exposure chart with negative factor scores combined with unguarded chart plot-frame geometry during SwiftUI layout. The fix converts factor exposure fills to lines and clamps invalid geometry before applying hover overlay frames.

Final strict log scan after relaunch:

```text
no output
```

### Remaining: AX automation is flaky on some route reads

Severity: Medium audit confidence issue, not currently a user-facing app fault.

AppleScript route clicks can change focus/title correctly, but immediate `window 1` title reads intermittently return `Invalid index (-1719)` for Trading/Projects/Analytics. Process checks showed the app was still alive with one window and later recovered. For future release confidence, add a small XCTest UI route harness or AppKit-level smoke helper instead of relying on AppleScript AX reads.

### Remaining: General universe still surfaces trading-heavy cluster labels

Severity: Product/content polish issue.

The app shell is now framed as a general knowledge universe, but the current corpus still makes the visible cluster labels read trading-specific, for example `Signal Enrichment in Trading` and `Quantitative Trading Spaces`. This may be correct for the loaded corpus, but it conflicts with the goal that the main universe should feel general-purpose. The app should either make clear that labels reflect the current corpus, or add a display layer that avoids over-specialized phrasing unless the user enters the Trading lens.

## Gate Call

**Repo/app smoke status:** Pass after fixes.

**Release-candidate status:** Not claimed. This audit did not run a Release build, Instruments profile, signing/notarization checks, complete native UI automation, destructive corpus operations, export flows, or long-running AI workflows.

Recommended next gate: add a native UI smoke test for the six sidebar routes and the highest-risk buttons, then run a Release build with Instruments if this branch is close to shipping.
