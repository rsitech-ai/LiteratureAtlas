# LiteratureAtlas App Store Release Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the existing cross-platform SwiftPM executable into verifiable macOS and iOS App Store application targets, harden every locally actionable release gate, and produce a truthful versioned release dossier.

**Architecture:** Keep `Package.swift` as the development and unit-test boundary. Add a deterministic XcodeGen specification that compiles the same source tree into separate macOS and iOS application products with centralized release coordinates, platform resources, entitlements, privacy manifests, and shared archive schemes. Store fresh evidence outside committed binaries and summarize sanitized results under `docs/release/1.0.0/`.

**Tech Stack:** Swift 6.3, SwiftUI, Xcode 26.6, XcodeGen 2.45.4, SwiftPM, XCTest, Rust/Cargo, Python/pytest/ruff, App Sandbox, Apple distribution tooling.

## Global Constraints

- Production archives use Xcode 26.6 and the installed 26.5 SDKs; OS 27 runtimes form a separate compatibility track.
- Deployment targets remain macOS 26.0 and iOS 26.0 because Foundation Models APIs are a core product dependency.
- No new runtime dependencies are introduced.
- Existing SwiftPM builds/tests remain supported.
- App Store Connect mutations, uploads, review submission, releases, legal declarations, and account changes remain approval-gated.
- `com.literatureatlas.app`, `com.literatureatlas.app.ios`, version `1.0.0`, and build `1` are centralized reversible defaults pending owner/account confirmation.

---

### Task 1: Capture the immutable preflight boundary

**Files:**
- Modify: `PLAN.md`
- Modify: `TODO.md`
- Create: `docs/release/1.0.0/TEST_EVIDENCE.md`
- Create: `docs/release/1.0.0/RELEASE_MANIFEST.json`

**Interfaces:**
- Consumes: clean source commit `010769162d824192310bf9236ffe188ef9fba7c4`
- Produces: timestamped toolchain, source, requirements, target, dependency, identity/profile, and gate evidence referenced by every later report

- [x] Run the Apple release doctor and inspector and record the exact zero-project discovery failure.
- [x] Capture `git`, Xcode, SDK, simulator, device, Swift, Cargo, Python, GitHub CLI, signing identity, and provisioning-profile inventory without storing credentials.
- [x] Record current official Apple source URLs and the 2026-07-15 retrieval date.
- [x] Create a valid JSON manifest whose paths and SHA-256 digests identify committed release evidence without including archives or sensitive logs.

### Task 2: Add deterministic Xcode application targets

