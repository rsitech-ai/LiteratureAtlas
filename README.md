# LiteratureAtlas

## 1. Project Title & One-Sentence Tagline
- **LiteratureAtlas** — on-device SwiftUI atlas that ingests your research PDFs, summarizes them locally, clusters the ideas, and serves interactive maps, Q&A, and analytics without sending data to the cloud.

## 2. High-Level Overview
- The app reads PDFs, uses Apple’s on-device `LanguageModelSession` and `NLContextualEmbedding` to summarize and embed text, then builds a multi-scale “knowledge galaxy” for exploration.
- A local analytics pipeline (Python + DuckDB + optional Rust helpers) computes topic trends, novelty, centrality, drift, factor exposures, and recommendations consumed by the SwiftUI dashboard.
- Primary stack: **Swift 6 + SwiftUI + PDFKit + NaturalLanguage + FoundationModels** for the app, **Python 3.10+ + DuckDB + pandas/numpy + scikit-learn** for analytics, and **Rust (cargo)** for ANN/graph acceleration.

## 3. Architecture & Key Components
- **Data flow**: PDF ingestion → on-device summarization & chunk embeddings → JSON in `Output/papers` & `Output/chunks` → clustering & galaxy layout → optional Python/Rust analytics → `analytics.json` reloaded by the app → interactive views (Map, Q&A, Analytics).
- **Swift app (`Sources/LiteratureAtlas/`)**
  - `App/AppModel.swift`: central state machine for ingestion, clustering, RAG Q&A, recommendations, analytics reloads, and event logging.
  - `Services/`: 
    - `PDFProcessor.swift` (PDF text/metadata extraction), `EmbeddingService.swift` (sentence embeddings + KMeans), `VectorIndex.swift` (in-process similarity search fallback), `LLMActors.swift` (summaries, cluster naming, Q&A), `ClaimGraph.swift` (claim extraction/relations/stress tests), `TemporalAnalytics.swift` (novelty, drift, panel/debate simulators), `AnalyticsStore.swift` (loads Python-generated `analytics.json`), `AtlasFFI.swift` (HNSW/graph FFI loader).
  - `Views/`: `IngestView`, `MapView`, `QuestionView`, `AnalyticsView`, `PaperDetailView`, `GlobalProgressOverlay`, etc.
- **Analytics backend (`analytics/`)**
  - `rebuild_analytics.py`: loads app outputs, writes `Output/atlas.duckdb`, Parquet snapshots, and `Output/analytics/analytics.json` (baseline metrics plus quality/stability/lifecycle/bridges/citations/claims/methods/workflow/hygiene sections).
  - `requirements.txt` / `pyproject.toml`: Python dependencies.
  - `rust/`: CLI that builds ANN edges from Parquet embeddings using Polars (see `analytics/rust/src/main.rs`).
  - `ffi/`: Rust `cdylib/staticlib` exposing HNSW search and basic graph analytics to Swift (`analytics/ffi/src/lib.rs`, headers in `analytics/ffi/include/`).
- **Data**: all persistent artifacts live under `Output/` (papers, chunks, clusters, analytics parquet/JSON, DuckDB) to keep the app self-contained.

## 4. Features
- Local PDF ingestion with first-pages text extraction, title/year inference, and on-device bullet summaries (no network calls) — `IngestView`, `PDFProcessor`, `LLMActors.PaperSummarizerActor`.
- Chunked embeddings for RAG and Q&A; fallback hashing embeddings if on-device model is unavailable — `AppModel.buildChunks`, `EmbeddingService`.
- Multi-scale clustering and force-directed layout (“Knowledge Galaxy”) with lenses for time, methods, data regime, and personal interest — `AppModel.buildMultiScaleGalaxy`, `MapView`.
- Claim graph construction, relation inference (supports/extends/contradicts), assumption stress tests, and blueprint generation for methods — `ClaimGraph.swift`, `IngestView` cards.
- Reading planner: recommendations, blind spots, adaptive curriculum, flashcards, daily quiz, and knowledge snapshots — `AppModel.recommendedNextPapers`, `adaptiveCurriculum`, `dailyQuizCards`.
- Corpus-level synthesis: generate an executive “corpus briefing” from the current topic hierarchy (cached to `Output/reports/`) — `AppModel.generateCorpusBriefing`, `LLMActors.CorpusBriefingActor`.
- Topic dossiers: generate a structured briefing for any selected cluster (cached to `Output/reports/`) — `AppModel.loadOrGenerateTopicDossier`, `LLMActors.TopicDossierActor`.
- Analytics dashboard fed by Python outputs: topic trends, novelty/consensus, drift, factors, influence + newer trust/stability/lifecycle/bridge/citation/workflow signals — `AnalyticsView`, `analytics/rebuild_analytics.py`.
- Optional Rust acceleration: HNSW ANN + graph metrics via `analytics/ffi` (linked into the Swift target) and a standalone Polars-based ANN graph builder in `analytics/rust`.
- Event logging to `Output/analytics/user_events.jsonl` for later aggregation (questions asked, answers ready, papers opened).

