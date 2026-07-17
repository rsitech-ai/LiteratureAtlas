# Publication gate matrix

| Gate | State | Evidence / next action |
|---|---|---|
| Effective OSI license | Pass | Existing MIT `LICENSE`; no restrictive terms |
| Authority to relicense | Blocked | Confirm rights holders before MPL/CC proposal |
| Current-tree third-party content | Pass with review | No bundled PDFs; notices and current source ecosystems inventoried |
| Reachable history IP | Blocked | Four third-party PDFs; clean-history or approved rewrite decision |
| Secret/history scan | Pass | No credential found; repeat on final commit |
| Distributed privacy/runtime boundary | Pass | Tests and artifact marker checks |
| Community build | Historical pass only | Commit `647911a`: exact ad-hoc app/DMG verification, dSYM, six-destination click sweep, real sandboxed ingest, relaunch persistence; exact artifact directory is no longer retained |
| Official pre-sign build | Historical pass only | Commit `647911a`: signature-free arm64 app, exact identity/version/source mapping, 35 prompts, dSYM, no checkout-only markers; rebuild from approved current source before release |
| Official Developer ID signature | Blocked external | Owner must authorize the installed private key for the exact pre-sign candidate |
| Notarization/stapling/Gatekeeper | Blocked external | No Apple upload authorized or performed |
| Production artwork | Blocked | Release validator: `app_icon_artwork` |
| Source tests/builds | Pass | Swift/Python/Rust/Xcode and release-policy gates pass; Release fails on Swift warnings |
| CI workflow hardening | Pass locally / blocked external | Workflows pinned and locally validated; main protection, required checks, Dependabot security updates, and private reporting remain disabled |
| Source/dependency SBOM | Pass locally | Current follow-up source and frozen Python/Rust dependency inventories are under `sbom/`; regenerate after any later source or lock change |
| Community/pre-sign app SBOM | Historical snapshots only | Commit-`647911a` app inventories remain exact historical evidence; regenerate from every future exact packaged artifact |
| Official artifact SBOM/provenance | Blocked | Generate from exact signed candidate and attest source mapping |
| Private security contact | Blocked external | Enable GitHub private reporting or approved monitored route |
| Governance/DCO | Blocked owner | Approve roster, authority, DCO versus CLA |
| Trademark/branding authority | Blocked owner | Confirm owner and marks; technical rebrand policy exists |
| Fresh clone | Historical pass only | Commit `a8f2f2a`: locked restore, complete language/release suite, and warning-free macOS/iOS Release builds; repeat for the approved current source |
| macOS 26 local hardware | Historical pass only | The commit-`647911a` relocated community app launched, navigated, ingested, and relaunched cleanly |
| Download quarantine acceptance | Blocked external | Test the future downloaded and notarized DMG on supported hardware |
| Tag/release/public announcement | Not authorized | Separate explicit approval required |

Overall verdict: **BLOCKED**.
