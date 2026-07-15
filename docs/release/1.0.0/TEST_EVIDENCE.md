# LiteratureAtlas 1.0.0 Preflight Test Evidence

## Evidence boundary

- Captured: `2026-07-15T11:45:43Z`
- Requirements retrieved: `2026-07-15`
- Source commit: `010769162d824192310bf9236ffe188ef9fba7c4`
- Release coordinates: version `1.0.0`, build `1`
- Intended channels: Mac App Store and iOS/iPadOS App Store
- Authority boundary: local, read-only release inspection only; no Apple-account changes, uploads, TestFlight distribution, submission, merge, tag, or release occurred.
- Sanitization: certificate fingerprints, profile payloads, device identifiers and names, credentials, emails, private URLs, archives, and raw personal data are intentionally excluded.

## Official Apple requirements snapshot

Apple's current submission page directs developers to build and test with Xcode 26. As of 2026-04-28, iOS and iPadOS uploads must use the iOS and iPadOS 26 SDK or later. The installed Xcode 26.6 toolchain with the 26.5 SDK satisfies that SDK floor.

Official sources retrieved on 2026-07-15:

- <https://developer.apple.com/app-store/submitting/>
- <https://developer.apple.com/news/?id=ueeok6yw>
- <https://developer.apple.com/app-store/review/guidelines/>
- <https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases/>
- <https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/>
- <https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api/>
- <https://developer.apple.com/help/account/provisioning-profiles/create-an-app-store-provisioning-profile>

## Source and toolchain inventory

| Item | Sanitized evidence |
| --- | --- |
| Git | `HEAD=010769162d824192310bf9236ffe188ef9fba7c4`; source boundary was clean before release-plan bookkeeping |
| Host | Apple silicon; macOS 27.0 build `26A5378j` |
| Developer directory | `/Applications/Xcode.app/Contents/Developer` |
| Xcode | 26.6, build `17F113` |
| SDKs | iOS 26.5, iOS Simulator 26.5, macOS 26.5 |
| Swift | Apple Swift 6.3.3 (`swiftlang-6.3.3.1.3`, `clang-2100.1.1.101`) |
| Cargo / rustc | Cargo 1.91.0; rustc 1.91.0 |
| Python | System Python 3.14.6; the validated Python test gate used the repository environment |
| GitHub CLI | 2.96.0 |
| XcodeGen | 2.45.4 |
| Apple release CLI | 0.1.0 |
| Available iOS simulator runtimes | 26.1 (`23B86`), 26.2 (`23C54`), 26.5 (`23F77`), and compatibility runtime 27.0 (`24A5380i`) with iPhone and iPad device types |
| Device inventory | `devicectl` enumerated 16 registered device records; names and identifiers are suppressed. Connected physical-device release proof is not yet verified. |

## Apple release inspector

`apple-release doctor` passed:

```text
Xcode 26.6 (17F113); iOS SDK 26.5; macOS SDK 26.5
```

`apple-release inspect --json` exited 65 with the exact fail-closed result:

```json
{"command":"inspect","error":{"code":"project-ambiguous","gate":"projectConfiguration","message":"Expected exactly one top-level Xcode project or workspace, found 0"},"ok":false}
```

No top-level Xcode project or workspace, application targets, shared archive schemes, app entitlements, asset catalog, or privacy manifests exist at this source boundary.

## Signing and provisioning inventory

- One installed Apple Distribution signing identity exists for Team `2NY8A789TN`.
- Seven provisioning-profile files were inventoried without persisting their payloads.
- Zero installed macOS profiles match Team `2NY8A789TN` and bundle identifier `com.literatureatlas.app`.
- Distribution signing is therefore blocked at the profile gate. The identity alone does not establish package readiness.

## Quality and dependency evidence

| Gate | Result | Evidence |
| --- | --- | --- |
| GitHub Actions run `29124436038` | PASS, incomplete release coverage | Completed successfully for source commit `010769162d824192310bf9236ffe188ef9fba7c4`; workflow only builds the Rust FFI and conditionally runs Swift tests. It does not cover Python, strict Rust lint, Xcode app targets, Release builds, archives, signing, privacy manifests, or runtime proof. |
| Swift tests | PASS | 51 tests executed, 0 failures, 1 opt-in ingestion smoke skipped. |
| Python tests | PASS | 9 of 9 passed. |
| Python lint | PASS | Ruff lint passed. |
| Python format check | FAIL | Ruff would reformat `analytics/__init__.py`, `analytics/rebuild_analytics.py`, and `analytics/tests/test_rebuild_analytics_unit.py`. |
| Rust tests | PASS | 3 of 3 passed. |
| Rust format | PASS | `cargo fmt --check` passed. |
| Strict Rust clippy | FAIL | Three `clippy::useless_vec` findings occur in test fixtures in `analytics/ffi/src/lib.rs` at the edge-list sites beginning near lines 331, 355, and 384. |
| Rust dependency audit | FAIL | `cargo audit` reports `bytes` advisory `RUSTSEC-2026-0007` and `crossbeam-epoch` advisory `RUSTSEC-2026-0204`. |
| Python lock consistency | FAIL | `uv lock --check` reports the committed lock is stale. No dependency or lockfile mutation is part of Task 1. |

