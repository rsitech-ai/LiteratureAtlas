# Immersive Galaxy UI Design

## Decision

Use the "Immersive Galaxy" visual direction selected by the user in the visual companion. The goal is to make LiteratureAtlas feel more animated, colorful, and premium while preserving native macOS behavior.

## Scope

This pass is a focused visual-system update, not a product restructure. It should touch SwiftUI presentation code and shared styling only.

Primary targets:
- `RootView`: replace the static gradient with a reusable animated galaxy backdrop and smoother top-level tab transitions.
- `GlassCard`: make the default card match the galaxy language while preserving existing call sites.
- `IngestView`: upgrade the first-run and active-ingestion experience with an immersive hero, status deck, and clearer action groups.
- `QuestionView`: upgrade the Q&A flow with richer empty, loading, answer, relevant-document, and evidence states.
- `AnalyticsView` and overlays: apply light shared-surface improvements where low-risk.

Non-goals:
- No analytics model changes.
- No ingestion behavior changes.
- No repair of the deleted `analytics/rust` CLI in this visual branch.
- No custom replacement for native macOS tab/menu/window mechanics.
- No broad rewrite of the already complex `MapView`.

## Visual Language

The app should feel like a research cockpit inside a knowledge galaxy:
- dark cosmic base, not flat white panels
- slow ambient movement behind content
- saturated but controlled accents: cyan, violet, pink, gold, mint
- luminous status tokens and progress indicators
- layered glass cards that maintain readable contrast
- subtle hover, selection, and state transitions

The map can remain the strongest immersive surface. Other screens should inherit its atmosphere without becoming as visually dense.

## Native macOS Guardrails

Keep:
- SwiftUI `TabView`
- native buttons, pickers, toggles, file importer, sheets, and toolbars
- text fields with expected keyboard behavior
- scroll views and lazy stacks for long content
- semantic foreground styles for readability

Avoid:
- replacing native controls with web-style custom controls
- cardifying sidebars or lists that should stay desktop-dense
- hiding core actions behind gestures
- animating large lists, charts, or every card continuously

## Component Plan

### Galaxy backdrop

Add a reusable ambient background view with:
- dark linear/radial base
- slow angular or radial color movement
- reduce-motion support
- `allowsHitTesting(false)`
- isolated `@State` so animation invalidation stays local

### Shared cards

Upgrade `GlassCard` rather than changing every call site. The default style should:
- use darker material layers
- add a subtle gradient sheen
- improve border contrast
- keep the current padding and corner radius close enough to avoid layout churn

Optional additions:
- tint parameter for important cards
- prominence parameter for hero cards

### Hero and status components

Create small reusable components for:
- screen hero header with icon, title, subtitle, and optional actions
- status pills with consistent color semantics
- metric tiles for counts and health state

These helpers should be view-only and not own app logic.

### Ingest screen

Improve:
- first screen impact with galaxy hero
- folder selection and stop actions as a primary action row
- ingestion progress as a richer status strip
- log panel surrounded by a clearer operational surface

Preserve:
- existing file importer behavior
- ingestion progress model fields
- claim graph and stress-test behavior

### Q&A screen

Improve:
- empty state when no documents are ingested
- question composer
- thinking/loading state
- answer and evidence presentation
- relevant-document cards

Preserve:
- answer generation behavior
- retrieval/evidence data flow
- existing model method calls

### Analytics and overlays

Keep analytics charts stable. Apply only light shared card and header styling in this pass. Do not refactor chart data flow.

## Performance Plan

Potential risks:
- repeat animations invalidating large view trees
- expensive visual effects over charts and long lists
- too many independent animated cards

Mitigations:
- one ambient animated backdrop at the root or per major screen
- no per-row repeat animations
- keep heavy computed work out of `body`
- prefer `LazyVStack` where long lists already exist
- respect reduce motion

## Validation

Required commands:
- `swift build`
- `swift test`
- `swift run LiteratureAtlas` launch smoke, stopped after startup

Visual smoke:
- app launches
- top-level tabs are usable
- Ingest and Q&A remain readable
- no obvious clipped text or broken control layout
- no runaway terminal process remains

## Rollback

Rollback should be simple:
- revert shared visual-system files and the modified SwiftUI views on this branch
- keep the preserved document/knowledge-base snapshot branch intact
- do not touch the preservation commit
