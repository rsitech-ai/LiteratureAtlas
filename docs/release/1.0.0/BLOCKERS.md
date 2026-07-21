# LiteratureAtlas 1.0.0 Release Gates

## Direct-download gates

| Gate | Current state | Evidence required to close |
| --- | --- | --- |
| Production AppIcon | Pass | Complete referenced opaque asset catalog compiles for macOS and iPadOS and passes the release validator |
| Migration PR | Pass | Reviewed org PR #4 passed all required checks and merged through protected `main` |
| Exact source build | Pass | Official app embeds merged org `main` SHA `88f7d5e7c373226eb3861277ba9ca6a57f5e8774` |
| Developer ID signing | Pass | Team `2NY8A789TN`, hardened runtime, least-privilege entitlements, secure timestamp, and nested-code verification |
| Apple notarization | Pass | Submission `68cc41be-2f44-4650-a731-ec1e5a042f3f` accepted with no issues; DMG ticket stapled and validated; app accepted by Gatekeeper |
| Runtime package proof | Pass | Mounted app equality, quarantined relocation, launch, process-liveness, and clean fatal-log scan |
| Public download | Pass | RSI Tech `v1.0.0` DMG, checksum, and SPDX SBOM match unauthenticated public downloads byte-for-byte |

The legacy ad-hoc community prerelease and tag were removed only after all
replacement gates passed. The personal repository is private and archived.

## Separate App Store lane

Apple Development/App Store Distribution identities, registered App Store
identifiers, provisioning profiles, App Store Connect metadata, privacy
attestations, screenshots, and physical iPad acceptance remain external work.
They do not block the notarized macOS direct-download lane.

## Tracked dependency debt

`bincode 1.3.3` is reported as unmaintained (`RUSTSEC-2025-0141`) but not as a
known vulnerability. The Rust FFI is not loaded by the distributed app; any
migration must be a separate compatibility-tested change.
