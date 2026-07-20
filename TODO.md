# TODO

## Tasks
- [x] Complete authority, GitHub, license, history, signing, and release inventory (DoD: exact evidence and targets are recorded before mutation)
- [x] Sanitize public history (DoD: the four third-party PDFs are absent from every pushable ref and fresh-clone history; recoverable backup retained)
- [x] Publish sanitized canonical repository to RSI Tech (DoD: new `rsitech-ai/LiteratureAtlas` is public, contains only intended rewritten refs, and passes fresh-clone history checks)
- [ ] Retire obsolete personal release/repository state (DoD: only after replacement verification, the old prerelease/tag is removed and the personal repository is private/archived recovery evidence)
- [x] Adopt Apache-2.0 and public identity (DoD: owner, maintainer, website, contact, Git URLs, package metadata, REUSE, NOTICE, SBOM, and docs are internally consistent)
- [x] Validate code and product (DoD: full local language, policy, archive, package, runtime, license, and documentation matrix is green or explicitly blocked)
- [ ] Create and review PR (DoD: coherent org PR is independently reviewed, findings resolved, and all hosted checks pass on the exact head)
- [ ] Merge via PR (DoD: PR merge lands on protected org `main` and exact remote SHA/settings are verified)
- [ ] Build and publish latest app (DoD: exact merged source produces a downloadable artifact with truthful signing/notary status, checksum, SBOM, and remote byte verification)
- [ ] Safe cleanup and closeout (DoD: only obsolete/generated artifacts are removed; PLAN/TODO/MEMORY record exact final evidence and remaining external blockers)

## In progress
- [ ] Create and review PR

## Done
- [x] User confirmed copyright owner Rafal Sikora, RSI Tech brand/maintainer, `https://rsitech.ai`, `info@rsitech.ai`, the no-reply Git email, Apache-2.0, history rewrite, org publication, PR/merge, release publication, and cleanup authority.
- [x] Repository-local Git author configured as `Rafal Sikora <24563931+s1korrrr@users.noreply.github.com>`.
- [x] Valid installed direct-download identity found: `Developer ID Application: Rafal Sikora (2NY8A789TN)`; certificate download is not currently needed.
- [x] GitHub identity `s1korrrr` has repository admin and active `rsitech-ai` org admin access.
- [x] Usable Apple notarization credentials found under keychain profile `codebase-combiner-notary`; the expected `LiteratureAtlasNotary` alias is absent but no credential download is needed.
- [x] Independent history audit rejected a transfer because hidden PR refs would retain the PDFs; selected a clean rewritten org repository plus private archived personal rollback repository.