**Files:**
- Create: `project.yml`
- Create: `Config/Shared.xcconfig`
- Create: `Config/Debug.xcconfig`
- Create: `Config/Release.xcconfig`
- Create: `Resources/macOS/Info.plist`
- Create: `Resources/macOS/LiteratureAtlas.entitlements`
- Create: `Resources/macOS/PrivacyInfo.xcprivacy`
- Create: `Resources/iOS/Info.plist`
- Create: `Resources/iOS/LiteratureAtlas.entitlements`
- Create: `Resources/iOS/PrivacyInfo.xcprivacy`
- Create: `Resources/Shared/Assets.xcassets/Contents.json`
- Create: `Resources/Shared/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `LiteratureAtlas.xcodeproj/project.pbxproj`
- Create: `LiteratureAtlas.xcodeproj/xcshareddata/xcschemes/LiteratureAtlas-macOS.xcscheme`
- Create: `LiteratureAtlas.xcodeproj/xcshareddata/xcschemes/LiteratureAtlas-iOS.xcscheme`

**Interfaces:**
- Consumes: `Sources/LiteratureAtlas/**`, macOS/iOS 26 platform floors, centralized bundle/version defaults
- Produces: `LiteratureAtlas-macOS.app` and `LiteratureAtlas-iOS.app` Release products with archive actions

- [ ] Write `project.yml` with separate `application` targets, shared sources, platform-specific resource directories, automatic local signing style, hardened Release settings, and shared schemes.
- [ ] Write Info plists with `CFBundleShortVersionString=$(MARKETING_VERSION)`, `CFBundleVersion=$(CURRENT_PROJECT_VERSION)`, supported orientation/device declarations, and no invented permission strings.
- [ ] Write least-privilege entitlements: App Sandbox plus user-selected read-only file access on macOS; an empty iOS entitlement dictionary unless a verified capability requires more.
- [ ] Add privacy manifests that declare no tracking and list only validated required-reason API categories/reasons; do not claim `NSPrivacyCollectedDataTypes` is empty until owner attestation and final packaged-data-flow reconciliation support that declaration.
- [ ] Generate `LiteratureAtlas.xcodeproj` using `xcodegen generate --spec project.yml` and review the generated diff.

### Task 3: Prove release configuration and platform compilation

**Files:**
- Create: `scripts/validate_release_configuration.py`
- Create: `analytics/tests/test_release_configuration.py`
- Modify: source files only when an exact iOS/macOS compilation failure requires a minimal guard or API replacement

**Interfaces:**
- Consumes: generated Xcode project and platform resources from Task 2
- Produces: deterministic configuration report plus successful generic macOS and iOS Simulator Release builds

- [ ] Write a failing test that invokes the validator against a fixture missing one required target/resource/setting and asserts a nonzero result with a named gate.
- [ ] Run `.venv/bin/python -m pytest analytics/tests/test_release_configuration.py -v` and verify the test fails because the validator does not exist.
- [ ] Implement the stdlib-only validator to parse Xcode build settings and plists, verify both targets/schemes, coordinates, platform floors, icons, entitlements, privacy manifests, and Release archive actions, and emit JSON.
- [ ] Rerun the focused test and verify it passes.
- [ ] Run XcodeGen and generic macOS/iOS Simulator Release builds; for each deterministic source failure, add the smallest platform guard/replacement and a focused regression where feasible.

### Task 4: Run repository quality gates

**Files:**
- Modify: production/test files only for reproduced deterministic failures
- Modify: `.github/workflows/ci.yml` if CI does not exercise the new application Release targets

**Interfaces:**
- Consumes: production source and generated application targets
- Produces: green Swift, Rust, Python, configuration, and CI-equivalent evidence

- [ ] Run Cargo format, clippy with denied warnings, and tests.
- [ ] Run Python format check, lint, and pytest.
- [ ] Run Swift build and test.
- [ ] Run both Xcode Release builds and inspect warnings/concurrency/deprecations.
- [ ] Add CI steps for deterministic project generation, release validation, and generic application builds when the local commands are green.

### Task 5: Verify iOS production and OS 27 compatibility tracks

**Files:**
- Create: `docs/release/1.0.0/evidence/ios/` screenshots and sanitized text reports
- Modify: source/tests only for reproduced runtime defects

**Interfaces:**
- Consumes: `LiteratureAtlas-iOS.app` Release simulator product
- Produces: separate iOS 26 production-track and iOS 27 compatibility-track install/launch/UI/accessibility/log evidence

- [ ] Build and install on available iOS 26 iPhone and iPad simulators, launch by bundle ID, and capture screenshots plus crash/runtime logs.
- [ ] Repeat on available iOS 27 iPhone and iPad simulators without using Xcode 27 for the production archive.
- [ ] Exercise first launch, relaunch, background/foreground, dark/light mode, accessibility text size, reduced motion, VoiceOver inspection, empty/error/offline-relevant states, and document-import cancellation.
- [ ] Record physical-device-only Foundation Models and file-access behavior as explicit blockers when no authorized connected device can prove them.

### Task 6: Verify macOS runtime and package properties

**Files:**
- Modify: `script/build_and_run.sh`
- Create: `docs/release/1.0.0/evidence/macos/` screenshots and sanitized text reports
- Modify: source/tests only for reproduced runtime defects

**Interfaces:**
- Consumes: `LiteratureAtlas-macOS.app` Release product
- Produces: launch, accessibility, sandbox, bundle, architecture, signing, memory, and focused performance evidence

- [ ] Update the stable script to support an explicit Release/Xcode product without destructive wildcard behavior and keep `--verify` deterministic.
- [ ] Launch the packaged app, exercise primary navigation/import cancellation/window relaunch, and capture screenshots/logs.
- [ ] Inspect Info.plist, privacy manifest, architectures, bundle structure, quarantine attributes, signatures, designated requirement, and entitlements with native tools.
- [ ] Capture comparable memory/performance evidence for launch and major-screen navigation; investigate app-owned retained paths or stalls before making claims.

### Task 7: Resolve security, privacy, and supply-chain gates

**Files:**
- Create: `docs/release/1.0.0/SECURITY_STATUS.md`
- Create: `docs/release/1.0.0/PRIVACY_DATA_MAP.md`
- Modify: source/config/tests only for validated findings

**Interfaces:**
- Consumes: repository scan, final release diff, runtime logging, dependencies, manifests, and app data flows
- Produces: severity-ranked findings, fixed release blockers, dependency/license inventory, privacy reconciliation, and owner-only declarations

- [ ] Run the standard repository security scan and secret/dependency/license checks.
- [ ] Map collected/local data categories, source, purpose, storage, retention/deletion, recipients, tracking, and identity linkage.
- [ ] Reconcile file APIs, privacy manifests, sandbox entitlements, logs, network behavior, and App Review privacy rules.
- [ ] Add regression tests before each feasible security behavior fix and rerun the focused plus full gate.
- [ ] Run a final security diff scan after all changes.

### Task 8: Prepare App Store content and release dossier

**Files:**
- Create: `docs/release/1.0.0/RELEASE_STATUS.md`
- Create: `docs/release/1.0.0/APP_STORE_CHECKLIST.md`
- Create: `docs/release/1.0.0/TEST_EVIDENCE.md`
- Create: `docs/release/1.0.0/APP_REVIEW_NOTES.md`
- Create: `docs/release/1.0.0/RELEASE_NOTES.md`
- Create: `docs/release/1.0.0/BLOCKERS.md`
- Create: `docs/release/1.0.0/RELEASE_MANIFEST.json`

**Interfaces:**
- Consumes: verified functionality, real screenshots, official requirements, scan results, archive results, and owner attestations
- Produces: the complete truthful versioned handoff required by the mission

- [ ] Draft platform metadata within current field limits using only verified functionality.
- [ ] Use real application captures for screenshots and validate dimensions/no-alpha requirements.
- [ ] Record missing support/privacy URLs, contact, DSA, age rating, export, content rights, pricing, territories, and release-control choices as owner blockers rather than invented answers.
- [ ] Populate every required release-status section and ensure the JSON manifest validates and references current digests.

### Task 9: Archive, inspect, validate, and reconcile GitHub

**Files:**
- Modify: release dossier evidence and status files
- Modify: `MEMORY.md`
- Modify: `PLAN.md`
- Modify: `TODO.md`

**Interfaces:**
- Consumes: clean Release targets, signing identities/profiles, final source digest, metadata digest, and all fresh gates
- Produces: immutable archive coordinates, exact verdict, durable commands, cohesive commits, draft PR, and CI reconciliation

- [ ] Create fresh macOS and iOS archives from the isolated worktree; never commit archives.
- [ ] Inspect configuration, bundle IDs, Team IDs, profiles, entitlements, nested code, dSYMs, UUIDs, architectures, icons, resources, and privacy manifests.
- [ ] Validate archives with locally available Apple tooling; if App Store validation requires account access or matching profiles, mark the exact external blocker.
- [ ] Re-run all relevant tests, Release builds, runtime smokes, signing inspection, final diff review, and gate-table reconciliation.
- [ ] Update `MEMORY.md`, final plan notes, and fully checked/accurately blocked TODO state.
- [ ] Commit intentional cohesive changes, push `feat/andrzej_literatureatlas_release_20260715`, open a draft PR, and inspect GitHub Actions without merging or tagging.
