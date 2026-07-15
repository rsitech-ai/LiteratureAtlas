# TODO

## Tasks
- [x] Preflight repository, Apple requirements, toolchain, targets, identities, profiles, CI, and dependencies (DoD: initial gate matrix has current command evidence, owner, and next action for every non-PASS row)
- [x] Add deterministic macOS/iPadOS Xcode application packaging (DoD: generated project exposes shared Release schemes, platform app targets, centralized version/bundle settings, entitlements, privacy manifests, and an explicit failing gate for missing approved icon artwork)
- [x] Validate Release configuration (DoD: XcodeGen generation plus macOS and iPadOS Release builds pass and configuration assertions detect missing release metadata)
- [x] Verify Swift/Rust/Python quality gates (DoD: all applicable format, lint, build, and tests pass with fresh logs, and the sole maintenance warning is documented)
- [x] Verify iPadOS 26 production-track runtime behavior (DoD: app installs, launches, navigation behavior is captured, and unavailable physical-device proof is named)
- [x] Verify OS 27 compatibility track (DoD: available OS 27 simulator/host runs are captured separately and no beta toolchain is used for production archives)
- [x] Verify macOS runtime, sandbox, signing, accessibility, performance, and memory (DoD: built bundle is launched and inspected with native tools; unavailable device-only proof is named)
- [x] Complete security, privacy, dependency, and App Review audit package (DoD: validated findings are fixed or assigned; privacy map and owner-only declarations are explicit; exact-head security scan is part of final handoff)
- [x] Prepare versioned App Store dossier and truthful evidence (DoD: `docs/release/1.0.0/` contains required reports, real engineering screenshots, manifest, and explicit blockers; unapproved marketing assets are not represented as complete)
- [x] Create and inspect production archives (DoD: fresh unsigned macOS/iPadOS archives are inspected and distribution signing/validation blockers are recorded without Apple-account mutation)
- [x] Run final independent repository verification (DoD: relevant tests/builds/runtime/archive/diff gates are rerun and every local gate has fresh evidence)
- [x] Memory update: record durable packaging and release commands (DoD: `MEMORY.md` contains only concise evergreen facts and decisions)
- [x] Prepare GitHub change management (DoD: intentional cohesive commits are ready for authorized push/draft PR; no merge or tag occurs)

## In progress
- None. Remaining work is explicitly owner/external and tracked in `docs/release/1.0.0/BLOCKERS.md`.

## Done
- [x] HQ session bootstrap completed.
- [x] Clean isolated release worktree and branch created.
- [x] Initial release-gate matrix published and execution continued.
- [x] Immutable preflight evidence and digest manifest captured for source commit `010769162d824192310bf9236ffe188ef9fba7c4`.
- [x] Deterministic XcodeGen project, macOS/iOS app targets, shared Archive schemes, centralized release settings, platform plists, least-privilege entitlements, and required-reason privacy manifests added.
- [x] Generic macOS and iOS Simulator Release builds pass after platform guards; App Store storage uses Application Support and prompts are bundled.
- [x] App Store compilation excludes external Python, relative Rust dynamic loading, and dormant OpenAI networking; focused validator and path tests pass.
- [x] Final local matrix passed: Swift 55 tests (one opt-in smoke skipped), Python 12 tests, Rust FFI 3 tests, generic Release builds, and fresh unsigned macOS/iPadOS archives.
- [x] Production icon, Apple account/profiles, signed validation, physical-device acceptance, metadata, privacy/legal, and marketing-asset work is packaged as explicit owner blockers rather than marked done.
