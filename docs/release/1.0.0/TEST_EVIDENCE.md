# LiteratureAtlas 1.0.0 Test Evidence

## Candidate coordinates

- Canonical repository: `https://github.com/rsitech-ai/LiteratureAtlas`
- Version/build: `1.0.0` / `1`
- Bundle identifier: `ai.rsitech.LiteratureAtlas`
- Direct-download identity: `Developer ID Application: Rafal Sikora (2NY8A789TN)`
- Architecture / minimum OS: `arm64` / macOS 26.0
- Exact merged source SHA: pending migration PR

## Repository gates

The local candidate results below were captured before commit and are rerun on
the exact PR head by protected-branch workflows.

| Gate | Command | Result |
| --- | --- | --- |
| Python environment | `uv sync --project analytics --extra dev --frozen` | Pass, uv 0.5.23 / Python 3.12.10 |
| Python format/lint/tests | Ruff checks and `pytest analytics/tests` | Pass, 65 tests |
| Swift | `swift test -Xswiftc -warnings-as-errors` | Pass, 90 XCTest cases with 1 authorized-corpus smoke skipped; 4 Swift Testing cases passed |
| Rust | locked format, strict Clippy, 7 tests, and audit | Pass; no known vulnerability, one documented unmaintained `bincode` warning |
| Release scripts | `scripts/tests/test_release_scripts.sh` | Pass |
| Release configuration | `scripts/validate_release_configuration.py` | Pass, all 15 gates including AppIcon |
| License compliance | `uv tool run --from reuse==5.1.1 reuse lint` | Pass, REUSE 3.3 / 251 of 251 files |
| Deterministic project | regenerate with XcodeGen and require identical diff | Pass, XcodeGen 2.45.4 |
| AppIcon asset compiler | standalone macOS and iPhone/iPad `actool` compiles | Pass, macOS `AppIcon.icns`/`Assets.car` and iPhone/iPad asset output produced |
| macOS/iPadOS Xcode archives | unsigned archive construction | Local environment blocked: Xcode 26.6 build service pipe deadlock also affects unrelated workspaces; exact-head hosted Apple job required |
| Native smoke | `./script/build_and_run.sh --verify` | Pass, app built and process launched with `ai.rsitech.LiteratureAtlas` |

The formal Codex Security scan is excluded by explicit user direction. This
does not waive the repository-native tests, dependency audit, CodeQL workflow,
or secret-pattern gate required by the protected branch.

## Distribution evidence

These fields are completed only after the migration PR merges and the exact
merged source is packaged.

| Evidence | Result |
| --- | --- |
| Merged source SHA | Pending |
| Signed app SHA-256 | Pending |
| DMG SHA-256 | Pending |
| App SPDX SBOM SHA-256 | Pending |
| Notary submission ID/status | Pending |
| Stapler validation | Pending |
| Gatekeeper assessment | Pending |
| Mounted app byte equality | Pending |
| Relocated launch/log smoke | Pending |
| Org release URL | Pending |
| Remote asset byte verification | Pending |
