# Third-party notices

This file describes scopes; the lock files and generated inventories are the
version source of truth. Upstream copyright notices and license texts remain
controlling.

## Distributed macOS app

The first direct-distribution app is built from project-authored Swift source,
prompts, and resources using Apple platform SDKs and system frameworks. It does
not embed the Python analytics environment or the Rust FFI library. SwiftPM has
no remote Swift package dependencies.

Apple SDKs and system frameworks are supplied under Apple's terms and are not
relicensed by this repository.

## Contributor-only dependencies

- Python direct dependencies: DuckDB, NumPy, pandas, scikit-learn, and PyArrow.
- Python development dependencies: pytest and Ruff.
- Rust direct dependency: `hnsw_rs`; transitive versions are resolved in
  `analytics/ffi/Cargo.lock`.

Resolved Python versions are recorded in `analytics/uv.lock`. These components
are not included in the first distributed app. Their upstream licenses must be
reviewed from the exact locks before redistributing contributor-tool binaries or
environments.

## Build and CI tools

XcodeGen, uv, Ruff, pytest, cargo-audit, and GitHub Actions are build or
validation tools, not app runtime components. Each retains its upstream terms.

## Assets and source documents

Production AppIcon artwork has not been approved. Release-evidence screenshots
remain provenance-review items. No third-party sample research PDFs are present
in the current tree or permitted in release artifacts. Historical PDF blobs in
reachable Git history are a publication blocker documented in
`docs/open-source/IP_INVENTORY.md`.
