# Publication gate matrix

| Gate | State | Evidence / next action |
|---|---|---|
| Effective OSI license | Pass | Apache-2.0 `LICENSE`, `NOTICE`, package metadata, and REUSE annotation |
| Copyright/licensing authority | Pass | Rafal Sikora confirmed owner and licensing authority; prior MIT grants preserved |
| Canonical history IP | Pass | Fresh org clone has no PDF path or audited PDF blob; only rewritten `main` published |
| Public maintainer/contact | Pass | RSI Tech; `https://rsitech.ai`; `info@rsitech.ai` |
| Governance/DCO | Pass | Single-maintainer governance, CODEOWNERS, DCO 1.1, web sign-off required |
| Private security/conduct route | Pass | GitHub PVR plus `info@rsitech.ai` |
| Distributed privacy/runtime boundary | Pass | Exact release verifier passed marker, entitlement, signature, and mounted equality; separate quarantine, relocated launch, and fatal-log checks passed |
| Source tests/builds | Pass | PR #4 required checks passed; exact-main unsigned release workflow run 29782445124 succeeded |
| CI workflow policy | Pass | Only org-allowed GitHub actions remain; tools are pinned and the credential-free exact-main build passed |
| Source/dependency SBOM | Pass | Deterministic source SPDX reflects the cleaned current public tree; frozen Python/Rust inventories retain upstream licenses; exact app SPDX is published |
| Production artwork | Pass | Complete opaque RSI Tech/LiteratureAtlas AppIcon catalog passes validation and standalone asset compilation |
| Developer ID identity | Pass | Exact app is signed by Developer ID Application Team `2NY8A789TN` with secure timestamp and hardened runtime |
| Notary credentials | Pass | Exact request `68cc41be-2f44-4650-a731-ec1e5a042f3f` returned `Accepted` with no issues |
| Exact signed/notarized artifact | Pass | Stapled DMG validates; embedded app equality and app Gatekeeper acceptance passed |
| Release checksum/SBOM/provenance | Pass | Published DMG SHA-256 `f2fc0c5e…`, checksum, app SPDX, and source mapping recorded |
| Download availability | Pass | Public `v1.0.0` assets matched local bytes; legacy prerelease/tag removed afterward |
| Formal Codex Security scan | Excluded | Explicit user direction; do not translate scoped repository checks into exhaustive proof |
| iPad App Store | Blocked external | Separate identifiers, profiles, metadata, device, and upload gates |

Overall direct-download verdict: **RELEASED**.
