# TODO

## Tasks
- [x] Baseline inventory and current-doc map (DoD: targets, dependencies, services, flows, external gates, and official sources are recorded in the audit report)
- [x] Static architecture/correctness/security review (DoD: all production Swift/Python/Rust/release/workflow paths are reviewed and every material finding has file/line evidence)
- [x] Fresh local quality matrix (DoD: relevant format, lint, build, test, dependency, release-policy, SBOM, and warning gates pass or have exact blockers)
- [x] Native macOS E2E matrix (DoD: a freshly built app exercises all reachable primary surfaces, reversible edge paths, relaunch persistence, and focused logs with evidence)
- [x] Fix reproduced repository-owned defects (DoD: each fix has focused failing proof before and passing proof after, plus parent-workflow verification)
- [x] Performance/accessibility/polish pass (DoD: release-relevant launch, interaction, resizing, motion, contrast, keyboard, labels/help, and log behavior are verified or explicitly blocked)
- [x] Audit and security reports (DoD: July 17 reports contain commands, sources, scenario results, findings/fixes, remaining risks, and the weakest truthful readiness label)
- [x] Memory update (DoD: `MEMORY.md` contains any new durable knowledge and no task-history noise)
- [x] Independent review and final local ship gate (DoD: no unresolved blocker/high/important finding; full diff and fresh verification matrix are clean)
- [ ] Publish reviewed PR (DoD: intentional commits are pushed, PR is reviewed, hosted checks pass, actionable feedback is resolved, and the approved head is merged)
- [ ] Verify exact merged `main` (DoD: local `main`, `origin/main`, PR merge tree, and required post-merge commands agree)

## In progress
- [ ] Publish reviewed PR

## Done
- [x] HQ session bootstrap completed; repository instructions, memory, previous plan/TODO, and Git baseline reviewed.
- [x] Clean `bde3e9f` baseline preserved on `feat/andrzej_full_audit_2026_07_17`.
- [x] Isolated native E2E, focused regression fixes, dependency SBOM refresh, and audit/security reports completed without modifying the 3,919-paper user corpus.

## External / owner-controlled blockers to revalidate
- Approved production app icon/brand provenance and legal chain of title.
- Developer ID private-key authorization, notarization upload, quarantine/hardware acceptance, tag, and public binary release.
- Owner-controlled GitHub repository protection, private reporting, and security settings.
