# Plan

## Context
- The user reports the LiteratureAtlas left sidebar is not clickable.
- Runtime reproduction confirms the click reaches the sidebar row text, but the selected view remains on Knowledge Universe.
- Sampling found a second root cause: when two clusters are selected, `BridgingSection.body` repeatedly runs claim/bridge analysis during SwiftUI layout and can pin the main thread at 100% CPU.

## Assumptions
- "Left panel" means the LiteratureAtlas app sidebar with Ingest, Universe, Q&A, Trading, Projects, and Analytics.
- Success means each sidebar row switches the detail view when clicked in the launched `.app` bundle.

## Constraints
- Keep the fix narrowly scoped to navigation/hit testing.
- Do not mutate corpus data or run import/export side effects.
- Verify against the real app bundle, not only source review.

## Options considered
1. Add a broad overlay/hit-testing workaround around the sidebar.
2. Fix the SwiftUI selection/tag contract in `RootView`.
3. Replace the sidebar `List` with explicit buttons.

Chosen: 2 plus removing layout-time bridge analysis because reproduction shows events reach the row but selection does not change, and process sampling shows the main thread can be saturated by `BridgingSection.body`.

## Execution plan
1. Replace inert `List(selection:)` rows with explicit sidebar buttons that set `nav.selectedTab`.
2. Move expensive bridge paper analysis out of `BridgingSection.body`; make bridge search explicit/on-demand.
3. Rebuild and relaunch through `./script/build_and_run.sh --verify`.
4. Click Ingest, Universe, Q&A, Trading, Projects, and Analytics in the live app.
5. Capture verification evidence and run `swift test`.
6. Update TODO, MEMORY if durable knowledge changed, and record final notes.

## Test plan
- Runtime click smoke for all sidebar tabs in `dist/LiteratureAtlas.app`.
- Process sample/CPU check after removing body-time bridge work.
- `swift test`.

## Risks and rollback
- Risk: row selection still fails because another overlay captures clicks.
  - Rollback: inspect AX hit targets and convert the sidebar to explicit native buttons.
- Risk: switching to concrete tags breaks compilation.
  - Rollback: restore optional tags and use an explicit `onTapGesture` per row after confirming the compiler/runtime behavior.

## Memory impact
- Record the fixed sidebar selection convention if verified.

## Notes / Results
- Changes: replaced the sidebar `List(selection:)` rows with explicit full-width native-style buttons that set `nav.selectedTab`; moved bridge paper search out of `BridgingSection.body` and behind an explicit `Find bridging papers` button to stop layout-time claim graph recomputation.
- Tests run: `./script/build_and_run.sh --verify` passed; focused `swift test --filter AppPathsTests` passed; full `swift test` passed with 51 tests and 1 expected opt-in ingestion smoke skipped.
- Tradeoffs: bridge influence/claim paths are no longer auto-rendered during selection because that made normal UI navigation unusable; bridge paper search remains available on demand.
