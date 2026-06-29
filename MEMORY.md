# MEMORY

## Repo overview (languages/frameworks)
- **Swift 6 + SwiftUI** — macOS/iOS app for PDF research atlas (`Sources/LiteratureAtlas/`)
- **Python 3.10+** — Analytics pipeline with DuckDB (`analytics/`)
- **Rust** — FFI library for HNSW/graph algorithms (`analytics/ffi/`)

## Commands

### Setup/install
- Swift build: `swift build`
- Rust FFI build: `cargo build --manifest-path analytics/ffi/Cargo.toml --release`
- Python env + deps: `python -m venv .venv && .venv/bin/python -m ensurepip --upgrade && .venv/bin/python -m pip install -r analytics/requirements.txt`
- macOS app bundle run/smoke: `./script/build_and_run.sh --verify`

### Format
- Rust: `cargo fmt --manifest-path analytics/ffi/Cargo.toml`
- Python: `python -m ruff format analytics/` (configured in pyproject.toml)

### Lint
- Python: `.venv/bin/python -m ruff check analytics/`
- Rust: `cargo clippy --manifest-path analytics/ffi/Cargo.toml`

### Tests
- Swift: `swift test` (51 tests, typically 1 opt-in smoke test skipped without env vars; requires macOS 26+)
- Python: `.venv/bin/python -m pytest analytics/tests -v` (9 tests)
- Rust FFI: `cargo test --manifest-path analytics/ffi/Cargo.toml` (3 tests)

### Integration commands
- Analytics rebuild: `.venv/bin/python analytics/rebuild_analytics.py`
- Output artifact audit: `.venv/bin/python scripts/audit_output_artifacts.py`
- Topic reliability audit: `.venv/bin/python scripts/topic_focus_audit.py --base .`
- Integrated sample smoke run: `scripts/run_example_smoke.sh --count 10`
- Full corpus ingest gate (in-place to repo `Output/`): `LITERATURE_ATLAS_INGEST_SMOKE_INPUT_DIR="$(pwd)/examples" LITERATURE_ATLAS_INGEST_SMOKE_OUTPUT_ROOT="$(pwd)/Output" LITERATURE_ATLAS_INGEST_SMOKE_EXPECTED_COUNT=115 LITERATURE_ATLAS_INGEST_SMOKE_TIMEOUT_SEC=10800 swift test --filter IngestionSmokeTests/testIngestsSampleFolderAndWritesArtifacts`

## Architecture notes
- **Data flow**: PDF → Swift app (summarization, embeddings) → `Output/papers/*.paper.json` → Python analytics → `Output/analytics/analytics.json` → Swift app reloads
- **Output directory**: All artifacts under `Output/` (papers, chunks, clusters, analytics, reports, obsidian)
- **Paper JSON naming**: `savePaperJSON` writes id-suffixed filenames (`<title> [<UUID>].paper.json`) to prevent silent overwrites from duplicate inferred titles; legacy title-only files are migrated/removed only when they match the same paper id/filePath.
- **Rust FFI**: Dynamically loaded via `dlopen` in Swift; graceful fallback to pure-Swift implementations
- **Swift services**: `AppModel.swift` orchestrates; services in `Services/` (PDFProcessor, EmbeddingService, LLMActors, ClaimGraph, AnalyticsStore, etc.)
- **Analytics app sync**: `rebuildAnalyticsViaPython` and `rebuildAnalyticsWithCutoffs` now run output/topic health checks after successful rebuild and expose status/log in `AnalyticsView`; manual health-check trigger available in Analytics backend card.
- **App bundle paths**: Use `AppPaths` for repo-relative roots. Proper `.app` launches do not reliably inherit the repo current working directory, so app code should not derive `Output/` or `Prompts/` directly from `FileManager.default.currentDirectoryPath`.
- **Immersive galaxy UI**: Shared visual styling lives in `Sources/LiteratureAtlas/Views/GalaxyTheme.swift`; prefer its backdrop, hero, metric, status pill, section header, and action helpers plus tinted `GlassCard` before adding one-off colors or custom card styles.
- **Knowledge Universe map**: The primary map experience is general-purpose corpus exploration and opens by default as `Universe` / `Knowledge Universe`; trading-specific filtering and ranking belong in `TradingLensView`, not the main map.
- **Knowledge Universe interaction**: Map taps select/inspect nodes in the right panel; deeper navigation is explicit from inspector actions. Paper graph nodes use adaptive labels, hover/selection expansion, canvas pan/zoom, and per-node drag offsets.
- **Sidebar navigation**: The root sidebar uses explicit full-width buttons that set `AppNavigation.selectedTab`; do not replace this with passive `List(selection:)` rows without a live click smoke because that pattern previously received clicks but did not update the detail view reliably.
- **Claim graph performance**: Full claim relation inference is corpus-scale and must not run during SwiftUI `body` evaluation or app launch. Use bounded previews for UI cards and keep full graph export off the main actor.
- **Bridge analysis performance**: `BridgingSection` must not call `influencePath`, `claimPathBetweenClusters`, or other claim graph builders from `body`; bridge search is explicit/on-demand so sidebar navigation stays responsive.
- **Swift Charts plot geometry**: Hover/tracking overlays must use guarded plot-frame dimensions/coordinates from `ChartPlotGeometry.swift`. Filled `AreaMark`s over signed/negative analytics values can produce oversized CoreAnimation paint layers; prefer bounded line charts or explicit safe domains.
- **Background progress UX**: Long-running clustering may show progress, but global overlays must not intercept normal app clicks unless the task has an enabled cancel/stop action.

