# Developer ID and Open-Source Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a standalone, community-buildable macOS application and an approval-gated Developer ID/notarization release path, then harden the already-public repository for truthful open-source operation.

**Architecture:** Reuse the deterministic XcodeGen macOS application target at commit `c7f4215`. Build one unsigned Release payload, then wrap it with separate community/ad-hoc and official/Developer ID signing paths. Keep Python and optional Rust acceleration as contributor tooling unless separately embedded and verified. Record all unresolved legal, Apple, GitHub-setting, brand, and publication actions as explicit blockers.

**Tech Stack:** Swift 6, SwiftUI, XcodeGen/Xcode 26.6, Bash, Python 3.12 with uv, Rust/Cargo, GitHub Actions, SPDX/REUSE, CycloneDX or SPDX SBOM.

## Global Constraints

- Do not change repository visibility, publish a GitHub release, upload for notarization, distribute through TestFlight, submit for App Review, merge, tag, or announce without exact owner approval.
- Do not add private keys, certificates, profiles, passwords, tokens, API keys, notary credentials, update signing keys, or personal document data.
- Keep the effective software license MIT until the owner explicitly approves a future license and confirms relicensing rights.
- The official direct-distribution app is macOS-only; the existing iPad App Store target remains non-shipping context.
- The first direct-distribution build uses the Swift fallback and does not ship repository Python tooling or an unverified Rust dylib.
- Preserve the already-public history and all user commits; no history rewrite, force push, stash, rebase, or destructive cleanup.

---

### Task 1: Repair baseline developer gates

**Files:**
- Modify: `analytics/pyproject.toml`
- Modify: `analytics/README.md`
- Modify: `MEMORY.md`

**Interfaces:**
- Produces: one locked contributor command, `uv sync --project analytics --extra dev --frozen`, that installs both runtime and validation tools.

- [ ] Add a clean-environment test command to the plan evidence and verify plain `uv sync --frozen` lacks the optional dev tools.
- [ ] Run `uv sync --project analytics --extra dev --frozen` and verify `ruff` and `pytest` are importable.
- [ ] Run Ruff format/lint and Python tests.
- [ ] Run strict Rust format, clippy, tests, and audit on the adopted baseline.
- [ ] Run Swift tests and deterministic release-configuration validation.

### Task 2: Make the direct-distribution runtime boundary explicit

**Files:**
- Modify: `Config/Shared.xcconfig`
- Modify: `Sources/LiteratureAtlas/Services/AppPaths.swift`
- Modify: `Sources/LiteratureAtlas/App/AppModel.swift`
- Modify: `Sources/LiteratureAtlas/Views/AnalyticsView.swift`
- Modify: `Tests/LiteratureAtlasTests/AppPathsTests.swift`
- Create or modify focused runtime-capability tests under `Tests/LiteratureAtlasTests/`

**Interfaces:**
- Produces: `DISTRIBUTED_APP_BUILD`, used by both direct and App Store Xcode targets to select container-safe storage, bundled prompts, and native-only shipped behavior.
- Produces: a truthful runtime-capability value that hides or disables checkout-only Python actions in distributed builds.

- [ ] Write a failing test proving distributed builds resolve data under Application Support and prompt resources under the app bundle without a repository.
- [ ] Run the focused test and confirm the old build-condition API fails the new contract.
- [ ] Implement the minimal shared distributed-build condition and path behavior.
- [ ] Write a failing test proving distributed builds expose no Python dependency installer/rebuild capability.
- [ ] Implement the capability boundary and truthful UI state while preserving contributor checkout behavior.
- [ ] Re-run focused tests and the complete Swift suite.

### Task 3: Build, sign, package, and verify the macOS application

**Files:**
- Create: `Config/DirectDistribution.xcconfig`
- Modify: `project.yml`
- Regenerate: `LiteratureAtlas.xcodeproj/`
- Create: `script/build_community.sh`
- Create: `script/build_official.sh`
- Create: `script/sign_developer_id.sh`
- Create: `script/create_dmg.sh`
- Create: `script/notarize_dmg.sh`
- Create: `script/verify_distribution.sh`
- Create: `scripts/tests/test_release_scripts.sh`

**Interfaces:**
- `build_community.sh --product-name NAME --bundle-id ID --version VERSION --build BUILD --output DIR`
- `build_official.sh` produces the same unsigned payload and refuses to notarize or publish.
- `sign_developer_id.sh --app APP --identity IDENTITY` rejects non-Developer-ID identities.
- `notarize_dmg.sh --dmg DMG --keychain-profile PROFILE --expected-sha256 SHA256 --submit` is the only command with an external Apple write and is never invoked without exact artifact approval.
- `verify_distribution.sh --app APP [--dmg DMG] --mode community|official|notarized` emits machine-readable pass/fail evidence without secret values; official modes also require owner-approved identity, version, architecture, and deployment-target expectations.

