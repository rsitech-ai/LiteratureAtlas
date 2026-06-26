# MEMORY

## Repo overview (languages/frameworks)
- **Swift 6 + SwiftUI** — macOS/iOS app for PDF research atlas (`Sources/LiteratureAtlas/`)
- **Python 3.10+** — Analytics pipeline with DuckDB (`analytics/`)
- **Rust** — FFI library for HNSW/graph algorithms (`analytics/ffi/`) and CLI for ANN edges (`analytics/rust/`)

## Commands

### Setup/install
- Swift build: `swift build`
- Rust FFI build: `cargo build --manifest-path analytics/ffi/Cargo.toml --release`
- Rust CLI build: `cargo build --manifest-path analytics/rust/Cargo.toml --release`
- Python env + deps: `python -m venv .venv && .venv/bin/python -m ensurepip --upgrade && .venv/bin/python -m pip install -r analytics/requirements.txt`

### Format
- Rust: `cargo fmt --manifest-path analytics/ffi/Cargo.toml` and `cargo fmt --manifest-path analytics/rust/Cargo.toml`
- Python: `python -m ruff format analytics/` (configured in pyproject.toml)

### Lint
- Python: `.venv/bin/python -m ruff check analytics/`
- Rust: `cargo clippy --manifest-path analytics/ffi/Cargo.toml` and `cargo clippy --manifest-path analytics/rust/Cargo.toml`

### Tests
- Swift: `swift test` (43 tests, typically 1 opt-in smoke test skipped without env vars; requires macOS 26+)
- Python: `.venv/bin/python -m pytest analytics/tests -v` (4 tests)
- Rust FFI: `cargo test --manifest-path analytics/ffi/Cargo.toml` (3 tests)

### Integration commands
- Analytics rebuild: `.venv/bin/python analytics/rebuild_analytics.py`
- Rust ANN CLI: `cargo run --manifest-path analytics/rust/Cargo.toml --release -- --emb Output/analytics/paper_embeddings.parquet --out Output/analytics/ann_edges.json --k 8`
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
- **Immersive galaxy UI**: Shared visual styling lives in `Sources/LiteratureAtlas/Views/GalaxyTheme.swift`; prefer its backdrop, hero, metric, status pill, section header, and action helpers plus tinted `GlassCard` before adding one-off colors or custom card styles.
- **Claim graph performance**: Full claim relation inference is corpus-scale and must not run during SwiftUI `body` evaluation or app launch. Use bounded previews for UI cards and keep full graph export off the main actor.
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
