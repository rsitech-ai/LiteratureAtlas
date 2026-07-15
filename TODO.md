# TODO

## Tasks
- [x] Repair baseline developer gates (DoD: locked Swift/Rust/Python validation commands pass or have exact pre-existing blockers)
- [x] Implement distributed runtime boundary (DoD: Application Support, bundle prompts, and no checkout-only Python controls are proven by tests)
- [x] Implement community app pipeline (DoD: credential-free rebranded app builds, relocates, signs ad hoc, launches, and verifies)
- [x] Implement official Developer ID pipeline (DoD: scripts fail closed without explicit identity/profile and validate pre-sign, signature, DMG, notary, and stapling states)
- [x] Complete licensing/provenance inventory (DoD: every tracked logical group and dependency has a license/ownership disposition or exact legal blocker)
- [x] Complete governance and contributor documents (DoD: policies contain real commands, paths, roles, and explicit owner blockers)
- [x] Harden GitHub CI and supply chain (DoD: least privilege, pinned actions/tools, locked dependencies, community build, REUSE, secret, workflow, and SBOM gates validate locally)
- [x] Generate publication artifacts (DoD: required open-source reports, SBOMs, and manifest are complete and internally consistent)
- [ ] Run final security scans and fix validated blockers (DoD: final diff/repository scans have no unresolved critical/high implementation finding)
- [ ] Verify from a fresh clone/worktree (DoD: public docs alone reproduce the community build and tests)
- [ ] Request final independent review (DoD: all critical/important findings resolved and re-reviewed)
- [ ] Memory update (DoD: `MEMORY.md` records only durable commands, boundaries, and decisions)
- [ ] Final handoff (DoD: exact verdicts, exceptions, blockers, approvals, artifact paths, commits, and next action are recorded)

## In progress
- [ ] Run final security scans, fresh-clone reproduction, and independent review.

## Done
- [x] Session bootstrap and repository instructions reviewed.
- [x] Clean main state confirmed and isolated worktree created.
- [x] Same-day release branch `c7f4215` adopted as the technical baseline.
- [x] Direct-distribution/open-source design approved, written, reviewed, and committed.
- [x] Parallel read-only audit workstreams dispatched.
- [x] Community app relocated, launched, verified, and packaged into a checksummed DMG.
- [x] Fresh signature-free official pre-sign app rebuilt and inspected; Developer ID key authorization remains external.
- [x] REUSE 3.3, workflow actionlint/zizmor, CFF/JSON validation, SBOM generation, Cargo audit, pip-audit, and OSV lock scanning completed.

## External / owner-controlled blockers

- Historical third-party PDFs and chain-of-title authority.
- Production icon/brand provenance, trademark owner, DCO-versus-CLA choice, and governance roster.
- Private security/conduct reporting and GitHub repository protection/settings.
- Developer ID private-key authorization, explicit notarization upload, quarantine/hardware acceptance, tag, and public release.
