# MEMORY

## Repo overview (languages/frameworks)
- **Swift 6 + SwiftUI** — macOS/iOS app for PDF research atlas (`Sources/LiteratureAtlas/`)
- **Python 3.12+** — Analytics pipeline with DuckDB (`analytics/`)
- **Rust** — FFI library for HNSW/graph algorithms (`analytics/ffi/`)

## Commands

### Setup/install
- Swift build: `swift build`
- Generate Xcode project: `xcodegen generate --spec project.yml` (XcodeGen 2.45.4; `project.yml` is the source of truth)
- Rust FFI build: `cargo build --locked --manifest-path analytics/ffi/Cargo.toml --release`
- Python env + deps: `uv sync --project analytics --extra dev --frozen` (environment: `analytics/.venv`)
- macOS app bundle run/smoke: `./script/build_and_run.sh --verify`

### Format
- Rust: `cargo fmt --manifest-path analytics/ffi/Cargo.toml`
- Python: `analytics/.venv/bin/python -m ruff format analytics scripts` (configured in `analytics/pyproject.toml`)

### Lint
- Python: `analytics/.venv/bin/python -m ruff check analytics scripts`
- Rust: `cargo clippy --locked --manifest-path analytics/ffi/Cargo.toml --all-targets --all-features -- -D warnings`

### Tests
- Swift: `swift test -Xswiftc -warnings-as-errors` (84 XCTest cases, typically 1 opt-in smoke skipped, plus 4 Swift Testing bookmark cases; requires macOS 26+)
- Python: `analytics/.venv/bin/python -m pytest analytics/tests -v` (55 tests)
- Rust FFI: `cargo test --locked --manifest-path analytics/ffi/Cargo.toml` (7 tests)
- Release configuration: `python3 scripts/validate_release_configuration.py` (fails closed until approved AppIcon artwork is committed)
- Known-blocker CI gate: `python3 scripts/validate_release_configuration.py --allow-blocker app_icon_artwork` (fails on every other gate)
- Release script policy: `scripts/tests/test_release_scripts.sh`
- Community app: `script/build_community.sh --product-name LiteratureAtlasCommunity --bundle-id io.github.s1korrrr.LiteratureAtlasCommunity --version 1.0.0 --build 1 --output dist/community`
- Community DMG: `script/create_dmg.sh --app dist/community/LiteratureAtlasCommunity.app --output dist/community/LiteratureAtlasCommunity-1.0.0.dmg --volume-name LiteratureAtlasCommunity`, then `script/verify_distribution.sh --app dist/community/LiteratureAtlasCommunity.app --dmg dist/community/LiteratureAtlasCommunity-1.0.0.dmg --mode community`
- Official pre-sign app: `script/build_official.sh --product-name LiteratureAtlas --bundle-id "$OFFICIAL_BUNDLE_ID" --version "$VERSION" --build "$BUILD_NUMBER" --output dist/official`
- Unsigned macOS archive: `xcodebuild -project LiteratureAtlas.xcodeproj -scheme LiteratureAtlas-macOS -configuration Release -archivePath /tmp/LiteratureAtlas-macOS.xcarchive CODE_SIGNING_ALLOWED=NO archive`
- Unsigned iPadOS archive: `xcodebuild -project LiteratureAtlas.xcodeproj -scheme LiteratureAtlas-iOS -configuration Release -destination 'generic/platform=iOS' -archivePath /tmp/LiteratureAtlas-iPadOS.xcarchive CODE_SIGNING_ALLOWED=NO archive`

### Integration commands
- Analytics rebuild: `analytics/.venv/bin/python analytics/rebuild_analytics.py`
- Output artifact audit: `analytics/.venv/bin/python scripts/audit_output_artifacts.py`
- Topic reliability audit: `analytics/.venv/bin/python scripts/topic_focus_audit.py --base .`
- Integrated sample smoke run: `scripts/run_example_smoke.sh --source /path/to/authorized/pdfs --count 10`
- Full corpus ingest gate: set `LITERATURE_ATLAS_INGEST_SMOKE_INPUT_DIR` to an authorized local corpus; the repository intentionally contains no sample PDFs.

