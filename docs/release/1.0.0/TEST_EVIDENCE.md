# LiteratureAtlas 1.0.0 Test Evidence

## Evidence boundary

- Captured: `2026-07-15`
- Base commit: `010769162d824192310bf9236ffe188ef9fba7c4`
- Hardened implementation commit: `0d99116`
- Release branch: `feat/andrzej_literatureatlas_release_20260715`
- Version/build: `1.0.0` (`1`)
- Shipping targets: Mac App Store and iPad App Store; iPhone excluded
- Production toolchain: Xcode 26.6 (`17F113`), macOS/iOS SDK 26.5
- Compatibility-only environments: macOS 27 beta `26A5378j`; iPadOS 27 beta runtime `24A5380i`
- Authority boundary: no Apple-account mutation, upload, TestFlight distribution, submission, merge, tag, or release

Raw profiles, certificate fingerprints, emails, credentials, private URLs, and device identifiers are intentionally excluded.

## Current Apple requirements snapshot

Apple's published requirement effective April 28, 2026 accepts apps built with Xcode 26 or later and the iOS/iPadOS 26 SDK or later. These archives use Xcode 26.6 and SDK 26.5. Xcode 27/iOS 27 are beta compatibility surfaces and were not used to establish production readiness.

Official sources retrieved on 2026-07-15:

- <https://developer.apple.com/app-store/submitting/>
- <https://developer.apple.com/news/upcoming-requirements/>
- <https://developer.apple.com/news/?id=ueeok6yw>
- <https://developer.apple.com/news/releases/>
- <https://developer.apple.com/app-store/review/guidelines/>
- <https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications?page_id=111069>
- <https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels>
- <https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements>
- <https://developer.apple.com/documentation/bundleresources/privacy-manifest-files>
- <https://developer.apple.com/support/third-party-SDK-requirements/>
- <https://developer.apple.com/documentation/security/app-sandbox>
- <https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox>

## Configuration validation

`python3 scripts/validate_release_configuration.py --json` passes every gate except `app_icon_artwork`:

- macOS/iPadOS application targets and shared Archive schemes
- centralized release coordinates with owner-confirmed team left unset
- optimized Release configuration
- App Store runtime boundary inherited by Debug and Release
- platform Info plists
- privacy manifests and required-reason codes
- least-privilege entitlements
- generated project/schemes
- self-contained App Store compilation
- security-scoped ingest ordering

The remaining failure is deliberate and truthful: the asset catalog does not reference approved production icon artwork.

## Code-quality matrix

| Gate | Result | Evidence |
| --- | --- | --- |
| Swift tests | PASS | 55 tests passed; one opt-in corpus smoke skipped because `LITERATURE_ATLAS_INGEST_SMOKE_INPUT_DIR` was not supplied |
| Swift production build | PASS | `swift build -c release` |
| Python format | PASS | Ruff format check over `analytics` and `scripts` |
| Python lint | PASS | Ruff check over `analytics` and `scripts` |
| Python tests | PASS | 12 tests passed |
| Python lock | PASS | `uv lock --check --project analytics` |
| Python vulnerabilities | PASS | Exported frozen production requirements; `pip-audit --disable-pip` reports no known vulnerabilities |
| Rust format | PASS | `cargo fmt --manifest-path analytics/ffi/Cargo.toml --check` |
| Rust strict lint | PASS | all targets/features with `-D warnings` |
| Rust tests | PASS | 3 tests |
| Rust vulnerabilities | PASS WITH WARNING | no known vulnerability; `bincode 1.3.3` is unmaintained (`RUSTSEC-2025-0141`) |

The repository contains no `analytics/rust/Cargo.toml`; no nonexistent Rust CLI gate is claimed.

## Security diff scan

The release-hardening source diff through implementation commit `0d99116` received a complete Codex Security branch-diff scan covering all 20 changed source-like files. Every selected file has a full-file receipt; no plausible candidate, reportable finding, suppression, or deferred row remained. The sealed report was stored outside Git at an ephemeral machine-local path that is intentionally not published.

