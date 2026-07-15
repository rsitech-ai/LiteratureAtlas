# LiteratureAtlas 1.0.0 Release Status

## Verdict

`BLOCKED`

The repository is substantially hardened and both shipping applications can produce fresh unsigned Release archives, but the release is not package-ready or ready for App Store Connect upload. Production icon artwork, confirmed identifiers/team/profiles, physical-device acceptance, final metadata, legal/privacy attestations, and Apple-account validation remain owner-controlled blockers.

## Release scope

| Product | Channel | Minimum OS | Architectures | Status |
| --- | --- | --- | --- | --- |
| LiteratureAtlas for macOS | Mac App Store | macOS 26.0 | `arm64`, `x86_64` | Unsigned archive construction passed; distribution signing and validation blocked |
| LiteratureAtlas for iPad | App Store | iPadOS 26.0 | `arm64` | Unsigned archive construction and iPadOS 26.5 simulator launch passed; distribution signing/device proof blocked |
| LiteratureAtlas for iPhone | Not shipping in 1.0.0 | — | — | Explicitly excluded after compact-layout acceptance failed |

Local defaults are version `1.0.0`, build `1`, macOS bundle ID `com.literatureatlas.app`, and iPadOS bundle ID `com.literatureatlas.app.ios`. These coordinates are centralized and reversible, not asserted to exist in App Store Connect.

## Readiness labels

- Repository quality: `PASS`, except production icon validation intentionally remains red.
- App Store runtime architecture: `PASS` for self-contained, on-device builds.
- Unsigned archive construction: `PASS` for macOS and iPadOS.
- Package-ready: `BLOCKED` by icon and distribution signing.
- Release-candidate ready: `BLOCKED` by physical-device and owner acceptance gates.
- Ready for App Store Connect upload: `BLOCKED` by account, signing, metadata, legal, and validation gates.

## Evidence coordinate

- Base commit: `010769162d824192310bf9236ffe188ef9fba7c4`
- Release branch: `feat/andrzej_literatureatlas_release_20260715`
- Hardened implementation commit: `0d99116`
- Toolchain: Xcode 26.6 (`17F113`), iOS/macOS SDK 26.5
- Production runtime track: iPadOS 26.5 simulator
- Compatibility track: macOS 27 beta host and iPadOS 27 beta simulator, recorded separately

## Machine-verified outcome

- Deterministic XcodeGen project with shared Release schemes and explicit macOS/iPadOS application products.
- App Store compilation excludes runtime Python installation/execution, repository-relative Rust loading, and dormant OpenAI networking.
- App data uses the application container; selected macOS folders use read-only sandbox access and open their security scope before enumeration.
- Privacy manifests include the verified file-timestamp reasons `3B52.1` and `C617.1` without inventing collected-data answers.
- Swift, Python, and Rust format/lint/test/dependency gates pass locally; `bincode 1.3.3` remains a documented unmaintained dependency warning, not a known vulnerability.
- macOS App Store build launched sandboxed on the macOS 27 beta host and all six sidebar destinations were selected through the live accessibility tree.
- iPadOS 26.5 App Store build launched into the product UI. iPadOS 27 beta launched the explicit model-unavailable fallback because Apple Intelligence was not enabled in that simulator.
- Fresh unsigned macOS and iPadOS archives include expected coordinates, dSYMs, privacy manifests, and target architectures.
- Complete security branch-diff scan through `0d99116` reviewed all 20 changed source-like files with zero reportable findings and zero deferred rows. The later `eff288e` no-op cast removal received targeted Rust 1.97 verification; neither result claims an exhaustive repository-wide audit.

## Next release-lead action

Resolve the blockers in [BLOCKERS.md](BLOCKERS.md), then rerun the final matrix in [APP_STORE_CHECKLIST.md](APP_STORE_CHECKLIST.md). No upload, TestFlight distribution, review submission, merge, or tag has occurred.
