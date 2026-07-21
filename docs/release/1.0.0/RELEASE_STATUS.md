# LiteratureAtlas 1.0.0 Release Status

## Current verdict

`RELEASED`

The canonical source repository is
[`rsitech-ai/LiteratureAtlas`](https://github.com/rsitech-ai/LiteratureAtlas).
Version `1.0.0` (build `1`) is the first RSI Tech direct download. The artifact
was built from merged source `88f7d5e7c373226eb3861277ba9ca6a57f5e8774`,
Developer ID signed, Apple notarized, stapled, quarantine tested, and published
with remotely verified bytes at
[`v1.0.0`](https://github.com/rsitech-ai/LiteratureAtlas/releases/tag/v1.0.0).

The earlier `v1.0.0-community.1` personal-repository prerelease was ad-hoc
signed and not notarized. It and its tag were removed after replacement
verification; the personal repository is private and archived recovery
evidence.

## Direct-download target

| Product | Version / build | Bundle identifier | Minimum OS | Architecture | Distribution |
| --- | --- | --- | --- | --- | --- |
| LiteratureAtlas for macOS | `1.0.0` / `1` | `ai.rsitech.LiteratureAtlas` | macOS 26.0 | `arm64` | Developer ID Application, hardened runtime, notarized DMG |

The iPadOS target remains an App Store development lane and is not part of the
direct-download artifact.

## Release contract

- Build unsigned official application from the exact merged source.
- Sign with `Developer ID Application: Rafal Sikora (2NY8A789TN)`.
- Verify the designated requirement, entitlements, hardened runtime, nested
  code, version/build, bundle ID, architecture, and minimum OS.
- Package the verified app in a DMG and bind notarization to its SHA-256 digest.
- Staple and validate the ticket, pass Gatekeeper, compare mounted app bytes,
  relocate and launch the app, and inspect launch logs.
- Publish the DMG, checksum, app SPDX SBOM, and source mapping under the RSI
  Tech organization release, then download and verify every remote byte.

## Evidence boundary

`docs/release/1.0.0/TEST_EVIDENCE.md` records the exact commands and results.
`docs/open-source/OPEN_SOURCE_MANIFEST.json` is the machine-readable source and
release record. The iPad App Store lane remains separate and blocked external.
