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
- [x] Clean obsolete release/build state (DoD: only generated or superseded artifacts/worktrees are removed after clean-state and ancestry proof; unique commits remain preserved)
- [x] Run full static and code-level security review (DoD: full diff/source/docs/workflow review has no unresolved blocker/high implementation finding; Codex Security remains explicitly deferred)
- [x] Verify from a fresh clone/worktree (DoD: public docs alone reproduce the community build and tests)
- [x] Complete native macOS E2E audit (DoD: app relaunch, primary workflows, controls, edge states, persistence, accessibility/help, and focused runtime logs are captured in an audit report)
- [ ] Request final independent review (DoD: all critical/important findings resolved and re-reviewed)
- [ ] Create and harden PR (DoD: branch pushed, PR opened, GitHub checks/review inspected, and all actionable findings resolved)
- [ ] Merge and verify exact `main` (DoD: PR merged only after approval/gates; local `main` matches `origin/main` and merged-revision verification passes)
- [ ] Memory update (DoD: `MEMORY.md` records only durable commands, boundaries, and decisions)
- [ ] Final handoff (DoD: exact verdicts, exceptions, blockers, approvals, artifact paths, commits, and next action are recorded)

## In progress
- [ ] Request exact-diff review of `origin/main...HEAD`, then harden and merge the PR.

## Done
- [x] Session bootstrap and repository instructions reviewed.
- [x] Clean main state confirmed and isolated worktree created.
- [x] Same-day release branch `c7f4215` adopted as the technical baseline.
- [x] Direct-distribution/open-source design approved, written, reviewed, and committed.
- [x] Parallel read-only audit workstreams dispatched.
- [x] Community app relocated, launched, verified, and packaged into a checksummed DMG.
- [x] Fresh signature-free official pre-sign app rebuilt and inspected; Developer ID key authorization remains external.
- [x] REUSE 3.3, workflow actionlint/zizmor, CFF/JSON validation, SBOM generation, Cargo audit, pip-audit, and OSV lock scanning completed.
- [x] Exact community app/DMG from `647911a` verified, launched, navigated, ingested a real sandboxed fixture, and restored persisted state after relaunch.
- [x] Exact signature-free official pre-sign app from `647911a` inspected with source mapping and retained dSYM.
- [x] Fresh clone at `a8f2f2a` restored from the lock, passed all Swift/Python/Rust/release gates, and produced warning-free macOS and iOS Release apps.

## External / owner-controlled blockers

- Historical third-party PDFs and chain-of-title authority.
- Production icon/brand provenance, trademark owner, DCO-versus-CLA choice, and governance roster.
- Private security/conduct reporting and GitHub repository protection/settings.
- Developer ID private-key authorization, explicit notarization upload, quarantine/hardware acceptance, tag, and public release.
