# TODO

## Tasks
- [x] Baseline inventory and verification (DoD: local/remote/GitHub state, tool versions, pre-change passes/failures, and authority boundary are recorded)
- [x] Privacy, provenance, and workflow audit (DoD: validated findings are redacted, prioritized, and either remediated or explicitly blocked)
- [x] Code and test audit (DoD: production-impacting defects and test gaps are fixed or documented with exact evidence)
- [x] Documentation and community audit (DoD: public claims, commands, links, templates, metadata, and contributor paths are accurate and usable)
- [x] Release and package audit (DoD: version sources, community build, checksums, SBOM, release notes, and official blockers are internally consistent)
- [x] GitHub configuration (DoD: authorized repository metadata/settings are improved and verified; profile-wide changes remain separate unless explicitly supported)
- [x] Full local verification (DoD: format, lint, tests, builds, policy checks, runtime smoke, and artifact checks pass or have accepted evidence-backed limitations)
- [x] Fresh-clone/public rehearsal (DoD: an isolated tracked-source checkout follows documented setup and validates the supported artifact path)
- [x] Review, integrate, and push (DoD: intentional commits are reviewed, integrated into `main`, pushed, and exact hosted SHA/check state is verified)
- [x] Safe cleanup (DoD: only proven ignored/generated caches are removed; user data, environments, and release evidence are preserved)
- [x] Memory update and closeout (DoD: PLAN/TODO/MEMORY contain exact final evidence and no task placeholder remains)

## In progress
- None.

## Done
- [x] HQ session bootstrap and continuity check passed.
- [x] User explicitly excluded the formal Codex Security scan and authorized push to `main` plus safe cleanup.
- [x] Refreshed `origin`; clean local `main` matched `origin/main` at `2ee1adf6c7204f3bb4524c2c1a2d872fe8bc9e83` before branching.
- [x] Created `chore/oss-release-readiness` from the verified baseline.
- [x] Reviewed head `9b62c14a067d404821b9e8a03285fe6b140d660d` passed a frozen clean-room restore; Ruff and 61 Python tests; 7 Rust tests; warnings-as-errors Swift tests with 90 XCTest, 1 authorized corpus skip, and 4 Swift Testing cases; credential-free community build; mounted DMG byte comparison; portable checksum verification; and relocated launch smoke.
- [x] PR #11 passed Apple/Swift/distribution, macOS/Linux Python, Rust, release policy, REUSE, dependency review, and Swift/Python CodeQL; zero open CodeQL alerts remained on the reviewed branch.
- [x] PR #11 merged as `88f914bf98dcd032a638d0f28c8a719170bb7352` and protected `main` now requires current pull requests, nine named checks, and resolved conversations; force pushes and deletion are disabled.
- [x] Removed only ignored/generated Swift, Rust, Ruff, pytest, distribution, and exact temporary rehearsal outputs; preserved `Output/`, `analytics/.venv`, examples, user data, and release evidence.
