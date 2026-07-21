# Reflection: notarized release closeout

## Task

- **ID / title:** LiteratureAtlas 1.0.0 RSI Tech release closeout
- **Date:** 2026-07-21
- **Scope:** Accepted Apple notarization, stapling, distribution verification, public GitHub release, evidence PR, legacy retirement, and exact cleanup.
- **Authority boundary:** The owner authorized org publication, PR/merge, history rewrite, release publication, legacy cleanup, and exact local cleanup. A formal Codex Security scan was explicitly excluded.

## Success and Risk

- **Success criteria:** The exact protected-main source produces a Developer ID-signed, Apple-accepted, stapled, Gatekeeper-approved public DMG whose checksum and SBOM round-trip byte-for-byte; obsolete public state is retired only afterward.
- **Hypothesis 1:** Apple acceptance plus `stapler validate` on the submitted DMG and `spctl -t exec` on the signed app is sufficient for this unsigned transport-container design.
- **Hypothesis 2:** The DMG itself must pass `spctl -t open` even when it has no code signature.
- **Hypothesis 3:** Re-signing the already accepted DMG or rewriting the tagged source commit would preserve existing notarization and source provenance.
- **Rollback path:** Keep the org release unpublished until draft bytes pass; retain the old personal prerelease and recovery mirror until the replacement is publicly verified; preserve the accepted artifacts and Apple evidence on any verification failure.

## Candidate Directions

| Candidate | Expected benefit | Main risk | Evidence before choice | Decision |
|---|---|---|---|---|
| A. Preserve the accepted DMG; validate its ticket and assess the signed app | Keeps the exact accepted digest and tests the executable trust boundary | Requires correcting a stale script assumption | Apple accepted the unsigned DMG with no issues; `stapler validate` passed; the signed app passed Gatekeeper as Notarized Developer ID | Chosen |
| B. Sign or rebuild the DMG and submit again | Makes DMG-level `spctl -t open` pass | Changes the accepted digest, duplicates submission, and invalidates preserved evidence | Apple documents that disk images do not require a signature; the current app already passed the real quarantine path | Rejected |

## Evidence

- **First meaningful failure signal:** After Apple returned `Accepted`, `stapler validate` passed but `spctl -t open --context context:primary-signature` rejected the DMG with `source=no usable signature`.
- **Commands or runtime checks:** `notarytool info/log`, `stapler validate`, strict `verify_distribution.sh --mode notarized`, quarantined relocated launch, unified-log fatal scan, draft/public GitHub asset round trips, full release-script tests, Python/Swift/Rust tests, REUSE, and release configuration validation.
- **What the evidence ruled in or out:** The accepted artifact and app signature were valid. The failure was an invalid DMG-container assertion, not a signing or notarization defect. Concurrent tool-limited test runs also left read-only mounts and caused one transient fixture failure; a clean isolated rerun passed.

## Decision

- **Root cause or remaining unknown:** `notarize_dmg.sh` conflated ticket validation for an unsigned DMG transport with Gatekeeper execution assessment for its signed app. Separately, GitHub authored PR #4's merge commit with the account merge identity rather than the repository-local no-reply identity.
- **Retained fix / direction:** Staple and validate the exact submitted DMG, refresh its checksum, and require app-level Gatekeeper assessment in `verify_distribution.sh`. Preserve the already notarized release SHA and document the GitHub merge-identity exception; use a merge strategy that retains the signed-off no-reply commit for the evidence PR.
- **Why alternatives were rejected:** Re-signing or rewriting would change a public, notarized provenance chain and require rebuilding, resubmitting, and replacing already verified assets. That cost and risk exceed the benefit of cosmetic DMG signing or retroactive merge-metadata cleanup.
- **Residual risk:** The tagged PR #4 merge commit retains GitHub's account merge identity. The iPad App Store lane remains external and unproven.
- **Rollback trigger:** Withdraw the release if public bytes, tag target, Apple status, Gatekeeper result, or embedded source revision no longer match the recorded evidence.

## Reusable Lesson

- **Pattern to retain:** Bind each release check to the layer it proves: `stapler` for the submitted container ticket, `codesign` for code integrity, `spctl -t exec` for the app trust decision, and public re-download for distribution integrity.
- **Pattern to avoid:** Do not add container-level trust assertions that assume a signature the packaging workflow never creates; do not run long `hdiutil` suites concurrently under short tool deadlines.
- **Where it applies next:** Future RSI Tech direct-download macOS releases and any GitHub release-evidence PR that must preserve exact source identity.
