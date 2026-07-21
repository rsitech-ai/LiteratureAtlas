# LiteratureAtlas

LiteratureAtlas is a local-first SwiftUI app for turning research PDFs and Markdown notes into a navigable knowledge atlas. It performs document extraction, on-device summarization, semantic search, clustering, claim analysis, and interactive visualization without requiring a hosted backend.

## Release status

The canonical source repository is maintained by RSI Tech under Apache-2.0.
The official Apple Silicon macOS 1.0.0 release is available from the
[GitHub release](https://github.com/rsitech-ai/LiteratureAtlas/releases/tag/v1.0.0)
with its SHA-256 checksum and application SPDX SBOM.

- Community macOS builds are credential-free, ad-hoc signed, sandboxed, and use a distinct name and bundle identifier.
- The official 1.0.0 macOS build is Developer ID signed, Apple notarized, stapled, and accepted by Gatekeeper as Notarized Developer ID.
- The direct-download artifact is currently scoped to Apple Silicon and macOS 26 or later.
- The iPadOS target remains available for development, but is not part of the direct-download release.

See [open-source status](docs/open-source/OPEN_SOURCE_STATUS.md) and [release blockers](docs/open-source/BLOCKERS.md) before redistributing a build as official.

## What it does

- Ingests PDF and Markdown documents selected by the user.
- Builds local summaries, sections, citation anchors, embeddings, claims, and method structures.
- Creates a multi-scale Knowledge Universe for corpus exploration.
- Supports evidence-backed local Q&A, reading plans, flashcards, topic dossiers, and corpus briefings.
- Exports Markdown and graph artifacts for downstream use.
- Offers an optional contributor-only Python analytics pipeline and Rust acceleration library.

## Privacy boundary

Distributed app builds are native and local-only:

- mutable data is stored under `Application Support/LiteratureAtlas/Output`;
- prompt templates are bundled inside the app;
- repository Python execution and dependency installation are compiled out;
- environment API-key access and the dormant remote compiler provider are compiled out;
- repository-relative Rust dynamic loading is compiled out and the Swift fallback is used;
- the macOS app is sandboxed with read-only access to user-selected files;
- raw question text is not duplicated into local analytics events, and document paths are private in unified logs.

SwiftPM contributor builds retain repository-local tooling and store generated files under `Output/`. See [the privacy data map](docs/release/1.0.0/PRIVACY_DATA_MAP.md) for the current data inventory.

## Requirements

- macOS 26 or later
- Xcode 26.6 or a compatible Swift 6 toolchain
- XcodeGen 2.45.4 to regenerate the Xcode project
- Rust stable for the optional FFI crate
- Python 3.12 and uv for the optional analytics pipeline

## Clone and test

```bash
git clone https://github.com/rsitech-ai/LiteratureAtlas.git
cd LiteratureAtlas

swift test

cargo fmt --manifest-path analytics/ffi/Cargo.toml --check
cargo clippy --manifest-path analytics/ffi/Cargo.toml --all-targets --all-features --locked -- -D warnings
cargo test --manifest-path analytics/ffi/Cargo.toml --locked

uv sync --project analytics --extra dev --frozen
analytics/.venv/bin/python -m ruff format --check analytics scripts
analytics/.venv/bin/python -m ruff check analytics scripts
analytics/.venv/bin/python -m pytest analytics/tests -v
```

The opt-in ingestion smoke test is skipped unless `LITERATURE_ATLAS_INGEST_SMOKE_INPUT_DIR` and its output variables are supplied. This repository intentionally does not redistribute third-party sample PDFs.

## Run a contributor build

```bash
swift run LiteratureAtlas
```

Contributor builds can use the repository-local analytics tools:

```bash
uv run --project analytics --extra dev --frozen python analytics/rebuild_analytics.py --base .
```

Select your own PDF or Markdown folder in the Ingest screen. Do not commit the generated `Output/` directory or source documents.

## Build a community app

The community build uses a non-official name and bundle identifier and needs no Apple account:

```bash
script/build_community.sh \
  --product-name LiteratureAtlasCommunity \
  --bundle-id ai.rsitech.LiteratureAtlasCommunity \
  --version 1.0.0 \
  --build 1 \
  --output dist/community

script/verify_distribution.sh \
  --app dist/community/LiteratureAtlasCommunity.app \
  --mode community

script/create_dmg.sh \
  --app dist/community/LiteratureAtlasCommunity.app \
  --output dist/community/LiteratureAtlasCommunity-1.0.0.dmg
```

The command above uses RSI Tech's community-build identity.
Downstream distributors must replace it with a bundle namespace they control.
Community builds must not imply that they are official or Apple-notarized. See
[community build policy](docs/community-build/README.md) and
[branding](BRANDING.md).

## Prepare an official Developer ID build

The build step is deliberately unsigned:

```bash
script/build_official.sh \
  --product-name LiteratureAtlas \
  --bundle-id "$OFFICIAL_BUNDLE_ID" \
  --version "$VERSION" \
  --build "$BUILD_NUMBER" \
  --output dist/official
```

Signing and notarization are separate, owner-controlled steps:

```bash
script/sign_developer_id.sh \
  --app dist/official/LiteratureAtlas.app \
  --identity "$DEVELOPER_ID_APPLICATION"

script/verify_distribution.sh \
  --app dist/official/LiteratureAtlas.app \
  --mode official \
  --expected-bundle-id "$OFFICIAL_BUNDLE_ID" \
  --expected-team-id "$DEVELOPER_TEAM_ID" \
  --expected-version "$VERSION" \
  --expected-build "$BUILD_NUMBER" \
  --expected-architecture arm64 \
  --expected-min-macos 26.0 \
  --expected-source-revision "$(git rev-parse HEAD)"

script/create_dmg.sh \
  --app dist/official/LiteratureAtlas.app \
  --output dist/official/LiteratureAtlas-1.0.0.dmg

# External Apple upload. Run only with release-owner approval.
script/notarize_dmg.sh \
  --dmg dist/official/LiteratureAtlas-1.0.0.dmg \
  --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" \
  --expected-sha256 "$APPROVED_DMG_SHA256" \
  --submit
```

The repository contains no signing certificate, private key, profile, Apple
credentials, or notary profile. Follow [RELEASING.md](RELEASING.md) for the
complete gate sequence.

## Project structure

- `Sources/LiteratureAtlas/`: Swift application, models, services, and views.
- `Tests/LiteratureAtlasTests/`: Swift behavior and boundary tests.
- `Resources/`: Info plists, entitlements, privacy manifests, and asset catalogs.
- `Prompts/`: bundled local prompt templates.
- `analytics/`: optional Python analytics and Rust FFI contributor tooling.
- `Config/` and `project.yml`: deterministic Xcode build configuration.
- `script/`: app build, signing, DMG, notarization, and verification tools.
- `docs/open-source/`: publication, IP, security, supply-chain, and blocker evidence.

`project.yml` is the Xcode project source of truth. Regenerate and verify it with:

```bash
xcodegen generate --spec project.yml
git diff --exit-code -- LiteratureAtlas.xcodeproj
```

## Contributing and support

Read [CONTRIBUTING.md](CONTRIBUTING.md), the [Developer Certificate of Origin](DCO.txt),
and the [Code of Conduct](CODE_OF_CONDUCT.md). General support boundaries are in
[SUPPORT.md](SUPPORT.md). Send confidential project, conduct, and security mail
to `info@rsitech.ai`; do not place vulnerabilities, private documents, signing
material, or personal data in public issues.

## License and attribution

Copyright 2025-2026 Rafal Sikora. Project-authored source is available under the
[Apache License 2.0](LICENSE) and publicly maintained by
[RSI Tech](https://rsitech.ai). Third-party components and Apple SDKs remain
under their respective terms; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
Apache-2.0 does not grant rights to imply endorsement or use project branding
contrary to [TRADEMARKS.md](TRADEMARKS.md).