## Validated security and privacy preflight blockers

The completed preflight security review validated these P1 App Store architecture blockers:

- `Sources/LiteratureAtlas/App/AppModel.swift:1467` through `:1567` installs dependencies and executes an external Python interpreter at runtime. App Store builds must be self-contained and cannot rely on separately installed executable code.
- `Sources/LiteratureAtlas/Services/AtlasFFI.swift:10` through `:19` loads the Rust library from relative paths with `dlopen`; an archive needs a deterministic embedded, signed library or the existing pure-Swift fallback.
- `Sources/LiteratureAtlas/Services/AppPaths.swift:4` through `:38` derives mutable `Output` and immutable `Prompts` locations from repository/current-working-directory state, which is incompatible with a sandboxed installed app.
- The repository has no Xcode app targets, application manifests, or entitlements at the captured source boundary.

Required-reason API preflight identified file timestamp reason `3B52.1` for user-granted files and `C617.1` for app-container files. Those codes must be reconciled against the final packaged behavior. Owner attestation remains required for all App Store Connect collected-data claims; no claim is inferred from source inspection.

The current product behavior reads selected macOS source folders and does not modify them. The least-privilege packaging direction is therefore `com.apple.security.files.user-selected.read-only`, not read-write.

## Initial gate matrix

| Gate | Status | Evidence | Owner | Next action |
| --- | --- | --- | --- | --- |
| Immutable source coordinate | PASS | Source commit captured and digest-bound | Release engineering | Preserve this coordinate in later reports. |
| Current Apple SDK floor | PASS | Official Apple sources retrieved 2026-07-15; installed Xcode/SDK exceeds the iOS/iPadOS 26 floor | Release engineering | Refresh before upload if the requirement snapshot becomes stale. |
| Xcode application packaging | BLOCKED | Inspector found 0 projects/workspaces and returned `project-ambiguous` | Task 2 implementation | Add deterministic macOS/iOS application targets, manifests, schemes, assets, entitlements, and privacy manifests. |
| App Store architecture | BLOCKED | External Python execution, relative `dlopen`, and repo/CWD paths are validated P1 findings | Tasks 2, 3, and 7 | Remove or package each dependency/path assumption and prove both target builds. |
| Distribution identity | PASS | Apple Distribution identity exists for Team `2NY8A789TN` | Owner and release engineering | Confirm this is the intended App Store team before signing. |
| macOS distribution profile | BLOCKED | No installed matching profile for `com.literatureatlas.app` | Owner | Supply/select a matching Mac App Store profile without committing its payload. |
| CI | INCOMPLETE | Run `29124436038` passed but omits release targets and several quality gates | Task 4 implementation | Add release configuration and application build coverage after local gates are green. |
| Swift tests | PASS | 51 tests, 0 failures, 1 explicit opt-in skip | Task 4 implementation | Run the opt-in smoke and archive-specific checks later. |
| Python tests and lint | PASS | 9 tests and Ruff lint passed | Task 4 implementation | Preserve while repairing the lock and format gates. |
| Python format | FAIL | Three named analytics files require formatting | Task 4 implementation | Format intentionally and rerun lint/tests. |
| Rust tests and format | PASS | 3 tests and format check passed | Task 4 implementation | Preserve while repairing strict lint. |
| Strict Rust clippy | FAIL | Three `useless_vec` test findings | Task 4 implementation | Replace the test-only vectors with arrays and rerun strict clippy/tests. |
| Dependency advisories | FAIL | Two Rust advisories; Python lock is stale | Task 7 implementation | Upgrade/resolve advisories and refresh the lock with regression validation. |
| Privacy manifest and collected-data claims | BLOCKED | No manifest; reason codes identified; owner claims not attested | Task 2 implementation and owner | Add validated required-reason declarations and collect owner attestations. |
| Physical-device runtime proof | NOT YET VERIFIED | Inventory captured without a connected-device functional run | Owner and Task 5 verification | Run the first-release device matrix on an authorized device. |
| Archive, App Store validation, and upload | NOT YET VERIFIED | No application target or archive exists | Tasks 8 and 9; owner for external action | Complete all earlier gates before creating and validating immutable archives. |

## Preflight verdict

`blocked:external-and-repository`

The repository has a usable production toolchain, a passing baseline CI run, and a distribution identity, but it is not repo-ready, package-ready, release-candidate ready, or ready for App Store Connect upload. Packaging, architecture, strict quality, dependency, privacy, provisioning, runtime, archive, metadata, and owner-attestation gates remain open.
