# RSI Tech Apache release migration

## Goal

- User-visible outcome: LiteratureAtlas is canonically hosted under `rsitech-ai`, owned by Rafal Sikora, maintained and branded by RSI Tech, licensed Apache-2.0, free of the four unauthorized PDFs in pushable history, and available as a current verified macOS download.
- How to see it working: the org repository and protected `main` show the merged PR; a fresh clone passes the documented verification; the current release downloads from the org and its signature/notary/checksum/SBOM evidence matches the merged source.

## Current State

- Relevant paths: root license/community/governance files, `docs/open-source/`, `docs/release/`, `.github/`, `analytics/`, `script/`, `scripts/`, Xcode project/configuration, and GitHub repository/release/settings.
- Existing behavior: public personal repository under MIT, one ad-hoc/not-notarized prerelease, four PDFs removed from the current tree but still reachable in history and hidden PR refs, extensive green local/hosted release automation, and protected `main`.
- Constraints: no formal Codex Security scan; history rewrite only under explicit authority; PR required for current-tree changes; preserve user data and exact evidence; never infer signing/notary proof.

## Target State

- Desired behavior: sanitized canonical org history; Apache-2.0 plus NOTICE/REUSE/package/SBOM consistency; exact public owner/maintainer/contact/site; green reviewed PR; protected org `main`; current downloadable artifact with verified distribution status.
- Non-goals: Apple App Store submission, physical-device iPad release, deleting user research data, fabricating credentials, or rewriting dependency license metadata.

## Risks and Failure Modes

- History rewrite changes every descendant SHA and invalidates old links/tags as current evidence.
- Importing the existing repository would preserve hidden GitHub PR refs and cached unauthorized blobs.
- License conversion can overreach third-party materials or falsely imply withdrawal of prior MIT grants.
- Apple signing/notarization can fail due to keychain access, missing AppIcon artwork, bundle identity, or Apple service state.
- Cleanup can destroy evidence if targets are not exact.

## Milestones

### M1. Inventory and recovery boundary

- Goal: know exact mutation targets and retain a recoverable pre-rewrite mirror.
- Files / systems: local Git refs, GitHub repository/releases/settings, Keychain identities, license/contact references.
- Changes: plan/TODO only; no external destructive mutation.
- Verification: exact ref/path/release/permission/identity inventories and mirror fsck.
- Expected result: a bounded rewrite/transfer/release sequence with explicit rollback.

### M2. Sanitize and transfer

- Goal: remove the four PDFs from pushable history and establish the canonical org repository.
- Files / systems: disposable mirror, new `rsitech-ai` repository, personal rollback repository, branch protection, refs.
- Changes: rewrite only enumerated PDF paths plus the user's three legacy Git identity forms; publish only rewritten `main`; keep the personal repository public until replacement release verification.
- Verification: `git fsck`, `git log --all -- <paths>`, fresh clone object/path search, GitHub API repo/ref/release/settings checks.
- Expected result: public `rsitech-ai/LiteratureAtlas` has sanitized normal-clone history with no inherited PR/tag/dependabot refs.

### M3. Apache and identity migration

- Goal: make current source/docs/metadata truthful and internally consistent.
- Files / systems: `LICENSE`, `LICENSES/`, `NOTICE`, `REUSE.toml`, package manifests, community/governance/security docs, SBOM generator/inventories, URLs, release docs.
- Changes: Apache-2.0 ownership, RSI Tech maintainer/brand, website/contact/Git URLs; remove superseded tracked material only when proven irrelevant.
- Verification: failing-before/passing-after metadata regressions, REUSE, exact searches, JSON/YAML validation, source SBOM regeneration.
- Expected result: no current project-authored MIT/unknown-owner/personal-repo claim remains except clearly labeled historical facts.

### M4. Product and release validation

- Goal: prove the migration did not regress the native app or distribution pipeline.
- Files / systems: Swift/Python/Rust stacks, release scripts, Xcode archives, runtime app.
- Changes: only validated release fixes found by the matrix.
- Verification: full format/lint/tests/builds/audits, release scripts, macOS/iPadOS archives, community package/DMG, runtime launch/log smoke.
- Expected result: exact feature head is locally release-ready apart from explicitly named external gates.

### M5. PR hardening and merge

- Goal: land current-tree changes through a thoroughly reviewed org PR.
- Files / systems: feature branch, GitHub PR/checks/review threads, protected `main`.
- Changes: fix every blocker/high review finding; keep diff coherent.
- Verification: independent diff review, exact-head hosted checks, clean merge state, post-merge SHA parity.
- Expected result: protected org `main` contains the reviewed migration.

### M6. Exact release and cleanup

