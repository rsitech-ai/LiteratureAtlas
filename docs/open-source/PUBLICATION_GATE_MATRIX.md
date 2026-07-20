# Publication gate matrix

| Gate | State | Evidence / next action |
|---|---|---|
| Effective OSI license | Pass | Existing MIT `LICENSE`; no restrictive terms |
| Authority to relicense | Blocked | Confirm rights holders before MPL/CC proposal |
| Current-tree third-party content | Pass with review | No bundled PDFs; notices and current source ecosystems inventoried |
| Reachable history IP | Blocked | Four third-party PDFs; clean-history or approved rewrite decision |
| Secret/history scan | Warning | Manual redacted worktree/history scan found no credential; formal Codex Security scan excluded for this delta; repeat repository-native checks on final commit |
| Distributed privacy/runtime boundary | Pass | Tests and artifact marker checks |
| Community build | Current pass / published prerelease | Merge commit `95d0031a`: exact ad-hoc app/DMG verification, mounted-content comparison, relocated launch/log smoke, checksum, exact-app SBOM, and remote byte-for-byte download verification; not notarized |
| Official pre-sign build | Historical pass only | Commit `647911a`: signature-free arm64 app, exact identity/version/source mapping, 35 prompts, dSYM, no checkout-only markers; rebuild from approved current source before release |
| Official Developer ID signature | Blocked external | Owner must authorize the installed private key for the exact pre-sign candidate |
| Notarization/stapling/Gatekeeper | Blocked external | No Apple upload authorized or performed |
| Production artwork | Blocked | Release validator: `app_icon_artwork` |
| Source tests/builds | Pass locally | Python format/lint and 60 tests, Swift warnings-as-errors and 89 XCTest/4 Swift Testing cases, Rust format/strict Clippy/7 tests/release build, macOS and iPadOS arm64 Release archives, release-policy suite, and canonical launch smoke passed; the corpus ingest smoke remains intentionally gated on an authorized user corpus |
| CI workflow hardening | Warning / hosted candidate pending | Workflows are SHA-pinned and read-only; GitHub dependency alerts/security updates, private reporting, full-length Action SHA enforcement, merged-branch cleanup, and repository metadata are enabled. Fresh candidate checks and main protection/required checks remain pending |
| Source/dependency SBOM | Pass locally | Current follow-up source and frozen Python/Rust dependency inventories are under `sbom/`; regenerate after any later source or lock change |
| Community/pre-sign app SBOM | Current community pass; pre-sign historical | The `v1.0.0-community.1` release includes a 40-file exact-app SPDX SBOM; commit-`647911a` tracked app inventories remain historical snapshots |
| Official artifact SBOM/provenance | Blocked | Generate from exact signed candidate and attest source mapping |
| Private security contact | Pass | GitHub private vulnerability reporting is enabled and linked from `SECURITY.md`; a separate private conduct route remains a governance blocker |
| Governance/DCO | Blocked owner | Approve roster, authority, DCO versus CLA |
| Trademark/branding authority | Blocked owner | Confirm owner and marks; technical rebrand policy exists |
| Fresh clone | Historical pass only | Commit `a8f2f2a`: locked restore, complete language/release suite, and warning-free macOS/iOS Release builds; repeat for the approved current source |
| macOS 26 local hardware | Historical pass only | The commit-`647911a` relocated community app launched, navigated, ingested, and relaunched cleanly |
| Download quarantine acceptance | Blocked external | Test the future downloaded and notarized DMG on supported hardware |
| Tag/release/public announcement | Community exception published | `v1.0.0-community.1` is explicitly labeled ad-hoc/not notarized; official production tag/release/announcement still requires separate approval |

Overall verdict: **BLOCKED**.
