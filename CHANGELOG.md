# Changelog

All notable project changes are documented here.

## Unreleased

### Added

- A native local-first research atlas for PDF and Markdown corpora.
- Credential-free community build and DMG tooling.
- Fail-closed Developer ID signing and notarization interfaces.
- Canonical RSI Tech governance, Apache-2.0 licensing, DCO 1.1, and confidential project contact.

### Changed

- Distributed builds use a self-contained native runtime and Application Support.
- Canonical repository moved to `rsitech-ai/LiteratureAtlas` with sanitized history and RSI Tech bundle namespaces.

### Security

- Distributed builds compile out checkout-only execution and environment-key paths.
- Local diagnostic events no longer duplicate raw user questions.
- URL-derived openness signals require exact trusted hosts rather than substring matches.
- PDF extraction is off the main actor, incrementally hashed, and cooperatively cancellable.
- Analytics and in-memory caches use a cross-language content-and-embedding corpus fingerprint.

## 1.0.0-community.1 (legacy personal prerelease) - 2026-07-18

### Added

- Published an Apple Silicon/macOS 26+ community DMG with checksum and exact-app SPDX SBOM.

### Security

- The community app is sandboxed, uses hardened runtime, is ad-hoc signed, and is not Apple-notarized.
- Published assets were downloaded and verified byte-for-byte against the recorded hashes.

See [the pre-release notes](docs/release/1.0.0/RELEASE_NOTES.md) for the
historical user-facing description. The personal-repository prerelease is
superseded by the RSI Tech release process and is not current org evidence.
