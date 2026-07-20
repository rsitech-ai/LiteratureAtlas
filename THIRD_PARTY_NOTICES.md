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

- Python direct dependencies: DuckDB, NumPy, pandas, scikit-learn, SciPy, and PyArrow.
- Python development dependencies: pip-audit, pytest, and Ruff.
- Rust direct dependency: `hnsw_rs 0.3.4`; transitive versions are resolved in
  `analytics/ffi/Cargo.lock`.

Resolved Python versions are recorded in `analytics/uv.lock`. These components
are not included in the first distributed app. Their upstream licenses must be
reviewed from the exact locks before redistributing contributor-tool binaries or
environments. License metadata includes permissive licenses and MPL-2.0 for
`certifi`; upstream terms remain controlling.

## Build and CI tools

XcodeGen, uv, Ruff, pytest, cargo-audit, and GitHub Actions are build or
validation tools, not app runtime components. Each retains its upstream terms.

## Developer Certificate of Origin

`DCO.txt` is the verbatim Developer Certificate of Origin 1.1, copyright 2004
and 2006 The Linux Foundation and its contributors. It permits copying and
distribution of verbatim copies but does not permit changes. The same text is
stored as `LICENSES/LicenseRef-DCO-1.1.txt` for REUSE/SPDX tooling. It is not
relicensed under Apache-2.0.

## Assets and source documents

The production AppIcon was generated specifically for this project without
external reference artwork. Its complete asset catalog compiles and passes the
release validator. No release-evidence screenshots or third-party sample
research PDFs are tracked in the canonical repository. The canonical
organization history was sanitized before publication; the superseded personal
repository is retained only as a temporary legacy boundary until the RSI Tech
replacement release is remotely verified.
