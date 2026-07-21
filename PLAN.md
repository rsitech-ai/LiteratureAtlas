# Plan

## Context
- Move the public project to RSI Tech ownership, adopt Apache-2.0 under Rafal Sikora's confirmed copyright authority, remove four third-party PDFs from reachable Git history, and publish a current downloadable macOS release.
- The current repository is `s1korrrr/LiteratureAtlas`; `s1korrrr` has repository admin access and active admin membership in `rsitech-ai`.
- The user explicitly authorized history rewriting, removal of obsolete releases and irrelevant files, GitHub organization publication, PR review/merge, and release publication.

## Assumptions
- “Add this to our org GitHub” means create a clean canonical `rsitech-ai/LiteratureAtlas` from rewritten pushable history, then retire the old personal repository from public view after the replacement is verified. This avoids importing hidden GitHub pull-request refs that retain removed PDFs.
- “Clean up irrelevant files” means remove only proven generated, obsolete, duplicate, or unauthorized artifacts; preserve `Output/`, `analytics/.venv`, examples/source fixtures still used by tests, user data, and release evidence until superseded.
- Apache-2.0 applies prospectively to the owner-controlled project source. Prior MIT grants remain valid and historical third-party dependency licenses remain unchanged.
- The installed `Developer ID Application: Rafal Sikora (2NY8A789TN)` identity is the correct direct-download identity; Apple Development/App Store Distribution identities are not substitutes for Developer ID distribution.

## Constraints
- Do not run the formal Codex Security scan. Existing repository-native CodeQL, dependency, secret-pattern, and license checks remain scoped verification only.
- Do not expose, fabricate, export, or log private keys, notary credentials, tokens, or certificate payloads.
- History rewrite is limited to the four enumerated third-party PDF paths and proven obsolete refs/releases; keep a recoverable local mirror until the final org repository is verified.
- Use a PR for all current-tree license, identity, documentation, and release-code changes. The unavoidable history rewrite is a separately verified administrative mutation.
- Do not claim notarization, Gatekeeper acceptance, signing identity, or download readiness without exact artifact evidence.

## Options considered
1. Transfer the existing repository unchanged, then rewrite visible history and land license changes.
2. Rewrite and force-update the personal repository, transfer it, then land Apache/identity changes through a fresh PR.
3. Publish rewritten pushable history into a new org repository, land the current-tree migration through a fresh org PR, verify/release it, then make the personal repository private and archived as rollback evidence.

Chosen: option 3 because GitHub transfers preserve hidden PR refs and cached objects rooted after the PDFs. A new org repository produces a genuinely clean normal clone, keeps the migration reviewable, and lets the personal repository remain a private recovery boundary instead of publicly preserving unauthorized history.

## Execution plan
1. Inventory exact Git refs, PDFs, license/identity/contact surfaces, obsolete releases, installed signing identities, notary profile, and org permissions.
2. Create a recoverable mirror, rewrite the intended history to remove the four PDFs and canonicalize Rafal Sikora's Git identity, verify object/path/email absence, and create a clean public `rsitech-ai/LiteratureAtlas` containing only rewritten `main`.
3. Repoint the working checkout to the org repository, preserve the personal repository as a temporary rollback remote, and verify visibility, permissions, default branch, settings, and normal-clone history.
4. Recreate the feature branch from rewritten `main`; update Apache-2.0/NOTICE/REUSE/package/SBOM metadata, Rafal Sikora ownership, RSI Tech maintainer/brand, website/contact, GitHub URLs, governance, and release docs. Remove only proven obsolete tracked files.
5. Run format/lint/tests/builds/license checks, release-policy validation, source SBOM generation, macOS/iPadOS archives, credential-free package verification, and native runtime smoke.
6. Commit intentional files, push the feature branch, open a ready PR against org `main`, review the full diff independently, resolve findings, wait for all hosted gates, and merge through the PR.
7. Create and validate production AppIcon artwork consistent with LiteratureAtlas and RSI Tech, then build the exact merged macOS app. Use the installed Developer ID identity and usable `codebase-combiner-notary` profile; verify signature, entitlements, DMG contents, stapling, Gatekeeper, checksum, SBOM, relocation, and launch logs.
8. Publish the current downloadable release under `rsitech-ai`, verify remote bytes/checksum/SBOM, delete the obsolete personal prerelease/tag, make the superseded personal repository private and archived, clean only generated/local artifacts, and close PLAN/TODO/MEMORY with exact final evidence.

