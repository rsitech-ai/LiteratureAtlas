# Plan

## Context
- User selected the "Immersive Galaxy" visual direction for LiteratureAtlas.
- The app is a SwiftPM SwiftUI executable with a tabbed macOS/iOS surface.
- Current app already has a strong dark animated `MapView`; quieter screens such as `IngestView`, `QuestionView`, and top-level analytics surfaces should be brought into the same visual language.
- Existing document/knowledge-base work was preserved in commit `81aa19e` on `feat/andrzej_literatureatlas-document-kb-snapshot`; this branch starts from that commit.

## Assumptions
- The redesign should improve visual polish without changing core data models or ingestion/analytics behavior.
- macOS 26/iOS 26 availability lets us use current SwiftUI APIs, with platform checks where Liquid Glass APIs are not cross-platform or not available.
- The user prefers expressive visuals over restrained native-library styling, but the app should still feel like a native macOS app.

## Constraints
- Keep the diff focused on SwiftUI presentation and shared styling.
- Do not touch unrelated Rust/analytics/data-quality blockers unless a build forces it.
- Preserve native macOS affordances: toolbar buttons, system controls, sheets, keyboard-friendly flows, and semantic colors where practical.
- Keep animation bounded to avoid jank in large lists and charts.
- Do not commit local `.superpowers/` companion state.

## Options considered
1. Native macOS Library: strongest desktop convention, lowest risk, but less aligned with user's selected direction.
2. Colorful Research Cockpit: balanced, native shell with richer visual hierarchy, but less immersive.
3. Immersive Galaxy: app-wide dark cosmic visual language, higher wow factor, highest performance risk.

Chosen: 3 because the user selected it explicitly after seeing visual options. Bound the implementation so heavy surfaces remain performant and native controls remain recognizable.

## Execution plan
1. Create a durable design spec under `docs/superpowers/specs/`.
2. Add a shared galaxy visual system for colors, ambient backdrop, glass surfaces, hero headers, stat pills, and adaptive button styling.
3. Replace the root static gradient with an animated galaxy backdrop and smoother tab transitions.
4. Upgrade `GlassCard` to support richer galaxy material while keeping existing call sites simple.
5. Refresh `IngestView` with a more immersive hero, status deck, and action controls.
6. Refresh `QuestionView` with galaxy header, answer/evidence cards, and polished empty/loading states.
7. Lightly tune `AnalyticsView` and shared overlays where low-risk, reusing the shared system.
8. Build and test with SwiftPM, then run a short app launch smoke.
9. Update `PLAN.md`, `TODO.md`, and `MEMORY.md` if durable conventions are established.

## Test plan
- `swift build`
- `swift test`
- `swift run LiteratureAtlas` launch smoke, then stop the GUI process after startup.
- If visual changes touch analytics Python or FFI accidentally, rerun the relevant existing gates.

## Risks and rollback
- Risk: ambient animation increases CPU or invalidates large views too broadly.
  - Rollback: keep animation inside isolated backdrop view, respect reduce motion, and remove repeat animation if build or runtime smoke suggests trouble.
- Risk: dark galaxy styling reduces readability.
  - Rollback: raise material opacity, increase contrast on cards, and keep text on semantic foreground styles where possible.
- Risk: native macOS feel regresses.
  - Rollback: keep system controls and toolbar placements; avoid custom replacement for TabView or menus in this pass.

## Memory impact
- Record the shared visual system convention if implementation lands and builds.

## Notes / Results
- Changes:
- Tests run:
- Tradeoffs:
