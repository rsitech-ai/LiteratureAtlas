# Plan

## Context
- Prepare every shipping LiteratureAtlas Apple target for production App Store submission with fresh, evidence-backed build, runtime, security, privacy, signing, archive, metadata, and validation gates.
- The repository currently contains one SwiftPM executable product that declares macOS 26 and iOS 26, but no Xcode application project/workspace, App Store archive configuration, asset catalog, entitlements, privacy manifest, or versioned release dossier.
- The release inspector currently fails with `project-ambiguous` because it finds zero Xcode projects/workspaces.

## Assumptions
- The existing local bundle identity `com.literatureatlas.app` is the intended macOS identifier until owner/App Store Connect evidence says otherwise.
- The iOS companion will use the reversible local default `com.literatureatlas.app.ios`; registration or App Store Connect selection remains owner/account-confirmed.
- Version `1.0.0` and build `1` are the first-release defaults unless tags, App Store Connect, or owner evidence establishes another coordinate.
- Mac App Store and iOS App Store are the shipping channels; Developer ID notarization is not in scope.
- The Rust FFI is optional at runtime and the pure-Swift fallback may ship if embedding the Rust binary would weaken reproducibility or signing confidence.

## Constraints
- Keep the existing SwiftPM package and test workflow working.
- Use Xcode 26.6 / 26.5 SDKs for production archives because Apple currently accepts Xcode 26+ and OS 26 SDK submissions; use OS 27 runtimes only for compatibility testing.
- Do not upload, distribute through TestFlight, submit for review, change App Store Connect state, merge, tag, or release without the exact approval required by the Apple release workflow and repository authority contract.
- Do not invent privacy, age-rating, export, content-rights, DSA trader, pricing, storefront, reviewer-contact, or support/privacy URL answers.
- Preserve the original clean `main` checkout and work only in the isolated release worktree.

## Options considered
1. Keep the SwiftPM executable and extend the existing ad-hoc bundle script into a hand-built distribution bundle.
2. Add a generated Xcode project with explicit macOS and iOS app targets while retaining SwiftPM for library-style build/test coverage.
3. Replace SwiftPM entirely with a manually maintained Xcode project.

Chosen: 2 because App Store archives need explicit product types, bundle metadata, schemes, assets, entitlements, signing settings, and platform-specific destinations, while the existing SwiftPM workflow is valuable and should remain intact.

## Execution plan
1. Capture repository, machine, Apple requirement, target, dependency, CI, signing, profile, and release-tool preflight evidence.
2. Add `project.yml`, shared configuration files, platform Info plists, entitlements, privacy manifests, asset catalogs, and shared Release schemes; generate `LiteratureAtlas.xcodeproj` deterministically with XcodeGen 2.45.4.
3. Add focused validation that proves both application targets expose the intended version/build, bundle IDs, deployment floors, sandbox capabilities, privacy manifests, icons, and Release archive actions.
4. Build Rust/Python/Swift dependencies and run all configured format, lint, unit, integration, and Release build gates.
5. Build/install/launch the iOS app on representative OS 26 iPhone/iPad simulators and OS 27 compatibility simulators; capture screenshots, UI/accessibility evidence, logs, and platform-specific defects.
6. Build/run the macOS app through the stable bundle workflow and Xcode target; inspect sandbox behavior, bundle structure, architectures, signatures, entitlements, logs, accessibility, memory, and focused performance evidence.
7. Run repository security and final-diff scans; reconcile required-reason APIs, privacy manifests, local data flow, logging, dependencies, licenses, and App Review policy.
8. Prepare truthful metadata drafts, review notes, release notes, screenshot/icon evidence, owner-attestation blockers, and the versioned `docs/release/1.0.0/` dossier.
9. Produce fresh unsigned or locally signed archives first, then distribution-signed archives only when installed identities/profiles match without external account mutation; validate every archive with locally available Apple tooling.
10. Re-run all relevant tests, Release builds, runtime smokes, signing/entitlement inspection, final diff checks, and CI; update the gate matrix and exact final verdict.
11. Commit only intentional cohesive files, push the release-hardening branch, and open a draft PR because the user explicitly requested Phase 10 GitHub change management; do not merge or tag.

## Test plan
- `cargo fmt --check --manifest-path analytics/ffi/Cargo.toml`
- `cargo clippy --manifest-path analytics/ffi/Cargo.toml -- -D warnings`
- `cargo test --manifest-path analytics/ffi/Cargo.toml`
- `.venv/bin/python -m ruff format --check analytics scripts`
- `.venv/bin/python -m ruff check analytics scripts`
- `.venv/bin/python -m pytest analytics/tests -v`
- `swift build`
- `swift test`
- `xcodegen generate --spec project.yml`
- `xcodebuild -project LiteratureAtlas.xcodeproj -scheme LiteratureAtlas-macOS -configuration Release -destination 'generic/platform=macOS' build`
- `xcodebuild -project LiteratureAtlas.xcodeproj -scheme LiteratureAtlas-iOS -configuration Release -destination 'generic/platform=iOS Simulator' build`
- iOS simulator install/launch/screenshot/log checks on iPhone and iPad for OS 26 and OS 27 where the generated target builds.
- `./script/build_and_run.sh --verify` plus macOS log, `codesign`, `plutil`, `file`, `lipo`, and `xattr` inspection.
- Fresh `xcodebuild archive` for each shipping platform and archive bundle/signing/entitlement/dSYM inspection.
- GitHub Actions status inspection after the draft PR is pushed.

## Risks and rollback
- Xcode target compilation exposes iOS/macOS source incompatibilities -> add the smallest availability/platform guard with a failing regression or Release build reproducer; revert individual focused commits if behavior regresses.
- Bundle IDs or version coordinates differ from App Store Connect -> keep values centralized in `.xcconfig`, mark account confirmation blocked, and change only those centralized values after owner evidence.
- Rust FFI cannot be embedded reproducibly or signed for all declared architectures -> ship the existing pure-Swift fallback and document the performance tradeoff rather than include an unverifiable binary.
- Required privacy/legal answers are unavailable -> keep machine-verifiable work moving, name the owner-only blocker, and do not claim submission readiness.
- No matching App Store provisioning profile is installed -> retain unsigned/local archive evidence and classify distribution signing/validation as `BLOCKED`, never trigger automatic account mutations without approval.
- Generated Xcode project drifts -> regenerate from `project.yml` and review the deterministic diff; rollback is removal of the generated project/resources without touching the SwiftPM source tree.

## Memory impact
- Record the durable dual-track project boundary, deterministic XcodeGen command, production/compatibility toolchain split, release validation commands, bundle/version centralization, and any confirmed packaging pitfalls.

## Notes / Results (fill in at end)
- Changes: Completed the immutable release preflight boundary, then added a deterministic XcodeGen specification with separate macOS/iOS application targets, centralized release coordinates, platform Info plists, least-privilege entitlements, required-reason privacy manifests, shared schemes, and a structurally valid asset catalog.
- Tests run: `jq` manifest validation and SHA-256 reconciliation; `plutil -lint` for all platform plists; `xcodegen generate --spec project.yml` twice with identical generated-project digests; `xcodebuild -list -json`; Release `-showBuildSettings` inspection for both schemes.
- Tradeoffs: The app targets intentionally compile the pure-Swift fallback without embedding Rust. Real app-icon artwork is not fabricated by the packaging task and remains a release gate. Bundle IDs and version/build are centralized reversible defaults; the Apple Team remains unset pending owner/account confirmation.
