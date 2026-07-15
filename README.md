# LiteratureAtlas

## 1. Project Title & One-Sentence Tagline
- **LiteratureAtlas** — macOS-first SwiftUI atlas that ingests research PDFs and Markdown notes, compiles traceable local knowledge artifacts, clusters ideas, and serves interactive maps, Q&A, and analytics.

## 2. High-Level Overview
- The app reads PDFs and Markdown sources, extracts citation-aware sections, uses Apple’s on-device `LanguageModelSession` for compilation/summarization, and builds a multi-scale “knowledge galaxy” for exploration.
- A local developer analytics pipeline (Python + DuckDB + optional Rust helpers) computes topic trends, novelty, centrality, drift, factor exposures, and recommendations consumed by the SwiftUI dashboard. App Store products are self-contained and do not execute that external toolchain at runtime.
- Primary stack: **Swift 6 + SwiftUI + PDFKit + NaturalLanguage + FoundationModels** for the app, **Python 3.10+ + DuckDB + pandas/numpy + scikit-learn** for analytics, and **Rust (cargo)** for ANN/graph acceleration.

## 3. Architecture & Key Components
- **Data flow**: document ingestion (PDF + Markdown) → citation-aware extraction → compiler pass + chunk embeddings → JSON in `Output/papers`, `Output/documents`, and `Output/chunks` → compiled Markdown + graph export → clustering & galaxy layout → optional Python/Rust analytics → `analytics.json` reloaded by the app → interactive views (Map, Q&A, Analytics).
- **Swift app (`Sources/LiteratureAtlas/`)**
  - `App/AppModel.swift`: central state machine for ingestion, clustering, RAG Q&A, recommendations, analytics reloads, and event logging.
  - `Services/`: 
    - `PDFProcessor.swift` + `MarkdownProcessor.swift` (mixed-corpus extraction + anchors), `DocumentCompilerProvider.swift` (on-device/OpenAI compiler seam), `CompiledKnowledgeExporter.swift` (document/topic/entity Markdown), `DocumentGraphExporter.swift` (typed graph JSON), `EmbeddingService.swift` (sentence embeddings + KMeans), `VectorIndex.swift` (in-process similarity search fallback), `LLMActors.swift` (cluster naming, Q&A), `ClaimGraph.swift` (claim extraction/relations/stress tests), `TemporalAnalytics.swift` (novelty, drift, panel/debate simulators), `AnalyticsStore.swift` (loads Python-generated `analytics.json`), `AtlasFFI.swift` (HNSW/graph FFI loader).
  - `Views/`: `IngestView`, `MapView`, `QuestionView`, `AnalyticsView`, `PaperDetailView`, `GlobalProgressOverlay`, etc.
- **Analytics backend (`analytics/`)**
  - `rebuild_analytics.py`: loads app outputs, writes `Output/atlas.duckdb`, Parquet snapshots, and `Output/analytics/analytics.json` (baseline metrics plus quality/stability/lifecycle/bridges/citations/claims/methods/workflow/hygiene sections).
  - `requirements.txt` / `pyproject.toml`: Python dependencies.
  - `ffi/`: Rust `cdylib/staticlib` exposing HNSW search and basic graph analytics to Swift (`analytics/ffi/src/lib.rs`, headers in `analytics/ffi/include/`).
- **Data**: all persistent artifacts live under `Output/` (papers, documents, chunks, compiled Markdown, graph, clusters, analytics parquet/JSON, DuckDB) to keep the app self-contained.

## 4. Features
- Mixed PDF + Markdown ingestion with citation anchors, checksums, unified document records, and compiler-backed summaries — `IngestView`, `PDFProcessor`, `MarkdownProcessor`, `AppModel`.
- First-class compiled knowledge artifacts: per-document notes, topic briefs, entity pages, and typed graph export under `Output/compiled` and `Output/graph`.
- Chunked embeddings for RAG and Q&A; fallback hashing embeddings if on-device model is unavailable — `AppModel.buildChunks`, `EmbeddingService`.
- Multi-scale clustering and force-directed layout (“Knowledge Galaxy”) with lenses for time, methods, data regime, and personal interest — `AppModel.buildMultiScaleGalaxy`, `MapView`.
- Claim graph construction, relation inference (supports/extends/contradicts), assumption stress tests, and blueprint generation for methods — `ClaimGraph.swift`, `IngestView` cards.
- Reading planner: recommendations, blind spots, adaptive curriculum, flashcards, daily quiz, and knowledge snapshots — `AppModel.recommendedNextPapers`, `adaptiveCurriculum`, `dailyQuizCards`.
- Corpus-level synthesis: generate an executive “corpus briefing” from the current topic hierarchy (cached to `Output/reports/`) — `AppModel.generateCorpusBriefing`, `LLMActors.CorpusBriefingActor`.
- Topic dossiers: generate a structured briefing for any selected cluster (cached to `Output/reports/`) — `AppModel.loadOrGenerateTopicDossier`, `LLMActors.TopicDossierActor`.
- Analytics dashboard fed by Python outputs: topic trends, novelty/consensus, drift, factors, influence + newer trust/stability/lifecycle/bridge/citation/workflow signals — `AnalyticsView`, `analytics/rebuild_analytics.py`.
- Optional Rust acceleration: HNSW ANN + graph metrics via `analytics/ffi` (linked into the Swift target).
- Event logging to `Output/analytics/user_events.jsonl` for later aggregation (questions asked, answers ready, papers opened).

