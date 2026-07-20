# Publication gate matrix

| Gate | State | Evidence / next action |
|---|---|---|
| Effective OSI license | Pass | Apache-2.0 `LICENSE`, `NOTICE`, package metadata, and REUSE annotation |
| Copyright/licensing authority | Pass | Rafal Sikora confirmed owner and licensing authority; prior MIT grants preserved |
| Canonical history IP | Pass | Fresh org clone has no PDF path or audited PDF blob; only rewritten `main` published |
| Public maintainer/contact | Pass | RSI Tech; `https://rsitech.ai`; `info@rsitech.ai` |
| Governance/DCO | Pass | Single-maintainer governance, CODEOWNERS, DCO 1.1, web sign-off required |
| Private security/conduct route | Pass | GitHub PVR plus `info@rsitech.ai` |
| Distributed privacy/runtime boundary | Pass, reverify | Existing tests and artifact marker checks; rerun on exact PR/release source |
| Source tests/builds | Pass locally, pending exact head | Python, Swift, Rust, release policy, validator, and runtime smoke pass; hosted archive proof remains exact-PR-head work |
| CI workflow policy | Pass configuration, pending hosted run | Only org-allowed GitHub actions remain; tools are pinned and release-candidate build is credential-free |
| Source/dependency SBOM | Pass, reverify exact head | Deterministic source SPDX covers all 252 in-scope files; frozen Python/Rust inventories retain upstream licenses |
| Production artwork | Pass | Complete opaque RSI Tech/LiteratureAtlas AppIcon catalog passes validation and standalone asset compilation |
| Developer ID identity | Pass prerequisite | Valid installed Developer ID Application identity for Team `2NY8A789TN` |
| Notary credentials | Pass prerequisite | Authenticated read-only notary history succeeded with external keychain profile |
| Exact signed/notarized artifact | Pending | Build only after PR merge; verify signature, notarization, staple, Gatekeeper, DMG equality |
| Release checksum/SBOM/provenance | Pending | Generate from exact signed/stapled artifact and reconcile source mapping |
| Download availability | Pending | Publish org release and verify remote bytes before retiring personal prerelease |
| Formal Codex Security scan | Excluded | Explicit user direction; do not translate scoped repository checks into exhaustive proof |
| iPad App Store | Blocked external | Separate identifiers, profiles, metadata, device, and upload gates |

Overall direct-download verdict: **RELEASE CANDIDATE**.
