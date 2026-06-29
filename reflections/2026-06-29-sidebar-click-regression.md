# Reflection Entry

## Task
- **ID/Title:** Sidebar click regression
- **Date:** 2026-06-29
- **Scope:** LiteratureAtlas macOS sidebar navigation

## Plan and Risks
- **Planned approach:** Reproduce the click path in the launched app bundle, inspect AX hit targets, compare the `List(selection:)` implementation to SwiftUI selection expectations, then make the smallest navigation fix.
- **Top failure hypotheses:**
  1. A global overlay intercepts clicks before the sidebar receives them.
  2. The click reaches the row but SwiftUI selection does not update because of a tag/binding mismatch.
  3. The user is clicking a visually confusing background window rather than the LiteratureAtlas sidebar.
- **Success criteria:** Every sidebar item switches the detail view in the launched `.app`; Swift tests pass.

## Candidate Attempts
| Candidate | Summary | Outcome | Signals | Why selected / rejected |
|---|---|---|---|---|
| A | Debug coordinates only | Rejected | AX proved row centers and click target | Coordinates alone were not the root cause |
| B | Fix `List(selection:)` tag contract | Selected | Click reaches row text, but selection stays on Universe | Narrowest likely root cause |
| C | Replace sidebar with buttons | Deferred | Larger UI rewrite | Use only if tag fix fails |

## Reflection
- **Failure modes observed:** Clicks reached sidebar row text but did not change the selected detail view.
- **Root cause:** Two issues compounded: the root sidebar used a `List(selection:)` pattern that received row clicks without reliably updating `nav.selectedTab`, and `BridgingSection.body` could repeatedly run claim graph path analysis during layout when two clusters were selected, pinning the main thread at 100% CPU.
- **Fix that resolved it:** Replaced the sidebar rows with explicit full-width buttons that set `nav.selectedTab`; moved bridge paper search behind a `Find bridging papers` button and removed claim/influence path computation from `body`.
- **What improved score/quality:** Sidebar actions now route directly, the app responds to AX/window automation again, and process CPU dropped from a sampled 100% stuck state back to normal debug idle/animation levels.
- **Useful command-level evidence:** `sample <pid> 5` showed the main thread in `BridgingSection.body`; `./script/build_and_run.sh --verify` passed; live AX/window-title checks reached Literature Atlas, Knowledge Universe, Q&A, Trading lens, Projects/LiteratureAtlas, and Analytics; `swift test` passed 51 tests with 1 expected opt-in smoke skipped.
- **Branch comparison insight (if multiple attempts):** Not applicable.

## Reusable Lesson
- **Pattern that worked:** Combine AX hit-target checks with process sampling; the apparent click bug was partly a main-thread starvation bug.
- **Pattern to avoid:** Heavy claim graph or bridge computation inside SwiftUI `body`, especially in always-visible inspector/sidebar surfaces.
- **Where to apply next:** Any Knowledge Universe inspector feature that touches corpus-scale papers, claims, edges, or embeddings should be explicit/on-demand or cached outside layout.

## Decision
- **Final chosen approach:** Targeted navigation selection fix with live click verification.
- **Commit/rollback decision:** Keep the fix; no rollback needed after live routing checks and green tests.
- **Next step / follow-up:** Add a dedicated macOS UI smoke harness when tooling permits, so sidebar routing can be asserted without fragile screen-coordinate automation.