## 5. Getting Started
- **Prerequisites**
- Swift toolchain 6.0+, Xcode 26+; macOS 26 or iPadOS 26 with on-device FoundationModels + NLContextualEmbedding support.
  - Rust toolchain (stable) for `analytics/ffi` builds.
  - Python 3.10+ with `pip` or `uv`; dependencies in `analytics/requirements.txt`.
  - Apple Silicon strongly recommended for on-device models.
- **Installation**
  ```bash
  git clone <repo-url> LiteratureAtlas
  cd LiteratureAtlas
  # Build Rust FFI used by the Swift target (produces libatlas_ffi.{dylib,a} in analytics/ffi/target/release)
  cargo build --manifest-path analytics/ffi/Cargo.toml --release
  # Python env for analytics
  python -m venv .venv && source .venv/bin/activate
  pip install -r analytics/requirements.txt
  # Swift dependencies are bundled; build the app
  swift build
  ```
- **Configuration**
  - Data is written to `Output/` beside the repo; folders (`papers`, `documents`, `chunks`, `compiled`, `graph`, `clusters`, `analytics`, `reports`, `obsidian/papers`) are created automatically.
  - Prompt templates live in `Prompts/` (override path via `LITERATURE_ATLAS_PROMPTS_DIR`); edit them to iterate on prompts without touching Swift code.
  - Compiler backend selection:
    - current production mode is on-device compilation only
    - `LITERATURE_ATLAS_COMPILER_PROVIDER=openai` is ignored and falls back to on-device compilation because a supported standalone OAuth/Codex auth flow is not available here
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
  - Launches the SwiftUI app; use “Select Folder of Documents” in the Ingest tab to process PDFs and Markdown notes.
- **iPadOS**
- Run `xcodegen generate`, open `LiteratureAtlas.xcodeproj`, then select the shared `LiteratureAtlas-iOS` scheme and an iPadOS 26+ device/simulator with Apple Intelligence support. Version 1.0.0 is iPad-only; iPhone is not a shipping device family.
- **Analytics pipeline (optional but recommended)**
  ```bash
  source .venv/bin/activate  # if using venv
  python analytics/rebuild_analytics.py            # rebuild DuckDB + analytics.json from Output/
  python analytics/rebuild_analytics.py --base ..  # if running from a subdir
  ```
- **Production / release build**
  ```bash
  xcodegen generate
  xcodebuild -project LiteratureAtlas.xcodeproj -scheme LiteratureAtlas-macOS -configuration Release -destination 'generic/platform=macOS' CODE_SIGNING_ALLOWED=NO build
  xcodebuild -project LiteratureAtlas.xcodeproj -scheme LiteratureAtlas-iOS -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
  ```
  App Store builds use the pure-Swift/on-device runtime boundary: external Python execution, repository-relative Rust loading, and the dormant OpenAI provider are compile-time excluded.
- **CLI usage quick reference**
  - Rebuild analytics: `python analytics/rebuild_analytics.py [--base PATH] [--counterfactual-cutoffs ...]`
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
- The Rust FFI crate has three tests and strict gates: `cargo fmt --manifest-path analytics/ffi/Cargo.toml --check`, `cargo clippy --manifest-path analytics/ffi/Cargo.toml --all-targets --all-features -- -D warnings`, and `cargo test --manifest-path analytics/ffi/Cargo.toml`.