## 5. Getting Started
- **Prerequisites**
- Swift toolchain 6.0+, Xcode 16+ recommended; macOS 26 (or iOS/iPadOS 26) with on-device FoundationModels + NLContextualEmbedding support.
  - Rust toolchain (stable) for `analytics/ffi` and `analytics/rust` builds.
  - Python 3.10+ with `pip` or `uv`; dependencies in `analytics/requirements.txt`.
  - Apple Silicon strongly recommended for on-device models.
- **Installation**
  ```bash
  git clone <repo-url> LiteratureAtlas
  cd LiteratureAtlas
  # Build Rust FFI used by the Swift target (produces libatlas_ffi.{dylib,a} in analytics/ffi/target/release)
  cargo build --manifest-path analytics/ffi/Cargo.toml --release
  # Optional: build Rust ANN CLI
  cargo build --manifest-path analytics/rust/Cargo.toml --release
  # Python env for analytics
  python -m venv .venv && source .venv/bin/activate
  pip install -r analytics/requirements.txt
  # Swift dependencies are bundled; build the app
  swift build
  ```
- **Configuration**
  - Data is written to `Output/` beside the repo; folders (`papers`, `chunks`, `clusters`, `analytics`, `reports`, `obsidian/papers`) are created automatically.
  - Prompt templates live in `Prompts/` (override path via `LITERATURE_ATLAS_PROMPTS_DIR`); edit them to iterate on prompts without touching Swift code.
  - On macOS, the Analytics screen can install Python deps and run the rebuild; it prefers a repo-local `.venv` when present.
  - App-side analytics rebuild/recompute actions also run output + topic health checks and surface the latest health-check status/log in the Analytics backend card.
  - Override the Python interpreter used by the app via `LITERATURE_ATLAS_PYTHON` (e.g. `.venv/bin/python3`).
  - Analytics script flags: `--base /path/to/repo`, `--db <path>`, `--counterfactual-cutoffs 2010 2015 2020` (see `analytics/rebuild_analytics.py`).
  - The Swift target links against `analytics/ffi/target/release`; ensure the library exists before running `swift run`/`swift build`.
  - Optional user events: the app appends newline-delimited JSON to `Output/analytics/user_events.jsonl`.

## 6. Running the Project
- **Development (macOS)**
  ```bash
  # With FFI already built
  swift run LiteratureAtlas
  ```
  - Launches the SwiftUI app; use “Select Folder of PDFs” in the Ingest tab to start processing.
- **iPadOS**
- Open the package in Xcode 16+, select an iOS/iPadOS 26+ device/simulator with Apple Intelligence support, and run the `LiteratureAtlas` target. Ensure `analytics/ffi` is built for the target architecture.
- **Analytics pipeline (optional but recommended)**
  ```bash
  source .venv/bin/activate  # if using venv
  python analytics/rebuild_analytics.py            # rebuild DuckDB + analytics.json from Output/
  python analytics/rebuild_analytics.py --base ..  # if running from a subdir
  cargo run --manifest-path analytics/rust/Cargo.toml --release -- \
    --emb Output/analytics/paper_embeddings.parquet \
    --out Output/analytics/ann_edges.json --k 8
  ```
- **Production / release build**
  ```bash
  swift build -c release
  # Bundle libatlas_ffi.dylib next to the executable or in a Frameworks folder if redistributing.
  ```
- **CLI usage quick reference**
  - Rebuild analytics: `python analytics/rebuild_analytics.py [--base PATH] [--counterfactual-cutoffs ...]`
  - ANN edges (Rust): `cargo run --manifest-path analytics/rust/Cargo.toml --release -- --emb Output/analytics/paper_embeddings.parquet --out Output/analytics/ann_edges.json --k 8`
  - Topic reliability audit: `.venv/bin/python scripts/topic_focus_audit.py --base .`
  - 10-paper integrated smoke run: `scripts/run_example_smoke.sh --count 10`

## 7. Testing & QA
- Swift tests (macOS 26+/Swift 6 required):
  ```bash
  swift test
  ```
  - Covers ingestion upsert logic, clustering assignments, PDF year inference, claim extraction/relations/stress tests, vector index, galaxy math, analytics store, and temporal analytics (`Tests/LiteratureAtlasTests/*`).
