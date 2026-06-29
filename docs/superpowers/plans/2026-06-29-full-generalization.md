# Full Generalization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make LiteratureAtlas read and behave as a general research/knowledge app instead of a trading-first app.

**Architecture:** Preserve legacy data models and JSON keys, but generalize product-facing copy, navigation, prompts, markdown labels, and UI actions. This avoids destructive migration while removing trading from the user experience.

**Tech Stack:** Swift 6, SwiftUI, SwiftPM tests, Python analytics tests, Rust FFI tests.

---

### Task 1: Generalize Navigation And Planner Chrome

**Files:**
- Modify: `Sources/LiteratureAtlas/App/AppNavigation.swift`
- Modify: `Sources/LiteratureAtlas/Views/RootView.swift`
- Modify: `Sources/LiteratureAtlas/Views/ReadingPlannerCard.swift`

- [ ] Change tab title from `Trading` to `Insights`, icon from `dollarsign.circle` to `lightbulb`, and route content to the existing lens view.
- [ ] Change planner copy from trading lens/priority language to insight brief/application priority language.
- [ ] Build with `swift build`.

### Task 2: Generalize Insight Lens UI

**Files:**
- Modify: `Sources/LiteratureAtlas/Views/TradingLensView.swift`
- Modify: `Sources/LiteratureAtlas/Views/TradingLensCharts.swift`
- Modify: `Sources/LiteratureAtlas/Views/TradingScoreStrip.swift`

- [ ] Change screen title, empty states, context menu actions, filters, chart labels, card labels, and hypothesis language to general insight terminology.
- [ ] Keep old function/model names where they are implementation details.
- [ ] Build with `swift build`.

### Task 3: Generalize Paper Detail And Row Actions

**Files:**
- Modify: `Sources/LiteratureAtlas/Views/PaperActionRow.swift`
- Modify: `Sources/LiteratureAtlas/Views/PaperDetailView.swift`

- [ ] Change visible paper actions to `Generate insight brief`, `Create research project`, `Generate research plan`, and `Audit plan`.
- [ ] Change detail sections to `Insight brief`, `Hypotheses`, `Research plans`, and `Plan audit`.
- [ ] Build with `swift build`.

### Task 4: Generalize Projects UI

**Files:**
- Modify: `Sources/LiteratureAtlas/Views/StrategyProjectsView.swift`
- Modify: `Sources/LiteratureAtlas/Views/StrategyProjectDetailView.swift`

- [ ] Change visible project copy to research-project language.
- [ ] Replace finance/performance metric labels in UI with general evaluation labels where possible without changing stored fields.
- [ ] Build with `swift build`.

### Task 5: Generalize Analytics And Export/Prompt Copy

**Files:**
- Modify: `Sources/LiteratureAtlas/Views/AnalyticsView.swift`
- Modify: `Sources/LiteratureAtlas/Services/PaperMarkdownExporter.swift`
- Modify: `Sources/LiteratureAtlas/Services/ClusterMarkdownExporter.swift`
- Modify: `Sources/LiteratureAtlas/Services/AtlasMarkdownExporter.swift`
- Modify: `Sources/LiteratureAtlas/Services/ObsidianVaultAssetsExporter.swift`
- Modify: `Sources/LiteratureAtlas/Services/LLMActors.swift`
- Modify: `Sources/LiteratureAtlas/App/AppModel.swift`
- Modify: prompt files under `Prompts/` if present.

- [ ] Change visible analytics and export labels to generic insight/project terminology.
- [ ] Update fallback LLM prompts to request general insight briefs and research plans.
- [ ] Preserve old prompt file loading where needed, but make fallbacks and logs generic.
- [ ] Build with `swift build`.

### Task 6: Tests, Docs, Runtime Smoke

**Files:**
- Modify tests only if generic exported strings change assertions.
- Modify: `README.md`
- Modify: `MEMORY.md`
- Modify: `PLAN.md`
- Modify: `TODO.md`

- [ ] Update tests that assert old visible export labels.
- [ ] Run `swift test`.
- [ ] Run `.venv/bin/python -m ruff check analytics/`.
- [ ] Run `.venv/bin/python -m pytest analytics/tests -v`.
- [ ] Run `cargo test --manifest-path analytics/ffi/Cargo.toml`.
- [ ] Run `./script/build_and_run.sh --verify`.
- [ ] Verify the sidebar shows `Insights`, not `Trading`, and final strict log scan is clean.
