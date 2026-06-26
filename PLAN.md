# Plan

## Context
- The immersive knowledge universe branch launches, but the current graph interaction is wrong for inspection.
- Cluster node taps navigate immediately, so the right details panel cannot behave like a stable inspector.
- The paper universe switches to anonymous dot mode for larger subtopics, making it unreadable and not graph-like enough.

## Assumptions
- Tap should select and inspect; explicit buttons should navigate deeper or open full details.
- The paper map should remain fast for large paper sets, so labels must be adaptive rather than showing every full card at once.
- Dragging individual paper nodes is enough to make the graph feel movable while existing canvas pan/zoom remains available.

## Constraints
- Keep the native SwiftUI/macOS shell and existing model APIs.
- Avoid expensive layout work in `body`; keep the lightweight deterministic layout and bounded animation.
- Preserve current sheet/overlay paper detail behavior.

## Options considered
1. Force full paper cards for every paper.
2. Keep dot mode but add selectable labels, focused inspector state, hover/selection expansion, and per-node dragging.
3. Replace the map with a new graph engine.

Chosen: 2 because it fixes readability and interaction directly without destabilizing the SwiftUI app.

## Execution plan
1. Separate cluster selection from navigation so the right inspector stays active.
2. Add explicit zoom labels/actions in the inspector for mega topics and subtopics.
3. Add focused paper state shared between the graph and right sidebar.
4. Replace anonymous paper dots with labeled graph nodes that support hover, selection, and dragging.
5. Add a focused paper inspector above the paper list.
6. Run SwiftPM build/tests, launch the app, and inspect runtime status.
7. Update durable memory if the graph interaction convention changes.

## Test plan
- `swift build`
- `swift test`
- `swift run LiteratureAtlas`
- Runtime process check after launch.

## Risks and rollback
- Risk: extra labels clutter dense graphs.
  - Rollback: reduce adaptive label density while keeping hover/selection labels.
- Risk: node drag conflicts with canvas pan.
  - Rollback: keep drag on graph nodes only and leave background pan unchanged.
- Risk: sidebar selection state drifts after filters change.
  - Rollback: clear focused paper on filter/subtopic changes.

## Memory impact
- Record that map taps inspect/select and deeper navigation is explicit from the inspector; paper graph nodes are labeled/draggable with a focused right-panel inspector.

## Notes / Results
- Changes:
  - Cluster node taps now only select/inspect; automatic drill-in was removed from `onSelect`.
  - Cluster inspector actions now explicitly say `Zoom into subtopics` or `Open paper graph`.
  - Added shared focused-paper state between the paper graph and right sidebar.
  - Added a focused paper inspector with summary, metrics, clear, and open-details actions.
  - Replaced anonymous paper dots with adaptive labeled graph nodes that support hover, selection, and per-node dragging.
  - Expanded cluster node hit areas so card clicks are more reliable.
  - Reduced universe animation cadence/star counts to keep the debug build responsive.
- Tests run:
  - `swift build` (pass)
  - `swift test` (pass: 49 tests, 1 opt-in ingestion smoke skipped)
  - `swift run LiteratureAtlas` (pass; app launched and remains running for validation)
  - Runtime check after settling: debug build measured about 11% CPU and ~687 MB RSS with Universe active.
- Tradeoffs:
  - Kept adaptive labels instead of rendering every paper as a full card because dense subtopics would become slower and less readable.
  - Left paper list rows opening full details while graph taps focus the inspector; this preserves existing list behavior and fixes the graph workflow.