- [ ] Write shell tests for missing arguments, invalid identities, unsafe product/bundle values, output confinement, and no-notarization-by-default.
- [ ] Run the shell tests and confirm the scripts do not yet exist.
- [ ] Implement deterministic unsigned staging from the Xcode target.
- [ ] Implement ad-hoc community signing and official Developer ID signing separation.
- [ ] Implement DMG creation, checksums, approval-gated notarization, stapling, and validation.
- [ ] Build the community app with a non-official bundle identifier, relocate it outside the checkout, verify resources and signature, launch it, and inspect logs.
- [ ] Build the official unsigned payload and verify it contains no credentials, Python installer, or checkout-relative runtime requirement.

### Task 4: Establish licensing, provenance, governance, and public documentation

**Files:**
- Create or update: `README.md`, `NOTICE`, `COPYRIGHT.md`, `THIRD_PARTY_NOTICES.md`, `TRADEMARKS.md`, `BRANDING.md`, `DCO`, `CONTRIBUTORS.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `SUPPORT.md`, `GOVERNANCE.md`, `MAINTAINERS.md`, `ROADMAP.md`, `CHANGELOG.md`, `RELEASING.md`, `CITATION.cff`, `REUSE.toml`
- Create: `LICENSES/`
- Create: `docs/build/`, `docs/community-build/`, `docs/release/`, `docs/security/`, `docs/open-source/`

**Interfaces:**
- Effective license remains MIT; proposed MPL-2.0 is labeled owner/legal approval required.
- Security reports use GitHub private vulnerability reporting only after the repository setting is enabled; until then the manifest reports the gate blocked.
- Conduct enforcement names the maintainer role and marks the missing private moderation channel as an owner blocker rather than inventing contact data.

- [ ] Generate tracked-file, contributor, dependency, asset, binary, and history inventories with exact evidence.
- [ ] Write real policies using current commands, paths, owner roles, and support boundaries; do not insert legal-identity placeholders as facts.
- [ ] Add SPDX/REUSE mappings without replacing valid third-party notices.
- [ ] Generate third-party notices from locked Swift/Rust/Python/build-tool inputs and mark unknown items explicitly.
- [ ] Add in-app bundled acknowledgements/source metadata or record the exact source-code disclosure blocker.
- [ ] Run `reuse lint` or the pinned equivalent and correct every machine-actionable failure.

### Task 5: Harden GitHub CI and supply-chain controls

**Files:**
- Modify: `.github/workflows/ci.yml`
- Create: `.github/workflows/codeql.yml`
- Create: `.github/workflows/dependency-review.yml`
- Create: `.github/workflows/license-compliance.yml`
- Create: `.github/workflows/scorecard.yml`
- Create: `.github/workflows/release.yml`
- Create: `.github/CODEOWNERS`
- Create: `.github/dependabot.yml`
- Create: `.github/ISSUE_TEMPLATE/bug.yml`
- Create: `.github/ISSUE_TEMPLATE/feature.yml`
- Create: `.github/ISSUE_TEMPLATE/config.yml`
- Create: `.github/pull_request_template.md`

**Interfaces:**
- Default workflow token permission is `contents: read`.
- Untrusted pull requests receive no signing, notary, release, attestation, or protected-environment secret.
- The release workflow is manual/draft-only until protected environment and owner approvals exist.

- [ ] Pin third-party actions to verified full commit SHAs and record upstream versions in comments.
- [ ] Add timeouts, concurrency controls, `persist-credentials: false`, locked dependency gates, community bundle smoke, license checks, secret checks, and SBOM validation.
- [ ] Add DCO/sign-off enforcement with remediation instructions.
- [ ] Validate workflows with actionlint/yamllint-equivalent and zizmor or document unavailable-tool evidence.
- [ ] Inspect authenticated repository settings read-only and record branch protection, secret scanning, push protection, Dependabot, private reporting, and immutable-release state.

### Task 6: Produce audits, SBOMs, provenance, and publication manifest

**Files:**
- Create: `docs/open-source/OPEN_SOURCE_STATUS.md`
- Create: `docs/open-source/IP_INVENTORY.md`
- Create: `docs/open-source/LICENSE_MAP.md`
- Create: `docs/open-source/THIRD_PARTY_INVENTORY.md`
- Create: `docs/open-source/SECRET_AUDIT.md`
- Create: `docs/open-source/PUBLIC_PRIVATE_BOUNDARY.md`
- Create: `docs/open-source/COMMUNITY_BUILD.md`
- Create: `docs/open-source/TRADEMARK_REVIEW.md`
- Create: `docs/open-source/GOVERNANCE_REVIEW.md`
- Create: `docs/open-source/SECURITY_READINESS.md`
- Create: `docs/open-source/SUPPLY_CHAIN_READINESS.md`
- Create: `docs/open-source/PUBLICATION_GATE_MATRIX.md`
- Create: `docs/open-source/BLOCKERS.md`
- Create: `docs/open-source/OPEN_SOURCE_MANIFEST.json`
- Generate ignored evidence under `dist/evidence/`

**Interfaces:**
- The manifest uses exactly one publication verdict and one direct-distribution verdict, with evidence and owner blockers.
- Secret reports contain paths, commit IDs, fingerprints, classification, and rotation state but never secret values.

- [ ] Run current-tree and reachable-history scans with at least two independent methods where tools permit.
- [ ] Generate source and staged-app SPDX/CycloneDX SBOMs from locked dependencies.
- [ ] Record hashes, toolchain versions, commit, lockfiles, signing category, and notarization state.
- [ ] Populate every required manifest field with a value, explicit `not_applicable`, or evidence-backed blocker.

### Task 7: Final verification, security review, and branch handoff

**Files:**
- Update: `PLAN.md`, `TODO.md`, `MEMORY.md`
- Update: open-source status and gate evidence from Task 6

**Interfaces:**
- Produces one truthful final verdict: `READY TO MAKE PUBLIC`, `READY WITH DECLARED EXCEPTIONS`, `BLOCKED`, or `NOT READY`.
- Produces direct-distribution status separately from source-publication status.

- [ ] Run the complete Swift, Rust, Python, Xcode, release-script, community-bundle, docs, license, secret, SBOM, and CI-local validation matrix.
- [ ] Run the repository-wide Codex Security scan and final security diff scan; fix validated publication-blocking findings with test-first evidence.
- [ ] Generate a fresh clone/worktree from the final commit and follow only public documentation.
- [ ] Request independent whole-branch code review and fix every critical/important finding.
- [ ] Inspect the final diff, tracked binaries, large files, personal paths, placeholders, and private data.
- [ ] Update final plans, TODOs, memory, gate matrix, and owner action ledger.
- [ ] Commit intentional files. Do not push, open a PR, merge, tag, notarize, or publish without separate authorization.

## Verification

- `swift test`
- `cargo fmt --manifest-path analytics/ffi/Cargo.toml --check`
- `cargo clippy --manifest-path analytics/ffi/Cargo.toml --all-targets --all-features --locked -- -D warnings`
- `cargo test --manifest-path analytics/ffi/Cargo.toml --locked`
- `cargo audit --file analytics/ffi/Cargo.lock`
- `uv sync --project analytics --extra dev --frozen`
- `analytics/.venv/bin/python -m ruff format --check analytics scripts`
- `analytics/.venv/bin/python -m ruff check analytics scripts`
- `analytics/.venv/bin/python -m pytest analytics/tests -v`
- `xcodegen generate --spec project.yml && git diff --exit-code -- LiteratureAtlas.xcodeproj`
- `python3 scripts/validate_release_configuration.py`
- `scripts/tests/test_release_scripts.sh`
- `script/build_community.sh --product-name LiteratureAtlasCommunity --bundle-id org.example.LiteratureAtlasCommunity --version 1.0.0 --build 1 --output dist/community`
- `script/verify_distribution.sh --app dist/community/LiteratureAtlasCommunity.app --mode community`
- `reuse lint`
- current-tree and reachable-history secret scans
- source and artifact SBOM validation
- fresh relocated launch and strict runtime log scan

## Decision Log

- 2026-07-15: Adopted `c7f4215` as the technical baseline because it is the same-day release-hardened version; direct Developer ID distribution replaces, rather than discards, its macOS App Store infrastructure.
- 2026-07-15: Kept MIT effective because the repository is already public and prior MIT grants exist; MPL-2.0 remains a proposed future relicense pending explicit rights confirmation.
- 2026-07-15: Chose a native-only first distributed app; Python and optional Rust acceleration remain public contributor tooling unless separately packaged and verified.

## Progress Log

- 2026-07-15: Created isolated worktree and branch, adopted release baseline, completed initial parallel audit dispatch, and committed the approved design.
- 2026-07-15: Next: repair baseline gates and implement the shared distributed-build/runtime boundary.

## Rollback / Recovery

- If a runtime boundary regresses contributor behavior, revert only the focused task commit and retain the adopted release baseline.
- If Developer ID packaging cannot be validated locally, preserve the unsigned/community pipeline and report Apple credentials/notarization as external blockers.
- If licensing or ownership evidence is insufficient, keep MIT, omit unverified material from new release assets, and report the exact legal blocker.
- Never remove the worktree, delete the branch, rewrite history, or discard commits without explicit confirmation.
