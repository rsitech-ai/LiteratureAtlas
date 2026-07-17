# LiteratureAtlas 1.0.0 Release Status

## 1. Final verdict

`BLOCKED`

Current date: `2026-07-15` (Europe/Warsaw).

The repository is release-hardened and both shipping applications produce fresh unsigned Release archives, but the release is not package-ready, TestFlight-ready, or ready for App Store Connect upload. Production icon artwork, confirmed identifiers/team/profiles, distribution-signed Apple validation, physical-device acceptance, final metadata, and legal/privacy attestations remain genuine owner or external blockers.

## 2. Apple submission requirements and toolchain

Apple's requirement effective April 28, 2026 accepts apps built with Xcode 26 or later and the iOS/iPadOS 26 SDK or later. This was checked on `2026-07-15` against Apple's [Submitting apps page](https://developer.apple.com/app-store/submitting/), [upcoming requirements](https://developer.apple.com/news/upcoming-requirements/), and [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

- Production archive toolchain: Xcode 26.6 (`17F113`), iOS/macOS SDK 26.5.
- Xcode 27: not used for production archives because it is a beta toolchain and is not required by Apple's current accepted minimum.
- OS 27 compatibility: macOS 27 beta host launch/navigation passed; iPadOS 27 beta launched the explicit Apple-Intelligence-unavailable fallback without a crash. End-to-end model output was not tested on that simulator.

## 3. Release coordinates and scope

| Product | Version/build | Bundle ID default | Minimum OS | Architecture/device family | Status |
| --- | --- | --- | --- | --- | --- |
| LiteratureAtlas for macOS | `1.0.0` / `1` | `com.literatureatlas.app` | macOS 26.0 | universal `arm64`, `x86_64` | Unsigned archive construction passed; distribution signing and validation blocked |
| LiteratureAtlas for iPad | `1.0.0` / `1` | `com.literatureatlas.app.ios` | iPadOS 26.0 | `arm64`, iPad family `2` | Unsigned archive and iPadOS 26.5 simulator launch passed; distribution signing/device proof blocked |
| LiteratureAtlas for iPhone | Not shipping in 1.0.0 | — | — | Excluded | Compact-layout acceptance failed; project is explicitly iPad-only |

The identifiers are centralized, reversible defaults and are not claimed to exist in App Store Connect. The Apple Team remains unset pending owner confirmation.

## 4. Release-gate matrix

| Gate | Result | Command or inspection | Evidence | Owner | Next action |
| --- | --- | --- | --- | --- | --- |
| Accepted production toolchain | PASS | Checked current Apple requirements; `xcodebuild -version`, SDK inventory | This report and [TEST_EVIDENCE.md](TEST_EVIDENCE.md) | Release lead | Recheck only if submission occurs after Apple changes the requirement |
| Deterministic project/configuration | PASS | XcodeGen regeneration and generated-project diff; release validator | `project.yml`, `Config/`, generated project | Engineering | Keep generated project synchronized with `project.yml` |
| Swift build and tests | PASS | `swift test`; `swift build -c release` | 55 passed, 1 opt-in corpus smoke skipped; Release build passed | Engineering | Supply a real corpus only for the separately gated ingestion smoke |
| Python quality/dependencies | PASS | Ruff format/lint, 12 tests, uv lock, pip-audit | [TEST_EVIDENCE.md](TEST_EVIDENCE.md) | Engineering | Maintain the lock and CI gates |
| Rust quality/dependencies | PASS WITH WARNING | Rust 1.97 fmt, strict Clippy, 3 tests, cargo-audit | No known vulnerability; `bincode 1.3.3` maintenance warning documented | Engineering | Migrate `bincode` in a separate compatibility-tested change |
| macOS App Store build/runtime | PASS, LIMITED | Generic Release build; sandboxed host launch; live accessibility navigation | macOS 27 beta evidence and screenshot | Release QA | Repeat critical flows on supported physical macOS 26 hardware |
| iPad App Store build/runtime | PASS, LIMITED | Generic Release build; install/launch on iPadOS 26.5 and 27 beta simulators | Simulator screenshots and runtime matrix | Release QA | Run full flow on an Apple Intelligence-capable physical iPadOS 26 device |
| Accessibility | BLOCKED | Live accessibility tree navigation; compact-layout visual inspection | Six macOS destinations reachable; iPad title/layout inspected | Product/accessibility owner | Complete VoiceOver, keyboard, contrast, text-size, and App Store accessibility-label acceptance on target devices |
| Performance and memory | PASS, LIMITED | Idle process sample and macOS `leaks` capture | 0.0% CPU, about 20 MB RSS; 20,016 framework-owned leak bytes, no app-owned frame | Release QA | Recheck critical flows with Instruments on the signed candidate |
| Security and supply chain | PASS, DIFF-SCOPED | Complete branch-diff scan; secret/config review; dependency audits | 20/20 changed source-like files, 0 findings, 0 deferred rows; [SECURITY_STATUS.md](SECURITY_STATUS.md) | Engineering/security | Preserve the runtime boundary; run signed-artifact inspection after signing |
| Privacy manifest/runtime boundary | PASS, OWNER ATTESTATION BLOCKED | Plist/privacy/entitlement validation; executable string scan; data-flow review | Required reasons `3B52.1` and `C617.1`; no App Store remote/runtime-tooling path | Privacy/product owner | Attest production operations and complete App Privacy answers/policy |
| App icon | FAIL | `python3 scripts/validate_release_configuration.py --json` | Sole validator failure: `app_icon_artwork` | Product/design owner | Approve and commit complete macOS/iPadOS production artwork |
| Unsigned archives | PASS | Fresh Xcode 26.6 `xcodebuild archive` with signing disabled | `/tmp/LiteratureAtlas-1.0.0-final-20260715-*.xcarchive` | Release lead | Rebuild after identifiers, artwork, team, and profiles are approved |
| Signing/provisioning/Apple validation | BLOCKED | Identity/profile inventory; archive bundle inspection | Distribution identity exists for Team `2NY8A789TN`; matching confirmed IDs/profiles and signed validation absent | Apple account owner | Confirm IDs/team, install profiles, produce signed archives, inspect and validate with Apple |
| Metadata, legal, pricing, storefronts | BLOCKED | Repository/App Store content audit | [APP_REVIEW_NOTES.md](APP_REVIEW_NOTES.md), [BLOCKERS.md](BLOCKERS.md) | Product/legal/account owner | Supply and approve all declarations, URLs, copy, categories, rights, rating, DSA, export, pricing, territories, release mode |
| Marketing screenshots | BLOCKED | Engineering captures inspected for dimensions/content | Captures are truthful engineering evidence but show an empty corpus and are not approved marketing assets | Product/design owner | Capture populated screens and approve licensing/PII/localization |
| CI | EXPECTED FAIL-CLOSED | Push run `29423538877`; PR run `29423541480` at implementation head `45b9411` | Python and Rust green; both Apple jobs passed Swift, Release, XcodeGen, macOS, and iPadOS gates, then failed only `app_icon_artwork` | Product/design owner | Add approved icons and rerun CI |
| TestFlight/App Store Connect | BLOCKED | Account/auth/upload inventory | No authorized upload or validation performed | Apple account owner/release lead | Close signing, validation, metadata, legal, and device gates; obtain explicit upload approval |

## 5. Tests executed

- Swift: 55 tests passed; one opt-in corpus ingestion smoke skipped because `LITERATURE_ATLAS_INGEST_SMOKE_INPUT_DIR` was not supplied.
- Swift Release: `swift build -c release` passed.
- Python: Ruff format and lint passed; 12 tests passed; `uv lock --check` passed; `pip-audit` found no known vulnerability.
- Rust 1.97: format, all-target/all-feature Clippy with `-D warnings`, and 3 tests passed; `cargo-audit` found no known vulnerability and reported the tracked unmaintained `bincode` warning.
- Xcode: generic macOS and iPadOS Release builds passed; fresh unsigned archives passed.
- Release validator: every configuration/security/runtime-boundary check passed except the intentionally unresolved `app_icon_artwork` gate.

Exact commands and results are recorded in [TEST_EVIDENCE.md](TEST_EVIDENCE.md).

## 6. Devices and simulators tested

- iPadOS 26.5 iPad simulator: installed and launched into Knowledge Universe; compact/split navigation regression verified.
- iPadOS 27 beta iPad simulator: launched graceful Apple-Intelligence-unavailable state; end-to-end model behavior not exercised.
- macOS 27 beta host: sandboxed app launched; Ingest, Universe, Q&A, Insights, Projects, and Analytics selected through the live accessibility tree.
- Physical macOS 26 and iPadOS 26: not available for final first-release acceptance; this remains blocking.

## 7. Accessibility checks

The macOS live accessibility tree exposed and selected all six primary destinations. The iPad compact/split title and navigation presentation were visually inspected on iPadOS 26.5. Full VoiceOver order/actions, keyboard-only operation, increased contrast, accessibility text sizes, reduced motion, switch control, and App Store accessibility nutrition labels are not owner-accepted on physical target devices and remain blocking rather than being inferred from build success.

## 8. Performance and leak findings

After roughly 20 minutes, a macOS point sample showed 0.0% CPU and about 20 MB RSS. `leaks` reported 20,016 bytes across 417 allocations rooted in Apple framework XPC cycles, with no LiteratureAtlas-owned frame. This is useful compatibility evidence, not proof of zero leaks; comparable signed-candidate Instruments/ETTrace work remains a device acceptance action.

## 9. Security findings and fixes

App Store builds exclude runtime Python/dependency installation and repository-relative Rust loading; document compilation is on-device in every build and the dormant network compiler has been removed. Mutable output uses the app container; macOS selected-folder enumeration begins inside the security scope; least-privilege entitlements and privacy manifests are packaged. The sealed branch-diff scan through `0d99116` reviewed all 20 changed source-like files with zero reportable findings and zero deferred rows. The post-scan `eff288e` one-line no-op cast removal received targeted Rust 1.97 review. This does not claim an exhaustive repository-wide scan. See [SECURITY_STATUS.md](SECURITY_STATUS.md).

## 10. Privacy and compliance

The verified App Store runtime is local-first, has no linked third-party runtime SDK, and exposes no first-party telemetry endpoint. Privacy manifests declare the verified file-timestamp reasons without inventing collected-data answers. App Store privacy labels, privacy-policy URL/content, age rating, content rights, export compliance, EU DSA trader status, accessibility labels, and any operational data handling outside this repository require truthful owner decisions. See [PRIVACY_DATA_MAP.md](PRIVACY_DATA_MAP.md).

## 11. Signing, entitlements, and archive validation

- macOS entitlement: App Sandbox plus read-only user-selected file access.
- iPadOS entitlement file: intentionally no unverified capabilities.
- Fresh unsigned archives contain version/build coordinates, dSYMs, privacy manifests, and the expected architecture/device family.
- An Apple Distribution identity is installed for Team `2NY8A789TN`, but the team and bundle IDs are not owner-confirmed and matching App Store profiles are unavailable.
- Distribution signatures, embedded profiles, final entitlements, icon resources, and Apple validation are therefore `BLOCKED`. Unsigned archive construction is not represented as upload readiness.

## 12. TestFlight and upload status

No App Store Connect validation, upload, processing, tester assignment, TestFlight distribution, review submission, public release, merge, tag, or GitHub release occurred. TestFlight is blocked by the same artwork, account, signing, validation, metadata, and physical-device acceptance gates.

## 13. Changed files and commits

The release-hardening diff from `0107691` through implementation head `45b9411` changes 57 files: XcodeGen/Xcode configuration, platform resources and entitlements, runtime boundaries and paths, iPad navigation, Swift/Python/Rust tests and dependency locks, CI, and the versioned release dossier/evidence. It contains 3,458 insertions and 226 deletions before this final dossier-only close-out.

Commits:

- `8458517` Document App Store release preflight
- `0eecc7a` Add deterministic Apple app targets
- `9e60050` Harden App Store runtime boundaries
- `4b48e24` Align Xcode runtime hardening across configurations
- `5750690` Refresh analytics quality and dependency gates
- `6e3d2cf` Fix compact navigation and scope mobile release to iPad
- `fc0ad29` Enforce sandbox ingest and release CI gates
- `0d99116` Polish iPad navigation title presentation
- `a562a2d` Complete LiteratureAtlas release dossier
- `eff288e` Fix Rust 1.97 Clippy drift
- `45b9411` Record Rust CI compatibility evidence

## 14. Pull request and CI status

Draft PR: [#3 — Prepare LiteratureAtlas 1.0.0 App Store release](https://github.com/s1korrrr/LiteratureAtlas/pull/3), open and intentionally unmerged.

At implementation head `45b9411`, both the [push workflow](https://github.com/s1korrrr/LiteratureAtlas/actions/runs/29423538877) and [PR workflow](https://github.com/s1korrrr/LiteratureAtlas/actions/runs/29423541480) completed. Python and Rust jobs passed. Both Apple jobs passed Rust FFI construction, toolchain recording, 55 Swift tests, Swift Release build, deterministic XcodeGen verification, and macOS/iPadOS App Store target builds; both then stopped at the same sole fail-closed validator result: missing production AppIcon artwork. No unrelated CI defect remains known.

## 15. Remaining human-only decisions

The owner must approve the icon and marketing screenshots; confirm/register bundle IDs and Team; provide profiles; attest privacy operations; supply URLs, metadata, age rating, content rights, export and DSA answers, accessibility labels, pricing, territories, and release mode; authorize physical-device acceptance; and approve any later upload. The exact evidence required for each is in [BLOCKERS.md](BLOCKERS.md).

## 16. Exact next action required to submit

First, the product/design owner must approve production icon artwork and the Apple account owner must confirm the two bundle identifiers and Team `2NY8A789TN`. Then the release lead can commit the icon set and confirmed coordinates, install matching profiles, produce fresh distribution-signed archives, inspect signatures/entitlements/resources, run Apple validation, complete physical-device and metadata/legal acceptance, and request explicit upload approval. Submission must remain blocked until every row in [APP_STORE_CHECKLIST.md](APP_STORE_CHECKLIST.md) is complete.

## 17. Residual risks

- First-release import/Q&A/export, permission denial/retry, offline behavior, lifecycle recovery, interruption, and low-storage behavior lack physical-device proof.
- iPadOS 27 beta evidence covers graceful fallback only because Apple Intelligence was unavailable.
- The framework-owned macOS leak snapshot should be rechecked on the signed candidate if memory grows during real flows.
- `bincode 1.3.3` is unmaintained even though no known vulnerability is reported and the FFI is excluded from the App Store runtime boundary.
- The sealed security result is branch-diff scoped and predates the separately reviewed one-line Rust compatibility fix.

No upload, TestFlight distribution, review submission, merge, production tag, or public release is authorized or has occurred.
