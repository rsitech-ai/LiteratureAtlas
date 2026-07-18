# Plan

## Context
- Complete the already-validated full-quality remediation through cleanup, hosted review, merge to `main`, and a downloadable macOS release artifact.
- The user explicitly authorized repository cleanup, PR creation, hosted review, merge/push to `main`, and publication of the latest downloadable app.

## Assumptions
- The primary download target is the documented Apple Silicon macOS 26+ direct-download app.
- `Output/`, the active analytics environment, working corpus data, and validated release evidence are not irrelevant files and must be preserved.
- A public community prerelease is acceptable only when it is labeled truthfully as ad-hoc signed/not notarized; it must not be represented as the official Developer ID release.

## Constraints
- Preserve all user data and unrelated work; remove only exact, reproducible generated artifacts or stale remote release assets proven superseded.
- Merge only through a reviewed PR with passing hosted checks and no unresolved actionable review findings.
- Build the downloadable artifact from the exact merged `main` commit, then verify the bundle, signature mode, mounted DMG contents, checksums, and launch behavior.
- Do not bypass the fail-closed app-icon, Developer ID, notarization, legal-provenance, or GitHub-policy gates.

## Options considered
1. Publish an official Developer ID-signed and Apple-notarized release after all release-configuration, identity, and notary gates pass.
2. If an official release remains externally blocked, publish a clearly labeled community prerelease built from merged `main`, with exact limitations and verification evidence.
3. Stop after merging the PR and leave the binary local-only.

Chosen: attempt 1 first and fall back to 2 only for verified external blockers. Option 3 does not satisfy the requested downloadable release.

## Execution plan
1. Inventory Git state, hosted repository state, existing releases/tags/assets, signing/notary prerequisites, and exact cleanup candidates.
2. Remove only approved generated clutter using recoverable deletion where practical; preserve working data and evidence.
3. Run a fresh pre-push verification matrix and inspect the complete `origin/main...HEAD` diff.
4. Commit any closeout documentation changes, push the feature branch, create a ready-for-review PR, and inspect the rendered PR/diff.
5. Wait for hosted checks, review comments, and an independent exact-head review; repair and re-verify any actionable issue.
6. Merge through the PR only when all gates pass, synchronize local `main`, and verify exact local/remote/merge parity.
7. Build the latest macOS app from merged `main`, create and verify the distributable, publish the truthful GitHub release, and verify its downloadable asset metadata.
8. Update PLAN/TODO/MEMORY with exact final evidence and run final post-release cleanliness checks.

## Test plan
- Pre-PR: warning-free Swift tests, Python Ruff/tests/audit, Rust fmt/Clippy/tests/audit, release policy/configuration, privacy/entitlement validation, and canonical bundle runtime smoke.
- Hosted: all required GitHub Actions checks green on the exact PR head; no unresolved actionable review threads or comments.
- Post-merge: local `main` equals `origin/main`; repeat the strongest relevant release/build/runtime checks on the merge commit.
- Distribution: verify app structure, architecture, bundle metadata, signature mode, DMG mount/content equality, checksum, source revision, and launch/log behavior.

## Risks and rollback
- Cleanup could remove user data -> restrict targets to enumerated generated files and use Trash for material local artifacts.
- Hosted review could expose a regression -> keep the branch alive, fix on the branch, and require fresh checks before merge.
- Official distribution may be blocked by owner/Apple prerequisites -> publish only the explicitly labeled community prerelease and retain the exact official blocker.
- A release asset could be built from the wrong commit -> embed and verify the merged source revision before upload; delete/replace only the newly created incorrect release if verification fails.

## Memory impact
- Record the exact merged commit, PR/release URLs, verified release command, artifact labeling, and durable cleanup boundary if any changed.

## Notes / Results
- Changes:
- Cleanup: No old GitHub Releases/tags or repo-local DMGs/archives existed. Stopped the stale development app and moved 12 exact generated/cache targets (about 1.39 GiB) to Trash; preserved `Output/`, `examples/`, `analytics/.venv`, release/audit evidence, user configuration, and unmerged work.
- Tests run: Cold-cache Swift warning-as-error suite (84 XCTest, one opt-in corpus smoke skipped, plus four Swift Testing bookmark cases); Python Ruff format/check, 53 pytest cases, and pip-audit; Rust fmt/strict Clippy, seven tests, Release build, and RustSec (only the documented allowed unmaintained `bincode 1.3.3` warning); release-script policy, configuration with only `app_icon_artwork` allowed, privacy manifests, CI YAML, deterministic XcodeGen parity, macOS and generic iPadOS Release builds; canonical app-bundle rebuild/launch and process-specific log inspection.
- PR and merge: Ready PR #9 (`feat/andrzej_fix_full_quality_audit` -> `main`) created after the cold-cache local matrix and complete pre-push diff review. Independent review placed the first head on HOLD; four reproduced analytics-contract defects were repaired with regression tests. Exact-head re-review then found and corrected stale Python/runtime setup guidance before merge; the final head still requires fresh hosted/exact-head approval.
- Release:
- Tradeoffs/blockers: Official distribution is currently blocked by `app_icon_artwork` and unproven noninteractive notary credentials. A valid Developer ID Application certificate is installed, but its private-key authorization and a `LiteratureAtlasNotary` profile have not been proven; fall back only to a clearly labeled ad-hoc/not-notarized community prerelease.
