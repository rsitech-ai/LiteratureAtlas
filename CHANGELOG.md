# Changelog

All notable project changes are documented here.

## Unreleased

## 1.0.0 - 2026-07-21

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

### Distribution

- Published the first official RSI Tech Apple Silicon/macOS 26+ release from exact merged source commit `88f7d5e7c373226eb3861277ba9ca6a57f5e8774`.
- Developer ID signed the app, received Apple notarization acceptance, stapled the DMG, passed quarantined relocated-launch proof, and remotely verified every public asset.
- Retired the superseded personal-repository community prerelease after verifying the replacement.

## 1.0.0-community.1 (legacy personal prerelease) - 2026-07-18

### Added

- Published an Apple Silicon/macOS 26+ community DMG with checksum and exact-app SPDX SBOM.

### Security

- The community app is sandboxed, uses hardened runtime, is ad-hoc signed, and is not Apple-notarized.
- Published assets were downloaded and verified byte-for-byte against the recorded hashes.

See [the 1.0.0 release notes](docs/release/1.0.0/RELEASE_NOTES.md) for the
current user-facing description. The personal-repository community prerelease
is retired and is not current org evidence.
