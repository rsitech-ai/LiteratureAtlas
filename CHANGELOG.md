# Changelog

All notable project changes are documented here.

## Unreleased

### Added

- A native local-first research atlas for PDF and Markdown corpora.
- Credential-free community build and DMG tooling.
- Fail-closed Developer ID signing and notarization interfaces.

### Changed

- Distributed builds use a self-contained native runtime and Application Support.

### Security

- Distributed builds compile out checkout-only execution and environment-key paths.
- Local diagnostic events no longer duplicate raw user questions.
- URL-derived openness signals require exact trusted hosts rather than substring matches.
- PDF extraction is off the main actor, incrementally hashed, and cooperatively cancellable.
- Analytics and in-memory caches use a cross-language content-and-embedding corpus fingerprint.

## [1.0.0-community.1] - 2026-07-18

### Added

- Published an Apple Silicon/macOS 26+ community DMG with checksum and exact-app SPDX SBOM.

### Security

- The community app is sandboxed, uses hardened runtime, is ad-hoc signed, and is not Apple-notarized.
- Published assets were downloaded and verified byte-for-byte against the recorded hashes.

See [the pre-release notes](docs/release/1.0.0/RELEASE_NOTES.md) for the
user-facing description. No official production or notarized release exists.

[1.0.0-community.1]: https://github.com/s1korrrr/LiteratureAtlas/releases/tag/v1.0.0-community.1