- Python analytics checks:
  - End-to-end rebuild: `python analytics/rebuild_analytics.py`
  - Unit tests: `python -m unittest discover -s analytics/tests`
  - Topic reliability gate: `.venv/bin/python scripts/topic_focus_audit.py --base .` (non-zero exit means no reliable/searchable topic slice passed thresholds)
- Full sample ingest+validate smoke run:
  - `scripts/run_example_smoke.sh --count 10`
  - Samples random PDFs from `examples/`, ingests them via an opt-in test path, and runs analytics + artifact/topic audits on an isolated temp output root.
- Rust crates have minimal logic and can be checked with `cargo test` (none defined) or `cargo fmt --check` if desired.

## 8. Module-Level Documentation (Compact)
- `AppModel` — orchestrates ingestion, embeddings, clustering, RAG Q&A, analytics reloads, recommendations, flashcards, and event logging.
- `Services/`
  - `PDFProcessor` (text/title/year/page extraction), `EmbeddingService` (NLContextualEmbedding + KMeans), `VectorIndex` (cosine search), `LLMActors` (summary/Q&A actors), `ClaimGraph` (claims, relations, stress tests), `TemporalAnalytics` (novelty, drift, simulations), `AnalyticsStore` (decode `analytics.json`), `AtlasFFI` (Rust HNSW bindings).
- `Views/`
  - `IngestView` (ingestion/logs/planner/claims), `MapView` (galaxy with lenses, zoom, bridging), `QuestionView` (RAG Q&A + evidence), `AnalyticsView` (trends, drift, factor exposures, counterfactuals), `PaperDetailView` (notes/tags/status).
- `analytics/rebuild_analytics.py` — DuckDB load + novelty/centrality/drift/factors/recs export; writes Parquet snapshots and `analytics.json`.
- `analytics/ffi` — HNSW ANN and graph utilities exposed to Swift via `include/atlas_ffi.h`.
- `analytics/rust` — standalone ANN graph CLI writing `ann_edges.json`.
- `examples/` — sample PDFs for local testing; `Output/` holds generated artifacts and sample precomputed data.

## 9. Data & Storage
- `Output/papers/*.paper.json` — per-paper metadata, summaries, embeddings, claims, method pipeline, timestamps.
- `Output/obsidian/papers/*.md` — Obsidian-friendly per-paper notes (auto-managed block + a preserved `## Notes` section).
- `Output/chunks/chunks.json` — chunk-level text + embeddings for RAG.
- `Output/clusters/*.json` — cached cluster layouts/snapshots.
- `Output/atlas.duckdb` — DuckDB database built by analytics script; Parquet snapshots in `Output/analytics/*.parquet`.
- `Output/analytics/analytics.json` — compact analytics payload the app reloads (baseline metrics plus quality/stability/lifecycle/bridges/citations/claims/methods/workflow/hygiene sections).
- `Output/analytics/user_events.jsonl` — optional event log appended by the app (qa_question, qa_ready, paper_opened, rec_feedback).
- `Output/reports/corpus_briefing_<version>.md` — cached corpus-level executive briefing generated on-device from the current topic hierarchy.
- `Output/reports/topic_<clusterID>_dossier_<version>.md` — cached per-topic dossier generated on-device from a cluster + representative papers.
- All paths are local; no remote storage.

## 10. Deployment & Environments
- No Docker/Helm manifests provided; distribute as a SwiftPM/Xcode app. Ensure `libatlas_ffi` ships with the binary (or adjust `Package.swift` linker flags to your install path).
- macOS build links `atlas_ffi` from `analytics/ffi/target/release` (see `Package.swift`); rebuild the Rust lib per architecture before shipping.
- iOS builds default to the Swift fallback (no FFI). To enable FFI on iOS, add iOS linker settings and define `ATLAS_FFI_LINKED` for iOS in `Package.swift` after building a static library.

## 11. Security & Permissions
- All processing is offline: PDFs stay local, summaries/embeddings use on-device models, and analytics run locally.
- The app confines writes to the repo-relative `Output/` directory and uses security-scoped resource access when importing folders.

## 12. Roadmap / TODO
- No explicit roadmap or TODO files are present in this repository; add issues or docs to track future work (e.g., alternative ANN backends, packaging automation).

## 13. Contributing
- Suggested workflow: fork → create branch → build `analytics/ffi` → make changes → run `swift test` (and analytics script if relevant) → open PR.
- Keep new data outputs inside `Output/` and avoid committing large binaries unless necessary.

## 14. License
- MIT License (see `LICENSE`).
