# Full Generalization Design

## Goal

Make LiteratureAtlas a general research and knowledge-universe app, not a trading or quant app. Trading-specific data may remain readable for compatibility, but it must not define the first-class product experience.

## Product Model

The primary app concepts are:

- **Universe**: visual corpus map of topics, papers, evidence, and questions.
- **Insights**: generated applicability briefs, hypotheses, patterns, and ranked papers.
- **Research Projects**: general project workspaces created from papers or manually.
- **Analytics**: corpus health, novelty, consensus, influence, drift, quality, lifecycle, bridges, claims, recommendations, and workflow signals.

Trading/quant concepts are legacy implementation and data details. Existing JSON keys such as `trading_lens`, `strategy_impact`, `alpha_hypotheses`, and strategy project files must continue to decode so current corpora and tests do not break.

## User-Facing Changes

- Sidebar tab `Trading` becomes `Insights` with a general lightbulb/spark icon.
- `Trading lens` screen becomes `Insights`.
- `trading lens scorecard` becomes `insight brief`.
- `strategy project` becomes `research project`.
- `strategy blueprint` becomes `research plan`.
- `alpha hypotheses` becomes `hypotheses`.
- `asset classes`, `horizons`, and `signal archetypes` become `domains`, `timeframes`, and `patterns` where still useful; otherwise they are deemphasized.
- `strategy impact` becomes `application impact` or `relevance`.
- Project details use general labels: `Plan`, `Experiments`, `Outcomes`, `Metrics`, `Evidence`, and `Research plan`.
- Markdown exports use generic callout names by default while preserving old frontmatter identifiers where changing them would break migration.

## Architecture

This is a product-facing generalization, not a full data-schema migration. Internals may keep names like `TradingLensView`, `PaperTradingLens`, and `StrategyProject` in this slice if changing them would cause broad churn. Public copy, navigation, prompts, context menus, sheets, markdown labels, and logs should become general.

The migration boundary is:

- **Decode/read:** keep all existing legacy fields and files.
- **Display/write:** prefer general labels and generic generated prompt output.
- **Navigation:** use generic tab title and action labels.

## Implementation Scope

1. Update navigation, planner, paper actions, paper detail, Insights view, project list/detail, analytics copy, markdown exporters, prompt fallbacks, and README/memory docs.
2. Add or update tests for generic exported markdown labels where practical.
3. Run Swift build/tests, Python/Rust checks if touched indirectly, app launch smoke, strict log scan, and a root sidebar click smoke for `Insights`.

## Non-Goals

- No destructive migration of existing `Output/` data.
- No renaming of all Swift types/files in this slice.
- No removal of old JSON keys.
- No promise that generated cluster names never contain trading words when the loaded corpus itself is trading-heavy; those are data labels, not app chrome.

## Acceptance Criteria

- The main app sidebar has no `Trading` route.
- The app’s visible primary workflows read as general research workflows.
- Paper/project/export surfaces do not present trading as the default frame.
- Existing tests still pass.
- The app launches through `./script/build_and_run.sh --verify`.
- Strict runtime log scan after launch remains clean.