## 8. Module-Level Documentation (Compact)
- `AppModel` — orchestrates ingestion, embeddings, clustering, RAG Q&A, analytics reloads, recommendations, flashcards, and event logging.
- `Services/`
  - `PDFProcessor` + `MarkdownProcessor` (document extraction + citation anchors), `DocumentCompilerProvider` (compiler seam, currently local-only), `CompiledKnowledgeExporter` (document/topic/entity markdown), `DocumentGraphExporter` (typed graph snapshot), `EmbeddingService` (NLContextualEmbedding + KMeans), `VectorIndex` (cosine search), `LLMActors` (Q&A and synthesis actors), `ClaimGraph` (claims, relations, stress tests), `TemporalAnalytics` (novelty, drift, simulations), `AnalyticsStore` (decode `analytics.json`), `AtlasFFI` (Rust HNSW bindings).
- `Views/`
  - `IngestView` (ingestion/logs/planner/claims), `MapView` (galaxy with lenses, zoom, bridging), `QuestionView` (RAG Q&A + evidence), `AnalyticsView` (trends, drift, factor exposures, counterfactuals), `PaperDetailView` (notes/tags/status).
- `analytics/rebuild_analytics.py` — DuckDB load + novelty/centrality/drift/factors/recs export; writes Parquet snapshots and `analytics.json`.
- `analytics/ffi` — HNSW ANN and graph utilities exposed to Swift via `include/atlas_ffi.h`.
- `examples/` — sample PDFs for local testing; `Output/` holds generated artifacts and sample precomputed data.

## 9. Data & Storage
- `Output/papers/*.paper.json` — per-paper metadata, summaries, embeddings, claims, method pipeline, timestamps.
- `Output/documents/*.document.json` — unified per-document records for PDFs and Markdown sources.
- `Output/obsidian/papers/*.md` — Obsidian-friendly per-paper notes (auto-managed block + a preserved `## Notes` section).
- `Output/chunks/chunks.json` — chunk-level text + embeddings for RAG.
- `Output/compiled/documents/*.md`, `Output/compiled/topics/*.md`, `Output/compiled/entities/*.md` — compiled knowledge-base artifacts generated from the current corpus.
- `Output/graph/corpus_graph.json` — typed document/topic/entity/compiled-note graph for visualization and downstream tooling.
- `Output/clusters/*.json` — cached cluster layouts/snapshots.
- `Output/atlas.duckdb` — DuckDB database built by analytics script; Parquet snapshots in `Output/analytics/*.parquet`.
- `Output/analytics/analytics.json` — compact analytics payload the app reloads (baseline metrics plus quality/stability/lifecycle/bridges/citations/claims/methods/workflow/hygiene sections).
- `Output/analytics/user_events.jsonl` — optional event log appended by the app (qa_question, qa_ready, paper_opened, rec_feedback).
- `Output/reports/corpus_briefing_<version>.md` — cached corpus-level executive briefing generated on-device from the current topic hierarchy.
- `Output/reports/topic_<clusterID>_dossier_<version>.md` — cached per-topic dossier generated on-device from a cluster + representative papers.
- All paths are local; no remote storage. SwiftPM developer runs use repo-local `Output/`. App Store products use `Application Support/LiteratureAtlas/Output` inside the application container and bundle immutable prompts as resources.

## 10. Deployment & Environments
- No Docker/Helm manifests are provided. App Store products are generated from `project.yml`; SwiftPM remains the developer/test workflow.
- SwiftPM macOS builds can use `atlas_ffi` from `analytics/ffi/target/release`. App Store products intentionally use the Swift fallback until an embedded, reproducibly signed FFI artifact is introduced.

## 11. Security & Permissions
- App Store processing is local: PDFs and Markdown sources stay on device, compilation/summaries use on-device models, and no telemetry or remote model endpoint is packaged.
- macOS App Store builds use App Sandbox with read-only user-selected file access. Selected folder scope is opened before enumeration; derived writes stay in the app container.
- See `docs/release/1.0.0/PRIVACY_DATA_MAP.md` and `docs/release/1.0.0/SECURITY_STATUS.md` for the release boundary and remaining owner attestations.

## 12. Roadmap / TODO
- Task-local release work is tracked in `PLAN.md` and `TODO.md`; durable project commands and decisions live in `MEMORY.md`.

## 13. Contributing
- Suggested workflow: fork → create branch → build `analytics/ffi` → make changes → run `swift test` (and analytics script if relevant) → open PR.
- Keep new data outputs inside `Output/` and avoid committing large binaries unless necessary.

## 14. License
- MIT License (see `LICENSE`).
