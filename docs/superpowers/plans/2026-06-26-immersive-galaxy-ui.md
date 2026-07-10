# Immersive Galaxy UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the approved Immersive Galaxy visual direction to LiteratureAtlas while preserving native macOS behavior and existing app logic.

**Architecture:** Add a focused shared SwiftUI visual layer and reuse it from existing screens. Keep animation isolated in backdrop/status helpers, upgrade existing cards in place, and avoid refactoring the large map/analytics logic.

**Tech Stack:** Swift 6.1, SwiftUI, SwiftPM executable product `LiteratureAtlas`, macOS 26/iOS 26 availability.

---

## File Structure

- Create `Sources/LiteratureAtlas/Views/GalaxyTheme.swift`: shared colors, ambient backdrop, hero/header, metric tile, pill, primary action, and section helpers.
- Modify `Sources/LiteratureAtlas/Views/GlassCard.swift`: preserve the `GlassCard {}` API while adding galaxy material, tint, and prominence options.
- Modify `Sources/LiteratureAtlas/Views/RootView.swift`: use the shared ambient backdrop and animated tab content.
- Modify `Sources/LiteratureAtlas/Views/IngestView.swift`: use shared hero/status/action components and improve layout without behavior changes.
- Modify `Sources/LiteratureAtlas/Views/QuestionView.swift`: use shared hero/cards for composer, answer, documents, and evidence.
- Modify `Sources/LiteratureAtlas/Views/GlobalProgressOverlay.swift`: use galaxy progress styling.
- Modify `PLAN.md`, `TODO.md`, `MEMORY.md`, and `reflections/2026-06-26-immersive-galaxy-ui.md` after implementation.

## Tasks

### Task 1: Shared Galaxy Visual System

**Files:**
- Create: `Sources/LiteratureAtlas/Views/GalaxyTheme.swift`
- Modify: `Sources/LiteratureAtlas/Views/GlassCard.swift`

- [ ] Add `GalaxyTheme`, `GalaxyBackdrop`, `GalaxyHeroCard`, `GalaxyMetricTile`, `GalaxyStatusPill`, `GalaxyPrimaryActionButton`, and `GalaxySectionHeader`.
- [ ] Update `GlassCard` with optional `tint` and `prominence`, keeping existing call sites valid.
- [ ] Run `swift build`.

### Task 2: Root Shell and Overlay

**Files:**
- Modify: `Sources/LiteratureAtlas/Views/RootView.swift`
- Modify: `Sources/LiteratureAtlas/Views/GlobalProgressOverlay.swift`

- [ ] Replace the root static gradient with `GalaxyBackdrop`.
- [ ] Add localized tab-content animation keyed by selected tab.
- [ ] Restyle global progress using shared galaxy components.
- [ ] Run `swift build`.

### Task 3: Ingest Screen

**Files:**
- Modify: `Sources/LiteratureAtlas/Views/IngestView.swift`

- [ ] Replace the header with `GalaxyHeroCard`.
- [ ] Restyle folder actions, progress, activity status, log, claim graph, and assumption cards with shared components.
- [ ] Preserve file importer and model method calls exactly.
- [ ] Run `swift build`.

### Task 4: Question Screen

**Files:**
- Modify: `Sources/LiteratureAtlas/Views/QuestionView.swift`

- [ ] Replace plain stack with a scrollable galaxy surface.
- [ ] Add polished empty state, year filter strip, composer, loading card, answer card, relevant-doc cards, and evidence disclosure.
- [ ] Preserve question recording and answer generation calls exactly.
- [ ] Run `swift build`.

### Task 5: Validation and Closeout

**Files:**
- Modify: `PLAN.md`
- Modify: `TODO.md`
- Modify: `MEMORY.md`
- Modify: `reflections/2026-06-26-immersive-galaxy-ui.md`

- [ ] Run `swift test`.
- [ ] Launch with `swift run LiteratureAtlas`, confirm startup, then stop it.
- [ ] Update plan, checklist, memory, and reflection with final results.