## Architecture notes
- **Data flow**: PDF → Swift app (summarization, embeddings) → `Output/papers/*.paper.json` → Python analytics → `Output/analytics/analytics.json` → Swift app reloads
- **Output directory**: All artifacts under `Output/` (papers, chunks, clusters, analytics, reports, obsidian)
- **Paper JSON naming**: `savePaperJSON` writes id-suffixed filenames (`<title> [<UUID>].paper.json`) to prevent silent overwrites from duplicate inferred titles; legacy title-only files are migrated/removed only when they match the same paper id/filePath.
- **Rust FFI**: Dynamically loaded via `dlopen` in Swift; graceful fallback to pure-Swift implementations
- **Rust FFI ABI**: HNSW query calls use the versioned `atlas_query_index_v2` symbol, carry the query length across C/Swift/Rust, validate length/null/finite boundaries, and contain Rust panics before the foreign boundary. Versioning makes a cached legacy four-argument dylib fail lookup and use the Swift fallback instead of invoking an incompatible ABI.
- **Ingestion transaction**: Build paper/chunk candidates without mutating `AppModel`; persist the next canonical chunk index and paper JSON before publishing either to memory. A failed canonical write publishes neither object and rolls the chunk index back.
- **Managed Python boundary**: Contributor analytics uses only an explicit `LITERATURE_ATLAS_PYTHON` override or the frozen `analytics/.venv` interpreter. A missing or nonzero managed interpreter fails closed and is never replayed under brew/system/PATH Python.
- **Saved-paper loading**: Deduplicate canonical candidates by freshness before deriving the deterministic modal embedding dimension; stale duplicates must not mutate global embedding shape. Topic-focus audit must use the same newest-export-wins rule for duplicate paper IDs.
- **Ingest checksum validation**: Source-file I/O and incremental SHA-256 hashing must run off `AppModel`'s main actor; use bounded reads that check cancellation between chunks, then await only the result for skip-state publication.
- **Swift services**: `AppModel.swift` orchestrates; services in `Services/` (PDFProcessor, EmbeddingService, LLMActors, ClaimGraph, AnalyticsStore, etc.)
- **Analytics app sync**: `rebuildAnalyticsViaPython` and `rebuildAnalyticsWithCutoffs` now run output/topic health checks after successful rebuild and expose status/log in `AnalyticsView`; manual health-check trigger available in Analytics backend card.
- **App bundle paths**: Use `AppPaths` for repo-relative roots. Proper `.app` launches do not reliably inherit the repo current working directory, so app code should not derive `Output/` or `Prompts/` directly from `FileManager.default.currentDirectoryPath`.
- **Distributed product boundary**: Xcode app targets compile with `DISTRIBUTED_APP_BUILD`. They store mutable artifacts under container Application Support, bundle prompts, exclude external Python execution and dormant OpenAI networking, and disable repository-relative Rust FFI loading in favor of the Swift fallback.
- **Persistent source access**: Distributed macOS ingest stores app-scoped read-only bookmarks outside exported paper JSON, activates the picker scope while creating them, resolves/refreshes them, and holds the resolved scope for the full async ingest task and later source-document opens.
- **Cross-platform source access**: Durable source bookmarks use macOS security-scoped read-only options and iOS minimal bookmark options; resolution refreshes stale bookmarks and source-open failures remain visible to the user.
- **Derived analytics boundary**: `AnalyticsStore` rejects duplicate identifiers, non-finite values, every decoded UUID-bearing reference to an unknown canonical paper, and summaries whose paper count differs from the canonical library. Stale analytics must remain unavailable with an actionable rebuild message rather than being partially mixed into current UI.
- **Python paper-import boundary**: `load_papers` validates canonical hyphenated UUID paper identifiers while preserving their Swift-exported casing for cross-artifact joins, normalizes nested method-pipeline steps before downstream analytics, and sizes claim-neighbor queries from the filtered valid-claim population rather than raw input rows.
- **Persistence publication rule**: Pin, rename, flashcard-review, paper/chunk, and research-project state is published to memory only after the canonical write succeeds; failures preserve the previous state and expose `persistenceError`.
- **Direct-download scope**: the first direct macOS artifact is Apple Silicon (`arm64`) on macOS 26+. The iPad-only iPadOS 26+ target remains a development/App Store lane, not part of the direct-download artifact. Community prerelease `v1.0.0-community.1` targets merge commit `95d0031a0ee67a9f91cd0d915de75e1f42137daa`, is ad-hoc signed/not notarized, and is published at `https://github.com/s1korrrr/LiteratureAtlas/releases/tag/v1.0.0-community.1`; DMG SHA-256 is `3337c297f3e0f9492795f9bae395a82aad63a00613e156a948e27e04eca5a691`.
- **Download checksum boundary**: `release_write_sha256_file` writes the checksum atomically beside the artifact with a basename-only entry and terminates option parsing for leading-dash paths. Both DMG creation and the post-stapling notarization path must use it so a downloaded `.dmg` and `.sha256` verify from any directory.
- **Immersive galaxy UI**: Shared visual styling lives in `Sources/LiteratureAtlas/Views/GalaxyTheme.swift`; prefer its backdrop, hero, metric, status pill, section header, and action helpers plus tinted `GlassCard` before adding one-off colors or custom card styles.
- **Knowledge Universe map**: The primary map experience is general-purpose corpus exploration and opens by default as `Universe` / `Knowledge Universe`; trading-specific filtering and ranking belong in `TradingLensView`, not the main map.
- **Knowledge Universe interaction**: Map taps select/inspect nodes in the right panel; deeper navigation is explicit from inspector actions. Paper graph nodes use adaptive labels, hover/selection expansion, canvas pan/zoom, and per-node drag offsets.
- **Sidebar navigation**: The root sidebar uses selection-backed `NavigationLink` rows plus explicit split-view visibility state so compact iPad navigation reveals detail. Any navigation change requires both `AppNavigationTests` and a live macOS click smoke across all six destinations because passive selection rows previously regressed on macOS.
- **Sidebar accessibility**: Defer sidebar selection publication to the next main run-loop turn. Synchronous publication from the `List(selection:)` binding produces SwiftUI runtime faults under accessibility activation.
- **Claim graph performance**: Full claim relation inference is corpus-scale and must not run during SwiftUI `body` evaluation or app launch. Use bounded previews for UI cards and keep full graph export off the main actor.
- **Bridge analysis performance**: `BridgingSection` must not call `influencePath`, `claimPathBetweenClusters`, or other claim graph builders from `body`; bridge search is explicit/on-demand so sidebar navigation stays responsive.
- **Swift Charts plot geometry**: Hover/tracking overlays must use guarded plot-frame dimensions/coordinates from `ChartPlotGeometry.swift`. Filled `AreaMark`s over signed/negative analytics values can produce oversized CoreAnimation paint layers; prefer bounded line charts or explicit safe domains.
- **SwiftUI transient geometry**: Treat `GeometryReader` dimensions as untrusted during window restoration/accessibility traversal. Sanitize non-finite or negative values before frame math and omit decorative stroked geometry while the resolved size is zero.
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
- Contributor analytics commands use `analytics/.venv`; stale/incomplete environments should be replaced with a frozen `uv sync`. On this host `uv` is installed at `/Users/s1kor/.local/bin/uv` and is not guaranteed to be on non-interactive `PATH`.
- Topic reliability audit prefers explicit cluster IDs when coverage is high, otherwise falls back to deterministic KMeans over embeddings
- Ingestion smoke testing is opt-in via `LITERATURE_ATLAS_INGEST_SMOKE_*`; `scripts/run_example_smoke.sh` requires an explicit `--source` corpus.
- Sandboxed folder ingestion must start the selected folder's security-scoped access before file existence checks or enumeration; per-file scope alone is insufficient.
- `scripts/run_example_smoke.sh` computes sample-friendly topic thresholds (`min_topic_size=max(3,floor(N/3))`, `min_primary_topic_size=ceil(0.4*N)`) to avoid flaky false negatives on random `--count 10` runs
- SciPy is a direct analytics dependency because `linear_sum_assignment` is used for cluster alignment. The July 2026 lock requires Python 3.12+ and selects NumPy 2.5.1, SciPy 1.18.0, and scikit-learn 1.9.0; older SciPy 1.15.3 failed to load on the audited macOS host.
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
- 2026-06-29: Full generalization pass reframed user-facing trading/quant/strategy surfaces as general research, insight brief, research plan, application impact, and research project language while preserving legacy internal type names, JSON keys, event names, and artifact filenames for compatibility.
- 2026-07-15: Added deterministic XcodeGen macOS/iPadOS App Store targets, centralized version/build/bundle settings, least-privilege entitlements, required-reason privacy manifests, container storage, shared self-contained runtime conditions, and fail-closed release validation (`project.yml`, `Config/`, `Resources/`, `scripts/validate_release_configuration.py`).
- 2026-07-15: Scoped 1.0.0 mobile distribution to iPad because the desktop-class interface failed iPhone visual acceptance; fixed compact split navigation with selection-backed `NavigationLink`s and preserved the mandatory live macOS sidebar click smoke.
- 2026-07-15: Added the `DISTRIBUTED_APP_BUILD` boundary and separate credential-free community, signature-free official pre-sign, Developer ID signing, DMG, approval-gated notarization, and distribution-verification scripts. Official signing is blocked until the owner authorizes the installed private key; no Apple upload was performed.
- 2026-07-15: The source repository is already public and effectively MIT-licensed. REUSE 3.3 passes, but chain of title and four reachable historical third-party PDFs block a truthful clean official source release or MPL/CC relicense.
- 2026-07-15: Ordinary CI uses read-only permissions, pinned actions/tools, locked Python/Rust environments, and no Apple credentials. GitHub branch protection, dependency graph/security updates, private vulnerability reporting, and required checks remain owner-controlled external gates.
- 2026-07-16: Direct release builds use a validated generated xcconfig to bind product/bundle/version/build/source revision, reject control-character injection, retain dSYMs, fail on Swift warnings, and use diagnostic-only Xcode output. Distribution verification mounts and exactly compares DMG app contents before accepting them.
- 2026-07-16: Real sandboxed community-app testing must include folder-picker selection, bookmark creation, actual file enumeration/ingest, truthful counters/output artifacts, all six sidebar destinations, and relaunch persistence; unit/build proof alone missed two bookmark lifetime defects.
- 2026-07-16: GitHub `macos-26` arm64 supports Python 3.12.10 but not 3.12.13 in `actions/setup-python`; the verified XcodeGen 2.45.4 archive extracts its binary under `xcodegen/bin` inside the chosen extraction directory.
- 2026-07-17: Hardened analytics and runtime boundaries: strict finite JSON/input normalization, parameterized DuckDB paths, bounded claim-neighbor construction, checksum-based ingest skipping, transactional project persistence, task/run identity guards, panic-contained length-aware Rust FFI, and warning-free single-paper analytics (`docs/audits/release-audit-2026-07-17.md`).
- 2026-07-17: A frozen Python sync must be import-tested, not inferred from lock success; the previous compatible-looking SciPy 1.15.3 wheel failed at `dlopen` on macOS 26, so the scientific stack floors and lock were refreshed (`analytics/pyproject.toml`, `analytics/uv.lock`).
- 2026-07-17: Canonical paper/chunk and strategy-project persistence now commits before in-memory publication; derived Markdown failures remain visible without misreporting a successful canonical generation as failed (`Sources/LiteratureAtlas/App/AppModel.swift`).
- 2026-07-17: PR review aligned topic-audit duplicate resolution with canonical freshness semantics and moved source checksum I/O/hash work off the main actor (`scripts/topic_focus_audit.py`, `Sources/LiteratureAtlas/App/AppModel.swift`).
- 2026-07-17: Full quality remediation made source bookmarks cross-platform, state mutations commit-before-publish, analytics freshness/identity fail closed, expensive layout work cooperatively cancellable, Python analytics rank/scale safe, and release verification enforce the exact read-only entitlement plus required file-timestamp reasons (`PLAN.md`, `docs/audits/release-audit-2026-07-17.md`).
- 2026-07-18: Independent PR review expanded stale-analytics rejection to every UUID-bearing summary section, made Python paper import UUID- and method-pipeline-safe, and fixed claim-neighbor sizing after invalid rows are filtered (`Sources/LiteratureAtlas/Services/AnalyticsStore.swift`, `analytics/rebuild_analytics.py`).
- 2026-07-18: UUID validation must not change persisted Swift identifier casing unless every cross-artifact foreign key is normalized together; paper import now preserves canonical source casing so chunk, event, claim-edge, and cluster joins remain consistent (`analytics/rebuild_analytics.py`).
- 2026-07-18: PR #9 merged reviewed head `e0eb788b8654a18a8fef62398b87017f5b56e79a` as `95d0031a0ee67a9f91cd0d915de75e1f42137daa` after all ten hosted gates and independent review passed; the tree matched exactly.
- 2026-07-18: Published `v1.0.0-community.1` as an Apple Silicon/macOS 26+ ad-hoc/not-notarized prerelease with DMG checksum and exact-app SPDX SBOM; official Developer ID/notarized/App Store readiness remains blocked by artwork and owner/Apple prerequisites.
- 2026-07-18: PR #10 review reproduced that the published checksum embedded its local build path; centralized portable basename-only checksum generation, added a relocation regression, replaced the remote checksum asset, and verified the remote DMG/checksum pair with the documented downloader command.
