# Build and test

## Prerequisites

- macOS 26 or later and Xcode 26.6 (Swift 6.3)
- XcodeGen 2.45.4
- Rust 1.97.0 for the optional FFI crate
- Python 3.12 and uv 0.5.23 for the optional analytics pipeline

The direct-distribution target is Apple Silicon. Contributor SwiftPM builds may
use checkout-local analytics tooling; distributed builds cannot.

## Deterministic Xcode project

```bash
xcodegen generate --spec project.yml
git diff --exit-code -- LiteratureAtlas.xcodeproj
```

`project.yml` is the source of truth. Do not hand-edit the generated project.

## Required local gates

```bash
swift test

cargo fmt --manifest-path analytics/ffi/Cargo.toml --check
cargo clippy --manifest-path analytics/ffi/Cargo.toml --all-targets --all-features --locked -- -D warnings
cargo test --manifest-path analytics/ffi/Cargo.toml --locked
cargo audit --file analytics/ffi/Cargo.lock

uv sync --project analytics --extra dev --frozen
analytics/.venv/bin/python -m ruff format --check analytics scripts
analytics/.venv/bin/python -m ruff check analytics scripts
analytics/.venv/bin/python -m pytest analytics/tests -v

scripts/tests/test_release_scripts.sh
python3 scripts/validate_release_configuration.py
```

The validator currently blocks release only on missing approved AppIcon artwork.
Rust dependency auditing currently reports `bincode 1.3.3` as unmaintained; no
known current vulnerability was found in the locked crate graph.

## Corpus smoke test

The repository ships no sample research PDFs. Supply a folder you are authorized
to use through `LITERATURE_ATLAS_INGEST_SMOKE_INPUT_DIR` and the documented output
variables. Generated `Output/` data remains local and must not be committed.

See [analytics/README.md](../../analytics/README.md) for contributor analytics
usage and [the community build guide](../community-build/README.md) for packaging.
