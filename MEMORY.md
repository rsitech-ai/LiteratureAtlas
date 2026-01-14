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
- Python env + deps: `python -m venv .venv && source .venv/bin/activate && pip install -r analytics/requirements.txt`

### Format
- Rust: `cargo fmt --manifest-path analytics/ffi/Cargo.toml` and `cargo fmt --manifest-path analytics/rust/Cargo.toml`
- Python: `python -m ruff format analytics/` (configured in pyproject.toml)

### Lint
- Python: `python -m ruff check analytics/`
- Rust: `cargo clippy --manifest-path analytics/ffi/Cargo.toml` and `cargo clippy --manifest-path analytics/rust/Cargo.toml`

### Tests
- Swift: `swift test` (42 tests, requires macOS 26+)
- Python: `python -m pytest analytics/tests -v` (2 tests)
- Rust FFI: `cargo test --manifest-path analytics/ffi/Cargo.toml` (3 tests)

### Integration commands
- Analytics rebuild: `python analytics/rebuild_analytics.py`
- Rust ANN CLI: `cargo run --manifest-path analytics/rust/Cargo.toml --release -- --emb Output/analytics/paper_embeddings.parquet --out Output/analytics/ann_edges.json --k 8`

## Architecture notes
- **Data flow**: PDF → Swift app (summarization, embeddings) → `Output/papers/*.paper.json` → Python analytics → `Output/analytics/analytics.json` → Swift app reloads
- **Output directory**: All artifacts under `Output/` (papers, chunks, clusters, analytics, reports, obsidian)
- **Rust FFI**: Dynamically loaded via `dlopen` in Swift; graceful fallback to pure-Swift implementations
- **Swift services**: `AppModel.swift` orchestrates; services in `Services/` (PDFProcessor, EmbeddingService, LLMActors, ClaimGraph, AnalyticsStore, etc.)

## Conventions
- **Logging (Python)**: Use `logging` module, not `print()`. Logger: `_logger = logging.getLogger(__name__)`
- **Type hints (Python)**: Use native `list`, `dict` syntax (not `List`, `Dict` from typing)
- **Swift availability**: All app code requires `@available(macOS 26, iOS 26, *)`
- **JSON encoding**: Swift uses `CodingKeys` with snake_case for JSON interop with Python

## Known pitfalls / sharp edges
- Swift tests require macOS 26+ with Apple Intelligence support
- Rust FFI must be built before `swift build` (Package.swift links against it)
- Python analytics requires `Output/papers/*.paper.json` to exist (run Swift ingestion first)
- `scipy` is optional; `linear_sum_assignment` may be `None`

## Decision log
- 2026-01-12: Converted Python print() to logging module for structured output
- 2026-01-12: Added pytest and ruff configuration to pyproject.toml
- 2026-01-12: Fixed ruff linting issues (unused imports/variables, deprecated type hints)