- Goal: publish and remotely verify the latest app, then remove superseded generated artifacts.
- Files / systems: exact merged checkout, Developer ID/notary tooling, DMG/checksum/SBOM, GitHub Release, local caches/evidence.
- Changes: add production AppIcon artwork; produce Developer ID-signed/notarized artifact; after remote verification delete the obsolete personal prerelease/tag, make the personal repository private/archived, and delete only proven generated outputs.
- Verification: codesign, entitlements, hardened runtime, notary/staple/Gatekeeper, DMG equality, checksum, SBOM, relocated launch/log smoke, remote byte match.
- Expected result: users can download the current verified artifact from the org repository; retained evidence and remaining blockers are explicit.

## Verification

- `git fsck --full`
- `git log --all -- <four exact PDF paths>`
- `uv sync --project analytics --extra dev --frozen`
- `analytics/.venv/bin/python -m ruff format --check analytics scripts`
- `analytics/.venv/bin/python -m ruff check analytics scripts`
- `analytics/.venv/bin/python -m pytest analytics/tests`
- `swift test -Xswiftc -warnings-as-errors`
- `cargo fmt --manifest-path analytics/ffi/Cargo.toml --check`
- `cargo clippy --locked --manifest-path analytics/ffi/Cargo.toml --all-targets --all-features -- -D warnings`
- `cargo test --locked --manifest-path analytics/ffi/Cargo.toml`
- `scripts/tests/test_release_scripts.sh`
- `scripts/validate_release_configuration.py`
- `reuse lint`
- `./script/build_and_run.sh --verify`
- Manual smoke: launch the relocated exact release app, exercise all primary destinations and one authorized import when available, relaunch, and inspect logs.

## Decision Log

- 2026-07-20: Publish a new sanitized org repository instead of transferring the personal repository; transfer would preserve hidden PR refs rooted after the PDFs. Keep the personal repository only as private archived recovery evidence after replacement verification.
- 2026-07-20: Treat Apache-2.0 as prospective owner-authorized licensing; do not rewrite historical dependency licenses or claim prior MIT grants are withdrawn.
- 2026-07-20: Use installed Developer ID Application Team `2NY8A789TN` for direct distribution. Apple Development/App Store identities are separate lanes.
- 2026-07-20: Use the verified `codebase-combiner-notary` keychain profile for notarization. The missing `LiteratureAtlasNotary` alias is not itself a credential blocker.

## Progress Log

- 2026-07-20: Completed: session bootstrap, authority/org/signing inventory, recoverable history rewrite, fresh-clone verification, and sanitized `rsitech-ai` repository publication.
- 2026-07-20: Completed: Apache-2.0/RSI Tech identity migration, DCO/governance, package/SBOM roots, `ai.rsitech` bundle namespace, production AppIcon, org-compatible workflow cleanup, stale-file cleanup, focused red/green tests, and broad local gates.
- 2026-07-20: Local Xcode archive attempts isolated a system-wide Xcode 26.6 build-service pipe deadlock also affecting unrelated workspaces; direct compiler and asset-catalog tools pass. Added a credential-free exact-SHA unsigned-candidate workflow instead of mutating or terminating other tasks.
- 2026-07-20: Completed: final independent diff review, DCO LicenseRef correction, release-truth cleanup, main-only workflow regression, 65 Python tests, 90 XCTest plus 4 Swift Testing cases, Rust/release/license/configuration gates, exact 252-file source SBOM, and administrator-enforced protected-main policy.
- 2026-07-20: Began signed squash, org PR checks/merge, hosted unsigned build, local signing/notarization, public release, legacy retirement, and closeout.
- 2026-07-21: Completed migration PR #4 and exact-main hosted build, local Developer ID signing, Apple notarization acceptance, stapling, strict distribution verification, quarantine relocation/launch proof, public `v1.0.0` publication, unauthenticated remote-byte verification, legacy personal-repository retirement, and exact recoverable cleanup.
- 2026-07-21: Completed independent release-evidence review and PR #5; all ten hosted checks passed on reviewed head `d9835891b7276122c45c06d27147966f810d2da9`, which rebased onto protected `main` as `9d14a50c7eebae61ab2511d21437ee203870f96a`. Archived this execution plan after final closeout.

## Rollback / Recovery

- If history rewrite fails: do not push; discard only the disposable mirror and retry from the retained source mirror.
- If a pushed rewrite is invalid: restore the exact pre-rewrite refs from the retained mirror while the repository remains under owner control, then re-enable the original protection/settings.
- If org publication fails: leave the personal repository public and unchanged, delete any empty/partial org target, and report the exact constraint.
- If notarization fails: retain the verified pre-sign app and logs, leave the personal repository recovery boundary intact, and report the exact credential/artifact/service blocker.
