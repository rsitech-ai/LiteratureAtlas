# TODO

## Tasks
- [x] Preflight repository, Apple requirements, toolchain, targets, identities, profiles, CI, and dependencies (DoD: initial gate matrix has current command evidence, owner, and next action for every non-PASS row)
- [ ] Add deterministic macOS/iOS Xcode application packaging (DoD: generated project exposes shared Release schemes, platform app targets, centralized version/bundle settings, entitlements, privacy manifests, and valid icons)
- [ ] Validate Release configuration (DoD: XcodeGen generation plus macOS and iOS Release builds pass and configuration assertions detect missing release metadata)
- [ ] Verify Swift/Rust/Python quality gates (DoD: all applicable format, lint, build, and tests pass with fresh logs, or each deterministic failure is fixed with regression coverage)
- [ ] Verify iOS 26 production-track runtime behavior (DoD: app installs, launches, and has captured iPhone/iPad UI, accessibility, lifecycle, and log evidence for available runtimes)
- [ ] Verify OS 27 compatibility track (DoD: available OS 27 simulator builds/runs are captured separately and no beta toolchain is used for production archives)
- [ ] Verify macOS runtime, sandbox, signing, accessibility, performance, and memory (DoD: built bundle is launched and inspected with native tools; unavailable device-only proof is named)
- [ ] Complete security, privacy, dependency, and App Review audit (DoD: validated findings are fixed or assigned; privacy map and owner-only declarations are explicit)
- [ ] Prepare versioned App Store dossier and truthful assets (DoD: `docs/release/1.0.0/` contains all required reports, manifest, real screenshots, and explicit blockers)
- [ ] Create and validate production archives (DoD: fresh macOS/iOS archives are inspected and validation/signing results are recorded without unauthorized Apple-account mutations)
- [ ] Run final independent verification (DoD: all relevant tests/builds/runtime/archive/diff/CI gates are rerun and every gate has fresh evidence)
- [ ] Memory update: record durable packaging and release commands (DoD: `MEMORY.md` contains only concise evergreen facts and decisions)
- [ ] GitHub change management (DoD: intentional cohesive commits are pushed to the release branch and a draft PR records status/evidence; no merge or tag occurs)

## In progress
- [ ] Complete deterministic packaging with reviewed icon artwork and green platform Release builds.

## Done
- [x] HQ session bootstrap completed.
- [x] Clean isolated release worktree and branch created.
- [x] Initial release-gate matrix published and execution continued.
- [x] Immutable preflight evidence and digest manifest captured for source commit `010769162d824192310bf9236ffe188ef9fba7c4`.
- [x] Deterministic XcodeGen project, macOS/iOS app targets, shared Archive schemes, centralized release settings, platform plists, least-privilege entitlements, and required-reason privacy manifests added.
