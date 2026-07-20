# LiteratureAtlas 1.0.0 Release Gates

## Direct-download gates

| Gate | Current state | Evidence required to close |
| --- | --- | --- |
| Production AppIcon | Implemented, verification pending | Complete referenced opaque asset catalog compiles for macOS and iPadOS and passes the release validator |
| Migration PR | Pending | Reviewed org PR is green and merged through protected `main` |
| Exact source build | Pending | Official app is built from the merged org `main` SHA |
| Developer ID signing | Pending | Valid signature, Team `2NY8A789TN`, hardened runtime, least-privilege entitlements, and nested-code verification |
| Apple notarization | Pending | Accepted request bound to the published DMG digest, stapled ticket, and successful `spctl`/`stapler` validation |
| Runtime package proof | Pending | Mounted app byte equality, relocated launch, and clean launch-log inspection |
| Public download | Pending | RSI Tech release assets, checksum, SPDX SBOM, and remote byte-for-byte verification |

None of these gates may be bypassed by publishing the legacy ad-hoc community
artifact as the official release.

## Separate App Store lane

Apple Development/App Store Distribution identities, registered App Store
identifiers, provisioning profiles, App Store Connect metadata, privacy
attestations, screenshots, and physical iPad acceptance remain external work.
They do not block the notarized macOS direct-download lane.

## Tracked dependency debt

`bincode 1.3.3` is reported as unmaintained (`RUSTSEC-2025-0141`) but not as a
known vulnerability. The Rust FFI is not loaded by the distributed app; any
migration must be a separate compatibility-tested change.
