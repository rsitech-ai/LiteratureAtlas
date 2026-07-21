# TODO

## Tasks
- [x] Complete authority, GitHub, license, history, signing, and release inventory (DoD: exact evidence and targets are recorded before mutation)
- [x] Sanitize public history (DoD: the four third-party PDFs are absent from every pushable ref and fresh-clone history; recoverable backup retained)
- [x] Publish sanitized canonical repository to RSI Tech (DoD: new `rsitech-ai/LiteratureAtlas` is public, contains only intended rewritten refs, and passes fresh-clone history checks)
- [x] Retire obsolete personal release/repository state (DoD: only after replacement verification, the old prerelease/tag is removed and the personal repository is private/archived recovery evidence)
- [x] Adopt Apache-2.0 and public identity (DoD: owner, maintainer, website, contact, Git URLs, package metadata, REUSE, NOTICE, SBOM, and docs are internally consistent)
- [x] Validate code and product (DoD: full local language, policy, archive, package, runtime, license, and documentation matrix is green or explicitly blocked)
- [x] Create and review migration PR (DoD: coherent org PR is independently reviewed, findings resolved, and all hosted checks pass on the exact head)
- [x] Merge migration via PR (DoD: PR merge lands on protected org `main` and exact remote SHA/settings are verified)
- [x] Build and publish latest app (DoD: exact merged source produces a downloadable artifact with truthful signing/notary status, checksum, SBOM, and remote byte verification)
- [x] Create, review, and merge release-evidence PR (DoD: final evidence and script regression land through protected `main` with all required checks green)
- [x] Safe cleanup and closeout (DoD: only obsolete/generated artifacts are removed; PLAN/TODO/MEMORY record exact final evidence and remaining external blockers)

## In progress
- None; the release migration and closeout are complete.

## Done
- [x] User confirmed copyright owner Rafal Sikora, RSI Tech brand/maintainer, `https://rsitech.ai`, `info@rsitech.ai`, the no-reply Git email, Apache-2.0, history rewrite, org publication, PR/merge, release publication, and cleanup authority.
- [x] Repository-local Git author configured as `Rafal Sikora <24563931+s1korrrr@users.noreply.github.com>`.
- [x] Valid installed direct-download identity found: `Developer ID Application: Rafal Sikora (2NY8A789TN)`; certificate download is not currently needed.
- [x] GitHub identity `s1korrrr` has repository admin and active `rsitech-ai` org admin access.
- [x] Usable Apple notarization credentials found under keychain profile `codebase-combiner-notary`; the expected `LiteratureAtlasNotary` alias is absent but no credential download is needed.
- [x] Independent history audit rejected a transfer because hidden PR refs would retain the PDFs; selected a clean rewritten org repository plus private archived personal rollback repository.
- [x] Migration PR #4 passed all nine required checks and merged reviewed head `712754f8c8d2696f6c1621d1b7e526384cb35b11` as protected-main commit `88f7d5e7c373226eb3861277ba9ca6a57f5e8774` with exact tree parity.
- [x] Exact-main unsigned workflow run `29782445124` produced the transport-verified official app and dSYM; the app embeds source revision `88f7d5e7c373226eb3861277ba9ca6a57f5e8774`.
- [x] Apple accepted notarization submission `68cc41be-2f44-4650-a731-ec1e5a042f3f`; the stapled DMG, exact mounted app, app-level Gatekeeper assessment, quarantine relocation, launch, and fatal-log scan passed.
- [x] Public org release `v1.0.0` maps to the exact merged source; DMG, checksum, and app SPDX SBOM matched unauthenticated public downloads byte-for-byte.
- [x] After replacement verification, removed legacy `v1.0.0-community.1`, closed/deleted personal Dependabot PRs/branches #6 and #7, and made `s1korrrr/LiteratureAtlas` private and archived with `main` preserved.
- [x] Moved only the enumerated obsolete archive, asset-compiler, debug-app, release, and smoke paths to Trash; preserved `Output/`, `analytics/.venv`, and the verified recovery mirror.
- [x] Release-evidence PR #5 merged reviewed head `d9835891b7276122c45c06d27147966f810d2da9` by rebase as protected-main commit `9d14a50c7eebae61ab2511d21437ee203870f96a` after all ten hosted checks passed.
- [x] Final closeout retained the published/notarized release provenance, preserved the recovery mirror and user-controlled outputs, and archived the completed execution plan.
