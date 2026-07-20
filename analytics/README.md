# Local Analytics Backend (Python + DuckDB + Rust FFI)

This directory houses the fully local analytics pipeline that the SwiftUI app can regenerate on demand. All reads/writes stay under `Output/`—no cloud dependencies.

## What it does
- Loads `Output/papers/*.paper.json` and `Output/chunks/chunks.json` produced by the app.
- Builds `Output/atlas.duckdb` with typed tables (papers, embeddings, chunks, claims, methods).
- Computes topic trends, novelty vs. cluster centroids, 8-NN centrality, drift, factor loadings/exposures, influence scores, recommendations, uncertainty proxy, counterfactual scenarios, and optional user-event stats from `Output/analytics/user_events.jsonl`.
- Adds higher-level offline analytics:
  - **Stability**: cluster assignment confidence/ambiguity + cohesion.
  - **Map quality**: trustworthiness/continuity + local distortion for the galaxy layout (cluster-level).
  - **Lifecycle**: burst scores, changepoint heuristics, phase labels (emerging/accelerating/mature/fading).
  - **Bridges**: topic graph betweenness/bridging-centrality + paper recombination index.
  - **Citations** (heuristic, offline): reference extraction + in-corpus matching + PageRank/in-degree when references are present in `chunks.json`.
  - **Claims**: controversy + maturity proxies from claim text similarity.
  - **Methods/datasets/metrics**: lightweight extraction + adoption curves + rigor/openness proxies.
  - **Workflow/hygiene**: coverage/blind-spots, QA gaps (from user events), duplicates + ingestion diagnostics.
- Exports Parquet snapshots and a compact `Output/analytics/analytics.json` consumed by `AnalyticsView` in the app.

## Quick start
```bash
# from repo root
uv sync --project analytics --extra dev --frozen
uv run --project analytics --extra dev --frozen python analytics/rebuild_analytics.py
# or if running from elsewhere
uv run --project analytics --extra dev --frozen \
  python analytics/rebuild_analytics.py --base /path/to/LiteratureAtlas
```

Key outputs
- `Output/atlas.duckdb` — warehouse (tables: papers, paper_embeddings, paper_chunks, claims, methods).
- `Output/analytics/*.parquet` — convenient parquet snapshots (papers, embeddings, chunks, claims, methods, plus optional extras like `paper_entities.parquet`, `ingestion_issues.parquet`, `refs.parquet`, `in_corpus_cites.parquet` when available).
- `Output/analytics/analytics.json` — summarized payload (baseline metrics plus new sections: `quality`, `stability`, `lifecycle`, `bridges`, `citations`, `claims`, `methods`, `workflow`, `hygiene`).

## Dependencies
```bash
# from the repository root; installs the exact audited lockfile
uv sync --project analytics --extra dev --frozen
```
- Runtime and development dependency versions are resolved in `analytics/uv.lock`.
- DuckDB follows the 1.4 LTS line and is pinned to its audited patch release.
- Audit the synchronized environment with `uv run --project analytics --extra dev --frozen pip-audit --local`.

## Script options (rebuild_analytics.py)
- `--base / --root` : repo root (default: script parent).
- `--db` : custom DuckDB path (default: `Output/atlas.duckdb`).
- `--counterfactual-cutoffs` : list of year thresholds for counterfactual scenarios (default: `2010 2015 2020`).

## Rust FFI
- **Swift FFI library** (`analytics/ffi`): exposes HNSW search and lightweight graph analytics.
  ```bash
  cargo build --manifest-path analytics/ffi/Cargo.toml --release
  # Headers: analytics/ffi/include/atlas_ffi.h
  # Library: analytics/ffi/target/release/libatlas_ffi.{dylib,a}
  ```
  The Swift target links against this library (see `Package.swift`).

The legacy `analytics/rust` ANN CLI is not present in this checkout. Do not run or document
`cargo run --manifest-path analytics/rust/Cargo.toml` unless that manifest is restored.

## Notebooks & extension points
- Open `Output/atlas.duckdb` in Jupyter/duckdb for custom analyses (UMAP, graph stats, topic modeling). Keep heavy experiments here; only small artifacts should flow back into `analytics.json`.
- To extend metrics, write additional Parquet/JSON files into `Output/analytics/` and reference them from the app if needed.