The scan snapshot digest is `codex-security-snapshot/v1:sha256:428594bedcaf6a1f2ebe279e8950442f1db9f2a0b0200988a891d073f684bda8`. The scan is diff-scoped and does not claim an exhaustive repository-wide audit. A subsequent one-line CI compatibility commit, `eff288e`, only removes a no-op `f32` cast; it received targeted review and passed Rust 1.97 format, strict Clippy, tests, and audit, but is not represented as part of the sealed snapshot.

## Build and runtime matrix

| Track | Target/environment | Result | Evidence |
| --- | --- | --- | --- |
| Production SDK | Generic macOS Release build | PASS | Xcode 26.6, macOS SDK 26.5, `APP_STORE_BUILD`, signing disabled for repository gate |
| Production SDK | Generic iPadOS Release build | PASS | Xcode 26.6, iOS SDK 26.5, iPad-only target |
| Production runtime | iPadOS 26.5 iPad simulator | PASS | Built, installed, launched into Knowledge Universe; compact/split navigation fixed; full-resolution screenshot captured |
| Compatibility runtime | iPadOS 27 beta iPad simulator | PASS, LIMITED | Built, installed, launched explicit `appleIntelligenceNotEnabled` unsupported state without crash; feature behavior not exercised |
| Compatibility runtime | macOS 27 beta host | PASS | Sandboxed Xcode app launched; all six navigation destinations selected through live accessibility UI |
| Physical device | macOS 26 and iPadOS 26 | BLOCKED | No authorized connected first-release device run |

Production screenshot evidence:

- `evidence/screenshots/ipados-26.5-universe-full.png` — 1640×2360 raw simulator capture after title/layout hardening.
- `evidence/screenshots/macos-27-beta.png` — scoped app-window capture, 2024×1124.

Compatibility evidence:

- `evidence/screenshots/ipados-27-beta-model-unavailable-full.png` — 1640×2360, graceful unsupported state.

The captures are engineering evidence, not an approved marketing set: they show an empty corpus and have not passed product, licensing, localization, or PII review.

## macOS sandbox and runtime evidence

- Local signature verified with App Sandbox, read-only user-selected files, and debug-only `get-task-allow`.
- App container created `Data/Library/Application Support/LiteratureAtlas`; `/Output` remained absent.
- Executable scan found no `api.openai.com`, runtime `pip install`, `rebuild_analytics.py`, or relative `libatlas_ffi` marker.
- Live accessibility navigation selected Ingest, Universe, Q&A, Insights, Projects, and Analytics.
- Idle point sample after roughly 20 minutes: 0.0% CPU and about 20 MB RSS.
- `leaks` reported 20,016 bytes in Apple framework XPC root cycles with no LiteratureAtlas-owned frame; this is not zero-leak proof.

## Archive evidence

Fresh archive commands used Xcode 26.6/SDK 26.5 and `CODE_SIGNING_ALLOWED=NO`:

- `/tmp/LiteratureAtlas-1.0.0-final-20260715-macOS.xcarchive`
- `/tmp/LiteratureAtlas-1.0.0-final-20260715-iPadOS.xcarchive`

Both archive commands succeeded. Archives are intentionally excluded from Git.

| Property | macOS archive | iPadOS archive |
| --- | --- | --- |
| Bundle ID | `com.literatureatlas.app` | `com.literatureatlas.app.ios` |
| Version/build | `1.0.0` / `1` | `1.0.0` / `1` |
| Architecture | `arm64`, `x86_64` | `arm64` |
| Device family | macOS | iPad (`2`) |
| dSYM | Present | Present |
| Privacy manifest | Present | Present |
| Signing team/identity | Empty | Empty |
| Distribution validation | Blocked | Blocked |

Unsigned archives prove reproducible Release construction only. They are not uploadable artifacts.

## Signing inventory

- An Apple Distribution identity is installed for Team `2NY8A789TN`.
- No matching Mac App Store profile was found for `com.literatureatlas.app`.
- iPadOS distribution provisioning and both identifiers remain account-confirmation gates.
- No Team ID is committed to the project until the owner confirms it.

## Final gate result

`BLOCKED`

Repository quality, self-contained architecture, simulator/host runtime, and unsigned archive construction are proven. Production artwork, account identity/provisioning, signed validation, device acceptance, metadata, privacy/legal answers, and approved marketing assets remain genuine external/owner blockers.
