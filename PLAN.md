# Plan

## Context
- The user confirmed LiteratureAtlas should be fully generalized, not trading-first with an optional trading lens.
- The implementation must remove trading/quant framing from user-facing app surfaces while preserving existing data compatibility.
- Design spec: `docs/superpowers/specs/2026-06-29-full-generalization-design.md`
- Implementation plan: `docs/superpowers/plans/2026-06-29-full-generalization.md`

## Assumptions
- Full generalization means app chrome, UI copy, prompts, exports, and visible workflows should use generic research/insight language.
- Internal Swift type names and JSON keys may remain if changing them only increases migration risk.
- Existing `trading_lens` and strategy project data must continue to load.

## Constraints
- Do not destructively migrate `Output/`.
- Keep changes product-facing and migration-safe.
- Verify with Swift build/tests and real app launch.

## Options considered
1. Rename-only generalization.
2. Migration-preserving product generalization.
3. Clean-slate removal of trading/strategy subsystems.

Chosen: 2 because it removes trading from the app experience without breaking existing corpus artifacts.

## Execution plan
1. Generalize navigation and planner chrome.
2. Generalize the Insights lens UI.
3. Generalize paper detail and row actions.
4. Generalize project UI.
5. Generalize analytics, markdown export, prompt fallback, and log copy.
6. Update tests/docs/memory.
7. Run full verification and live app smoke.

## Test plan
- `swift build`
- `swift test`
- `.venv/bin/python -m ruff check analytics/`
- `.venv/bin/python -m pytest analytics/tests -v`
- `cargo test --manifest-path analytics/ffi/Cargo.toml`
- `./script/build_and_run.sh --verify`
- Strict runtime log scan after final launch

## Risks and rollback
- Risk: broad copy changes miss a visible trading string.
  - Rollback: run focused `rg` over Swift/UI/docs and classify remaining internal-only terms.
- Risk: exporter tests assert old labels.
  - Rollback: update assertions to generic labels while preserving stored key compatibility.
- Risk: app launch is fine but route automation remains flaky.
  - Rollback: verify by screenshot/window state and report automation limits honestly.

## Memory impact
- Record the generalization boundary: user-facing app is general research/insight language; legacy trading/strategy names can remain as compatibility internals.

## Notes / Results
- Changes: Generalized product-facing navigation, planner, Insights, paper details/actions, research projects, analytics, markdown exports, Obsidian setup copy, runtime logs, and prompt templates from trading/quant language to general research/insight language.
- Tests run: `swift build`; `swift test` (51 tests, 1 opt-in ingestion smoke skipped); `.venv/bin/python -m ruff check analytics/`; `.venv/bin/python -m pytest analytics/tests -v` (9 passed); `cargo test --manifest-path analytics/ffi/Cargo.toml` (3 passed); `./script/build_and_run.sh --verify`; app running from `dist/LiteratureAtlas.app` as process 25120.
- Tradeoffs: Internal Swift type names, JSON keys, event names, `.strategy.json`, and `quant_kg.json` remain for compatibility. Remaining finance terms are compatibility parsing or claim-graph/test content that only appears when source papers contain those concepts.