## Conventions
- **Logging (Python)**: Use `logging` module, not `print()`. Logger: `_logger = logging.getLogger(__name__)`
- **Type hints (Python)**: Use native `list`, `dict` syntax (not `List`, `Dict` from typing)
- **Swift availability**: All app code requires `@available(macOS 26, iOS 26, *)`
- **JSON encoding**: Swift uses `CodingKeys` with snake_case for JSON interop with Python

## Known pitfalls / sharp edges
- Swift tests require macOS 26+ with Apple Intelligence support
- Rust FFI must be built before `swift build` (Package.swift links against it)
- Python analytics requires `Output/papers/*.paper.json` to exist (run Swift ingestion first)
- Analytics rebuild writes Parquet via pandas and requires `pyarrow` (in `analytics/requirements.txt` and `analytics/pyproject.toml`)
- The app prefers repo-local `.venv`; stale/incomplete `.venv` causes analytics rebuild failures even if system Python works
- Topic reliability audit prefers explicit cluster IDs when coverage is high, otherwise falls back to deterministic KMeans over embeddings
- Ingestion smoke test is opt-in via env vars (`LITERATURE_ATLAS_INGEST_SMOKE_*`) and `scripts/run_example_smoke.sh` sets them automatically
- `scripts/run_example_smoke.sh` computes sample-friendly topic thresholds (`min_topic_size=max(3,floor(N/3))`, `min_primary_topic_size=ceil(0.4*N)`) to avoid flaky false negatives on random `--count 10` runs
- `scipy` is optional; `linear_sum_assignment` may be `None`
- There is currently no `analytics/rust/Cargo.toml`; do not run or document Rust CLI commands unless that manifest is restored.

## Decision log
- 2026-01-12: Converted Python print() to logging module for structured output
- 2026-01-12: Added pytest and ruff configuration to pyproject.toml
- 2026-01-12: Fixed ruff linting issues (unused imports/variables, deprecated type hints)
- 2026-02-09: Added `pyarrow>=14.0.0` to analytics dependencies after rebuild failure on Parquet export (`analytics/requirements.txt`, `analytics/pyproject.toml`)
- 2026-02-09: Added `scripts/topic_focus_audit.py` + tests to enforce a pass/fail gate for reliable/searchable corpus topics after ingestion
- 2026-02-09: Added `scripts/run_example_smoke.sh` + `IngestionSmokeTests` for end-to-end 10-sample ingest validation in isolated temp output roots
- 2026-02-09: App analytics rebuild path now chains health checks and surfaces status/log in UI (`Sources/LiteratureAtlas/App/AppModel.swift`, `Sources/LiteratureAtlas/Views/AnalyticsView.swift`)
- 2026-02-09: Smoke-run primary topic threshold changed from `N/2` to `ceil(0.4*N)` to stabilize random 10-paper validation (`scripts/run_example_smoke.sh`)
- 2026-02-09: Fixed full-corpus paper loss from duplicate inferred titles by moving paper JSON to id-suffixed naming with safe legacy migration (`Sources/LiteratureAtlas/App/AppModel.swift`)
- 2026-02-09: Verified full 115-paper corpus ingest + analytics + ANN + output/topic audits all pass in repo `Output/`
- 2026-06-26: Added the immersive galaxy SwiftUI visual system and applied it to the root shell, Ingest, Q&A, Analytics hero/backend, and global progress overlay (`Sources/LiteratureAtlas/Views/GalaxyTheme.swift`, `Sources/LiteratureAtlas/Views/GlassCard.swift`)
- 2026-06-26: Removed launch-time Obsidian vault regeneration/upgrade work and made Ingest claim graph preview explicit, bounded, and asynchronous after profiling a ~190% CPU startup hang (`Sources/LiteratureAtlas/App/AppModel.swift`, `Sources/LiteratureAtlas/Views/IngestView.swift`, `Sources/LiteratureAtlas/Services/ClaimGraph.swift`)
- 2026-06-26: Made clustering progress non-blocking by preventing `GlobalProgressOverlay` from capturing clicks during clustering and running galaxy KMeans at utility priority (`Sources/LiteratureAtlas/Views/GlobalProgressOverlay.swift`, `Sources/LiteratureAtlas/App/AppModel.swift`)
- 2026-06-26: Reframed the primary map as a general `Knowledge Universe`, removed trading-specific controls from the main paper map, made Universe the default launch section, and added bounded animated starfield/nebula canvases with Reduce Motion support (`Sources/LiteratureAtlas/Views/MapView.swift`, `Sources/LiteratureAtlas/App/AppNavigation.swift`)
- 2026-06-26: Fixed Knowledge Universe graph interaction so cluster taps inspect instead of auto-navigating, paper selection drives the right inspector, paper graph nodes are labeled/draggable, and animation cadence is bounded for a responsive debug build (`Sources/LiteratureAtlas/Views/MapView.swift`)
- 2026-06-29: Added `script/build_and_run.sh` and `.codex/environments/environment.toml` as the canonical macOS app-bundle smoke path; fixed bundle-launched data loading with `AppPaths`, cleaned visible cluster labels with `DisplayText`, made the Universe inspector scrollable, replaced an unavailable project SF Symbol with standard folder symbols, and recorded the end-to-end SwiftUI polish audit in `docs/audits/polish-audit-2026-06-29.md`.
- 2026-06-29: Fixed the left sidebar click regression by replacing inert `List(selection:)` rows with explicit sidebar buttons and moving bridge paper search out of `BridgingSection.body`; process sampling showed the previous bridge section could pin the main thread at 100% CPU.
- 2026-06-29: Round-2 polish audit fixed Analytics CoreAnimation bogus layer-size warnings by clamping chart plot geometry and replacing signed factor exposure `AreaMark`s with `LineMark`s; final strict app log scan was clean (`docs/audits/polish-audit-2026-06-29-round2.md`).