## Test plan
- License/identity: REUSE 3.3, manifest regressions, exact owner/contact/URL searches, Apache metadata assertions, and absence of obsolete owner/license claims.
- History: all pushable refs contain none of the four PDFs; fresh org clone contains no matching paths or blobs; no obsolete release/tag remains.
- Code: Python Ruff/tests/audit, Swift warnings-as-errors tests, Rust fmt/Clippy/tests/audit, release-script suite, release validator, and deterministic project generation.
- Packaging: exact source revision, Developer ID identity, hardened runtime, entitlements, nested signatures, mounted DMG byte equality, checksum, SPDX SBOM, notarization/stapling/Gatekeeper, relocated launch, and log scan.
- Hosted: PR head SHA/check matrix, independent review, merge commit, protected `main`, org URL/settings, release assets, and remote download verification.

## Risks and rollback
- Force rewrite disrupts clones and invalidates old SHAs -> retain a local mirror backup, publish migration guidance, verify the rewritten remote before deleting any backup, and never rewrite extra paths.
- Org creation or policy blocks settings/releases -> verify org admin access and target-name availability first; keep the personal repository public until the clean org replacement succeeds.
- Apache conversion misses a metadata surface -> use REUSE plus repository-wide exact searches and tests before PR.
- Developer ID/notary credentials fail -> preserve the verified unsigned build and report the exact blocker; do not downgrade a promised current RSI Tech release silently.
- Broad cleanup removes evidence/user data -> enumerate exact targets, measure them, and remove only generated/superseded artifacts after the replacement is remotely verified.

## Memory impact
- Record the final canonical org URL, Apache-2.0 ownership/maintainer/contact facts, sanitized-history boundary, canonical release/signing commands, and exact merged/release SHAs.

## Notes / Results
- Changes: Rewritten canonical history and new org repository; Apache-2.0/NOTICE/REUSE/DCO/RSI Tech metadata; `ai.rsitech` bundle namespace; complete production AppIcon catalog; org-policy-compatible workflows; credential-free unsigned release handoff; exact Developer ID/notarized `v1.0.0`; preserved Apple response/log; release-evidence documentation; removal of the legacy personal prerelease/tag and proven obsolete local outputs. Corrected the notarization workflow so the stapled unsigned DMG is validated with `stapler` while Gatekeeper evaluates the signed app.
- Tests run: focused red/green metadata, DCO, workflow-guard, icon-validator, and unsigned-DMG Gatekeeper regressions; Python format/lint and 65 tests; Rust format/strict Clippy/7 tests/audit; 90 XCTest cases plus 4 Swift Testing cases; release-script suite; validator; REUSE 3.3; deterministic XcodeGen; standalone macOS/iPhone/iPad `actool`; native `build_and_run.sh --verify`; exact-main hosted unsigned build; strict signed/notarized distribution verification; quarantined relocated launch/log smoke; authenticated draft and unauthenticated public asset round trips.
- History/transfer evidence: sanitized org baseline `f6ed31b36a0b2dcb2e5ff459ebda28f3d212fa45`; 85 commits; fresh-clone fsck clean; no enumerated PDF path/blob or legacy personal email in that baseline; only rewritten `main` published; recovery mirror retained at `/private/tmp/LiteratureAtlas-history-rewrite.9tgspw/recovery.git`. GitHub later used the account merge identity for PR #4's merge commit instead of the configured no-reply email; rewriting the notarized release SHA was rejected to preserve exact provenance.
- Release evidence: migration PR #4 merged as `88f7d5e7c373226eb3861277ba9ca6a57f5e8774`; exact-main workflow run `29782445124` passed; `v1.0.0` targets that SHA. Apple submission `68cc41be-2f44-4650-a731-ec1e5a042f3f` is `Accepted`; published DMG SHA-256 is `f2fc0c5ec19831213e1dcd0ea4d6fe104a890fdaae821a581e5ce5d4af108c20`; app SPDX SHA-256 is `cd5d9b6cb620b3ec7191e3bdb9e6aba7004d35227f5230d0eb49bb9598c76440`; public bytes match.
- Tradeoffs/blockers: the macOS direct-download lane is complete. The local Xcode build-service issue was bypassed with exact-main hosted proof without terminating unrelated tasks. iPad App Store publication remains a separate external lane. Existing user `Output/` audit findings are preserved unchanged. The formal Codex Security scan remained excluded by user direction.
