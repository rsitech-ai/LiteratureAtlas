# Plan

## Context
- The current branch already contains the immersive galaxy UI and launch-responsiveness fix.
- The user wants the map to become a general galaxy/universe of knowledge rather than a trading-specific cockpit.
- The map should feel fluid, animated, dynamic, adaptive, and visually impressive while staying usable on macOS.

## Assumptions
- Trading-specific tooling remains available in the dedicated Trading tab and related detail surfaces.
- The primary Map view should default to general corpus exploration: papers, topics, novelty, consensus, methods, time, and interest.
- Animation must be bounded and respect Reduce Motion.

## Constraints
- Keep the native `NavigationSplitView` shell and standard macOS affordances.
- Do not reintroduce expensive work in SwiftUI `body` or app launch.
- Keep map animation local to the map canvases and avoid full-window drawing groups.
- Validate with SwiftPM build/test and a launch/runtime CPU check.

## Options considered
1. Full custom 3D universe: highest visual ambition, but too risky for this SwiftUI pass and likely to destabilize performance.
2. Map-only cinematic upgrade: add a richer animated starfield/nebula canvas, liquid-glass panels, general knowledge copy, and remove trading-specific map controls.
3. Copy-only generalization: safest, but does not satisfy the request for a breathtaking dynamic galaxy.

Chosen: 2 because it gives the map a dramatic universe feel while staying inside SwiftUI-native, bounded rendering.

## Execution plan
1. Remove trading-specific sorting, color, and filter controls from the primary paper map.
2. Rename visible map copy from step/trading-style framing to general knowledge-universe language.
3. Add a lightweight animated starfield/nebula background for the map and map canvases.
4. Improve node and paper visuals with fluid glow, orbital motion, and adaptive Reduce Motion behavior.
5. Use system material/liquid-glass-style surfaces without painting over the native sidebar/root shell.
6. Update `PLAN.md`, `TODO.md`, and `MEMORY.md` with durable conventions learned.
7. Run `swift build`, `swift test`, launch the app, and measure process health.

## Test plan
- `swift build`
- `swift test`
- `swift run LiteratureAtlas`
- Post-launch `ps` CPU/memory check, plus sample if CPU remains high.

## Risks and rollback
- Risk: richer animation raises CPU.
  - Rollback: lower timeline frequency, reduce star counts, and keep Reduce Motion support.
- Risk: removing trading controls hides useful capability.
  - Rollback: keep the Trading tab as the domain-specific surface; re-add map controls only if the general map needs a domain lens selector later.
- Risk: Liquid Glass API availability or signature mismatches.
  - Rollback: use stable SwiftUI materials and standard controls, preserving the same visual hierarchy.

## Memory impact
- Record that primary map UI is general-purpose and trading-specific controls belong in the Trading tab.

## Notes / Results
- Changes:
  - Renamed the primary map experience to `Knowledge Universe` and made it the default launch section.
  - Reframed visible map copy around general knowledge exploration: topics, papers, methods, evidence, and open questions.
  - Removed trading-specific sort/color/filter controls from the primary paper map; trading-specific exploration remains in the Trading tab.
  - Added a bounded animated universe field with deterministic star drift, twinkle, nebula motion, and orbital dust.
  - Reused the animated universe field inside cluster and paper canvases, with Reduce Motion support.
  - Added glow/pulse treatment to topic nodes using the existing cluster timeline.
  - Tuned map panels toward lighter system material/glass-like surfaces over the animated universe.
  - Replaced the Q&A placeholder with a domain-neutral research prompt.
- Tests run:
  - `swift build` (pass; existing unrelated deprecation warning in `StrategyProjectsView`)
  - `swift test` (pass: 49 tests, 1 opt-in ingestion smoke skipped)
  - `swift run LiteratureAtlas` (pass; app opens on `Knowledge Universe`)
  - Runtime check with Universe active: debug build measured about 10-13% CPU and ~250-286 MB RSS after settling.
  - Screenshot sanity check: visible app window titled `Knowledge Universe`; animated universe canvas and general controls render.
- Tradeoffs:
  - Used stable SwiftUI materials rather than direct `glassEffect` calls because this repo currently builds cleanly with the existing SwiftPM/SDK setup and material surfaces satisfy the glass direction without API-signature risk.
  - Kept topic names data-driven. If the loaded corpus contains trading papers, generated cluster names may still include trading terms; the UI framing and controls are no longer trading-specific.
  - Opened the app on Universe by default to make the galaxy the first-viewport experience.
