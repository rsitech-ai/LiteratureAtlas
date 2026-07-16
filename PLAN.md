# Plan

## Context
- Convert the same-day release-hardened LiteratureAtlas version at baseline commit `c7f4215` from a Mac App Store-oriented macOS target into a Developer ID-signed, notarized, direct-download product while hardening the already-public repository for truthful open-source operation.
- Approved design: `docs/superpowers/specs/2026-07-15-developer-id-open-source-design.md`.
- Implementation plan: `docs/superpowers/plans/2026-07-15-developer-id-open-source.md`.

## Assumptions
- The official first direct-download artifact is macOS 26 on Apple Silicon.
- The iPad App Store target remains available but is not a shipping deliverable for this task.
- GitHub `main` remains public and MIT-licensed until an explicit, rights-backed owner decision changes future licensing.

## Constraints
- PR creation, feature-branch push, review fixes, merge, and the resulting `main` push are now owner-authorized after all validation and review gates pass.
- No notarization upload, public binary release, tag, announcement, credential mutation, repository visibility change, history rewrite, or legal identity claim in this pass.
- No private credentials or user data in Git, CI, reports, artifacts, or command arguments.
- Preserve all committed release work and existing MIT grants.

## Options considered
1. Extend the legacy hand-built SwiftPM bundle.
2. Reuse the deterministic Xcode macOS target and add separate community, Developer ID, DMG, notarization, and verification layers.
3. Replace the project with a new installer/packaging system.

Chosen: 2 because it retains the strongest existing runtime, privacy, and archive evidence while keeping signing secrets outside the project.

## Execution plan
1. Repair baseline developer gates.
2. Add shared distributed-build runtime behavior and tests.
3. Implement community/official build, signing, DMG, notarization, and verification scripts.
4. Complete open-source licensing, governance, security, support, and developer documentation.
5. Harden GitHub CI and supply-chain controls.
6. Generate secret, IP, dependency, SBOM, provenance, and publication evidence.
7. Clean obsolete generated releases/worktrees only after Git and ancestry proof.
8. Audit the full implementation, official-document assumptions, and runtime behavior beyond tests.
9. Reproduce the community package from a fresh clone and complete a native macOS interaction/log sweep.
10. Request independent review, resolve all critical/important findings, and rerun the full matrix.
11. Push, create the PR, inspect GitHub checks/review, merge, and verify the exact merged `main` revision.

## Test plan
- Follow the complete command matrix in `docs/superpowers/plans/2026-07-15-developer-id-open-source.md`.
- Behavior changes use red-green-refactor tests; configuration and documentation use deterministic validators and clean-checkout smokes.

## Risks and rollback
- Direct build weakens the proven App Store boundary -> share the distributed-build path abstraction and keep platform-specific signing outside source behavior.
- Python/Rust removal breaks user-visible features -> compile out only checkout-only controls, retain native fallback, and document declared exceptions.
- Legal ownership is uncertain -> keep MIT effective and block relicense/publication claims.
- Apple or GitHub credentials/settings are unavailable -> finish local reversible work and record exact external blockers.

## Memory impact
- Record the adopted release baseline, Developer ID/direct-distribution build commands, official/community separation, public repository state, and any durable packaging pitfalls.

## Notes / Results
- Changes: Added a shared distributed runtime boundary; persistent read-only source bookmarks held through async ingest; credential-free community and signature-free official pre-sign builds; exact DMG comparison; source/identity-bound verification; staged Developer ID signing; hash-bound atomic notary evidence; privacy-minimized diagnostics; pinned credential-free CI; REUSE metadata; contributor/governance/security policies; IP/secret/license reports; and deterministic source/community/pre-sign SBOMs.
- Tests run: Swift 59 passed with one opt-in corpus smoke skipped plus 4 bookmark lifetime tests; Python 23 passed; Rust 5 passed with strict Clippy and no known vulnerability; macOS/iOS Release builds, community relocation/navigation/real sandbox ingest/relaunch/DMG, release scripts, actionlint, zizmor, REUSE 3.3, pip-audit, OSV, CFF, JSON, and documentation-link checks passed. The release validator has only the explicit approved-AppIcon blocker.
- Tradeoffs: Native-only Apple Silicon first distribution; Python and Rust acceleration remain contributor tooling. Existing MIT stays effective because MPL/CC relicensing authority is unconfirmed. Signing/notarization/publication remain external owner gates.
- 2026-07-16 audit/merge pass: Codex Security is explicitly deferred. This pass still includes code-level security, privacy, dependency, workflow, and signing-configuration review but will not claim a Codex Security result.
- 2026-07-16 runtime findings: exact artifact testing caught and fixed display-name/source-revision precedence, generated-xcconfig injection, bookmark-creation scope, and async bookmark-enumeration lifetime defects before PR creation. Verified local artifact evidence embeds commit `647911a`; later documentation commits do not replace that explicit mapping.
