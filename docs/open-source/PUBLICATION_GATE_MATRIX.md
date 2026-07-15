# Publication gate matrix

| Gate | State | Evidence / next action |
|---|---|---|
| Effective OSI license | Pass | Existing MIT `LICENSE`; no restrictive terms |
| Authority to relicense | Blocked | Confirm rights holders before MPL/CC proposal |
| Current-tree third-party content | Pass with review | No bundled PDFs; exact notices/SBOM pending |
| Reachable history IP | Blocked | Four third-party PDFs; clean-history or approved rewrite decision |
| Secret/history scan | Pass | No credential found; repeat on final commit |
| Distributed privacy/runtime boundary | Pass | Tests and artifact marker checks |
| Community build | Pass | Ad-hoc app, relocation launch, DMG and checksum verified |
| Official pre-sign build | Pass | Fresh signature-free arm64 app; resources and runtime markers inspected |
| Official Developer ID signature | Blocked external | Owner must authorize the installed private key for the exact pre-sign candidate |
| Notarization/stapling/Gatekeeper | Blocked external | No Apple upload authorized or performed |
| Production artwork | Blocked | Release validator: `app_icon_artwork` |
| Source tests/builds | Pass | Swift/Python/Rust/Xcode gates pass |
| CI workflow hardening | In progress | Pin actions/tools and validate workflows locally |
| Source/community SBOM | Pass | Pinned Syft and CycloneDX inventories under `sbom/` |
| Official artifact SBOM/provenance | Blocked | Generate from exact signed candidate and attest source mapping |
| Private security contact | Blocked external | Enable GitHub private reporting or approved monitored route |
| Governance/DCO | Blocked owner | Approve roster, authority, DCO versus CLA |
| Trademark/branding authority | Blocked owner | Confirm owner and marks; technical rebrand policy exists |
| Fresh clone | Pending | Run after final local commit |
| macOS 26 hardware/quarantine test | Blocked external | Owner/hardware acceptance required |
| Tag/release/public announcement | Not authorized | Separate explicit approval required |

Overall verdict: **BLOCKED**.
