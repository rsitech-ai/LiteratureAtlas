# TODO

## Tasks
- [x] Swift source access and persistence integrity (DoD: iPad/macOS bookmarks survive relaunch; pin/rename/review writes are transactional and surface failures; focused tests pass)
- [x] Swift cancellation and model-degraded operation (DoD: expensive clustering/layout work cooperatively stops and the corpus remains readable when generation is unavailable; focused tests pass)
- [x] Analytics input/freshness integrity (DoD: duplicate/malformed/non-finite/stale analytics fail safely with actionable UI, current data loads, and no trapping dictionaries remain)
- [x] Python analytics correctness and scalability (DoD: rank-deficient PCA, nested claims, malformed chunks, custom DB paths, separability errors, and kNN scale have red-green regressions)
- [x] Rust FFI graph contract (DoD: zero-weight edge presence is consistent with the public non-negative contract and strict Rust gates pass)
- [x] SwiftUI correctness and accessibility (DoD: stable identities, bounded layouts/charts, correct year semantics, action labels/help, native commands, and no render-time filesystem scans on audited surfaces)
- [x] Runtime performance and logs (DoD: Release idle sample and full interaction log scan show no reproduced app-owned invalid-frame, huge-layer, duplicate-ID, crash, or persistent high-idle-CPU defect)
- [x] Release artifact and supply-chain hardening (DoD: exact read-only entitlement and privacy reasons are verified, dependency audit is frozen in CI, supported versions are tested, and release tests pass)
- [x] Documentation and dead-code reconciliation (DoD: privacy/release/SBOM statements match behavior and every confirmed unreferenced production helper is removed or documented as intentional)
- [x] Full end-to-end verification (DoD: Swift/Python/Rust/release/security/build gates, macOS app relaunch/interaction, iPad build, and final diff review are green)
- [x] Memory update (DoD: `MEMORY.md` contains only new durable facts and no secrets/task-history noise)

## In progress
- None.

## Done
- [x] HQ session bootstrap, repository instructions, durable memory, historical plan/TODO, and exact Git baseline reviewed.
- [x] Dedicated branch `feat/andrzej_fix_full_quality_audit` created from clean `cd7bb74` main.
- [x] Improve-mode product contract established: preserve `Output/`, verify real macOS runtime, build-check iPadOS, and keep external release gates blocked.
- [x] All repository-owned remediation, full verification, runtime proof, documentation, memory, and final review completed on the feature branch.

## External / owner-controlled blockers
- Approved production app icon/brand provenance and legal chain of title.
- Developer ID private-key authorization, notarization upload, quarantine/hardware acceptance, tag, and public binary release.
- Owner-controlled GitHub repository protection, private reporting, and security settings.
