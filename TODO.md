# TODO

## Tasks
- [x] Inventory cleanup, GitHub, and Apple release state (DoD: exact cleanup candidates, release history, identity/notary status, and authority boundary are documented)
- [x] Clean generated/stale artifacts (DoD: only verified irrelevant artifacts removed; `Output/`, active environments, working data, and evidence preserved)
- [x] Fresh pre-PR verification (DoD: relevant Swift/Python/Rust/release/runtime gates pass on the exact branch head)
- [ ] Create and inspect PR (DoD: branch pushed, ready PR created against `main`, rendered metadata and full diff reviewed)
- [ ] Hosted and independent PR review (DoD: exact-head checks green and no unresolved actionable findings remain)
- [ ] Merge through PR and synchronize `main` (DoD: PR merged; local `main`, `origin/main`, and merge result match)
- [ ] Build and verify downloadable app (DoD: artifact built from merged `main`; bundle, signature mode, metadata, checksum, DMG, launch, and logs verified)
- [ ] Publish and re-check release (DoD: truthful release and downloadable asset are available; remote metadata/checksum match local evidence)
- [ ] Memory update and closeout (DoD: PLAN/TODO/MEMORY reflect exact final evidence and repository is clean)

## In progress
- [ ] Create and inspect PR

## Done
- [x] New-day HQ bootstrap and repository continuity check passed.
- [x] Previous full-quality remediation confirmed committed on `feat/andrzej_fix_full_quality_audit` with a clean worktree before closeout planning.
- [x] No existing GitHub tags or Releases were present; official publication remains blocked by production artwork and unproven notarization credentials.
- [x] Stopped the stale development app and moved 12 exact generated/cache targets (about 1.39 GiB) to Trash while preserving corpus data, examples, the analytics environment, and tracked evidence.
- [x] Cold-cache verification passed: 83 XCTest cases (one opt-in corpus smoke skipped), four Swift Testing cases, 50 Python tests, seven Rust tests, formatting/linting/security audits, release policy/config/privacy gates, deterministic XcodeGen parity, macOS/iPadOS Release builds, and fresh app launch/log inspection.
