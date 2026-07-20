# Plan

## Context
- Perform a delta production-readiness and public open-source release pass from clean `main` commit `2ee1adf6c7204f3bb4524c2c1a2d872fe8bc9e83`.
- The repository is already public, MIT-licensed, and has a published `v1.0.0-community.1` prerelease. This task must improve and verify the current state without rewriting already-proven work.
- The user explicitly opted out of the formal Codex Security scan and authorized safe local changes, cleanup, commits, integration, and pushing the completed result to `main`.

## Assumptions
- Intended users are researchers who want a local-first macOS or iPadOS workspace for ingesting papers, exploring relationships, and producing evidence-linked research artifacts.
- The supported downloadable artifact remains the Apple Silicon macOS 26+ community build unless official signing/notarization and artwork gates become provably available.
- Existing MIT licensing and repository copyright/provenance records are owner-selected project facts; this pass will not relicense or invent ownership.

## Constraints
- Exclude the formal Codex Security scan and label that coverage `unverified`; still run existing local dependency, secret-pattern, workflow, license, and release-policy checks where available.
- Preserve public APIs, persisted formats, compatibility keys, user data, `Output/`, active environments, release evidence, and ambiguous artifacts.
- Remove only exact generated/cache outputs that are reproducible and ignored; use recoverable cleanup where practical.
- Do not claim Developer ID signing, notarization, App Store readiness, or redistribution clearance without direct evidence.
- Keep one writer in this worktree; parallel agents are read-only auditors.

## Options considered
1. Rebuild the repository's open-source surface broadly from the master prompt.
2. Run an evidence-driven delta audit against the already-hardened public repository and remediate only validated gaps.
3. Perform a report-only review and leave all gaps for a later task.

Chosen: option 2 because the repository already contains extensive release, provenance, CI, and community infrastructure. A broad rewrite would add risk and churn, while report-only work would not satisfy the requested completion and push.

## Execution plan
1. Refresh local and GitHub state, capture tool versions, and record clean-baseline verification results.
2. Audit privacy/provenance/workflows, code and tests, documentation/community files, release packaging, and live GitHub metadata in independent read-only lanes.
3. Consolidate findings by public-exposure severity and remediate the smallest coherent set of validated gaps.
4. Run format, lint, test, build, license, dependency, release-policy, runtime, documentation, and artifact verification.
5. Rehearse documented setup/build/use from a fresh temporary clone and inspect the distributable as an unauthenticated user where practical.
6. Review the complete diff, commit only intentional files, integrate to `main`, push, and verify hosted checks and public repository state.
7. Remove only proven generated/cache clutter, then close PLAN/TODO/MEMORY with exact evidence and remaining blockers.

## Test plan
- Baseline and final: `swift test -Xswiftc -warnings-as-errors`.
- Python: frozen `uv sync`, Ruff format/check, and all `analytics/tests`.
- Rust FFI: fmt, strict Clippy, tests, release build, and advisory audit where available.
- Release: release-script regression suite, configuration/privacy/entitlement validation, deterministic project generation, package/build verification, SBOM/checksum checks, and `./script/build_and_run.sh --verify`.
- Documentation/community: validate README commands and links, community-file manifests, GitHub Actions syntax/policy, and `git diff --check`.
- Clean-room: fresh clone/copy using only tracked files, documented setup, tests, build, community artifact verification, and launch smoke.
- Hosted: verify exact pushed `main` SHA, required GitHub Actions checks, repository metadata, release assets, and remaining external settings.

## Risks and rollback
- A broad cleanup could remove user data -> restrict cleanup to enumerated ignored build/cache paths and preserve all ambiguous content.
- Documentation could overstate readiness -> qualify claims and preserve explicit legal, signing, runtime, and security limitations.
- New CI could be noisy or unsafe -> modify only validated existing workflows, keep permissions read-only, pin actions, and test locally where possible.
- Direct integration could regress `main` -> keep reviewable commits on `chore/oss-release-readiness`, run the full matrix before fast-forwarding or merging, and push only a verified `main` result.
- Formal security coverage is omitted -> retain an explicit `unverified` entry in the final gate matrix rather than translating local checks into exhaustive proof.

## Memory impact
- Record any newly verified canonical commands, durable public-release boundaries, GitHub configuration decisions, and final integrated commit/release state.

## Notes / Results
- Changes: hardened URL trust parsing; cross-language corpus freshness; PDF
  extraction/hash cancellation and actor isolation; derived-export ordering and
  error reporting; bounded claim controversy analysis; deterministic saved-paper
  compatibility; DMG cleanup; notices, SBOM, public docs, GitHub metadata, and
  protected-main governance with nine required checks.
- Tests run: Python Ruff + 61 tests; Swift warnings-as-errors + 90 XCTest and 4
  Swift Testing cases; Rust fmt/strict Clippy/7 tests/release build; Python/Rust
  advisory audits; REUSE 3.3; release-script suite; release validator; XcodeGen
  parity; arm64 macOS and iPadOS Release archives; canonical app launch/log smoke;
  manual redacted reachable-history scan. Reviewed head `9b62c14` also passed a
  frozen clean-room restore, full language suites, credential-free community
  build, mounted DMG byte comparison, portable checksum verification, and
  relocated launch smoke. PR #11 passed all substantive hosted checks, including
  executed dependency review and Swift/Python CodeQL, then merged as `88f914b`.
- Tradeoffs: formal Codex Security scan excluded by explicit user direction;
  repository-native checks remain scoped evidence, not an exhaustive substitute.
  The macOS archive is intentionally Apple Silicon to match the supported
  direct-download lane and local disk budget. Branch protection requires no
  approval for the solo-owner workflow but does require an up-to-date pull
  request, nine checks, and resolved conversations; administrators are not
  enforced so the explicitly authorized closeout commit can land directly.
- Cleanup: removed only ignored/generated Swift, Rust, Ruff, pytest,
  distribution, and exact temporary rehearsal outputs. Preserved `Output/`,
  `analytics/.venv`, examples, user data, and release evidence.
- Final readiness: the community lane is repo-ready, package-ready, and
  runtime-proven for the reviewed Apple Silicon candidate. Official source or
  Apple distribution remains blocked externally by reachable PDF history,
  chain of title, production artwork/brand authority, governance/conduct routing,
  Developer ID/notarization proof, and an exact signed-artifact SBOM/attestation.
