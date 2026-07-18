# TODO

## Tasks
- [x] Inventory cleanup, GitHub, and Apple release state (DoD: exact cleanup candidates, release history, identity/notary status, and authority boundary are documented)
- [x] Clean generated/stale artifacts (DoD: only verified irrelevant artifacts removed; `Output/`, active environments, working data, and evidence preserved)
- [x] Fresh pre-PR verification (DoD: relevant Swift/Python/Rust/release/runtime gates pass on the exact branch head)
- [x] Create and inspect PR (DoD: branch pushed, ready PR created against `main`, rendered metadata and full diff reviewed)
- [x] Hosted and independent PR review (DoD: exact-head checks green and no unresolved actionable findings remain)
- [x] Merge through PR and synchronize `main` (DoD: PR merged; local `main`, `origin/main`, and merge result match)
- [x] Build and verify downloadable app (DoD: artifact built from merged `main`; bundle, signature mode, metadata, checksum, DMG, launch, and logs verified)
- [x] Publish and re-check release (DoD: truthful release and downloadable asset are available; remote metadata/checksum match local evidence)
- [x] Memory update and closeout (DoD: PLAN/TODO/MEMORY reflect exact final evidence and repository is clean)

## In progress
- None.

## Done
- [x] New-day HQ bootstrap and repository continuity check passed.
- [x] Previous full-quality remediation confirmed committed on `feat/andrzej_fix_full_quality_audit` with a clean worktree before closeout planning.
- [x] No existing GitHub tags or Releases were present; official publication remains blocked by production artwork and unproven notarization credentials.
- [x] Stopped the stale development app and moved 12 exact generated/cache targets (about 1.39 GiB) to Trash while preserving corpus data, examples, the analytics environment, and tracked evidence.
- [x] Cold-cache verification passed: 84 XCTest cases (one opt-in corpus smoke skipped), four Swift Testing cases, 54 Python tests, seven Rust tests, formatting/linting/security audits, release policy/config/privacy gates, deterministic XcodeGen parity, macOS/iPadOS Release builds, and fresh app launch/log inspection.
- [x] Ready PR #9 created against `main` from `feat/andrzej_fix_full_quality_audit` and the rendered scope/diff inspected.
- [x] Reproduced and repaired all four independent-review findings: stale UUID references outside `paper_metrics`, invalid Python paper IDs, malformed method-pipeline steps, and nearest-neighbor sizing after invalid claims are filtered.
- [x] Re-ran the focused/full repair gates: Ruff passed, 53 Python tests passed, 84 XCTest cases passed with one opt-in smoke skipped, and all four Swift Testing bookmark cases passed.
- [x] Corrected re-review setup drift: Python 3.12, `analytics/.venv`, Xcode 26.6, managed analytics/release commands, distributed storage/FFI boundaries, and current Swift test coverage now match the repository runtime.
- [x] Removed adjacent stale distribution guidance from `prompts.txt`: public fixtures, shipped FFI, storage paths, release boundaries, and task-tracking guidance now match the current product contract.
- [x] Preserved canonical Swift UUID casing after Python validation so uppercase paper IDs continue to join chunks and other persisted artifacts; added a real paper/chunk regression and passed all 54 Python tests.
- [x] Final exact-head review passed: ten hosted checks green, GitHub Codex no-major-issue verdict, independent GO, all three threads resolved, and no remaining actionable finding.
- [x] PR #9 merged as `95d0031a0ee67a9f91cd0d915de75e1f42137daa`; reviewed head and merge trees matched, and local/remote `main` synchronized.
- [x] Built, verified, DMG-packaged, relocated-launched, published, downloaded, and byte-compared `v1.0.0-community.1` with checksum and exact-app SPDX SBOM.
