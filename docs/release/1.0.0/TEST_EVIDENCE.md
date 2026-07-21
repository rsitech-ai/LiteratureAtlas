# LiteratureAtlas 1.0.0 Test Evidence

## Candidate coordinates

- Canonical repository: `https://github.com/rsitech-ai/LiteratureAtlas`
- Version/build: `1.0.0` / `1`
- Bundle identifier: `ai.rsitech.LiteratureAtlas`
- Direct-download identity: `Developer ID Application: Rafal Sikora (2NY8A789TN)`
- Architecture / minimum OS: `arm64` / macOS 26.0
- Exact merged source SHA: `88f7d5e7c373226eb3861277ba9ca6a57f5e8774`
- Migration PR: [#4](https://github.com/rsitech-ai/LiteratureAtlas/pull/4), reviewed head `712754f8c8d2696f6c1621d1b7e526384cb35b11`, merged through protected `main`
- Exact-main unsigned build: [GitHub Actions run 29782445124](https://github.com/rsitech-ai/LiteratureAtlas/actions/runs/29782445124)

## Repository gates

The local results below were captured from the evidence working tree.
Protected-branch workflows rerun the applicable gates for every release-evidence
PR before it can merge.

| Gate | Command | Result |
| --- | --- | --- |
| Python environment | `uv sync --project analytics --extra dev --frozen` | Pass, uv 0.5.23 / Python 3.12.10 |
| Python format/lint/tests | Ruff checks and `pytest analytics/tests` | Pass, 65 tests |
| Swift | `swift test -Xswiftc -warnings-as-errors` | Pass, 90 XCTest cases with 1 authorized-corpus smoke skipped; 4 Swift Testing cases passed |
| Rust | locked format, strict Clippy, 7 tests, and audit | Pass; no known vulnerability, one documented unmaintained `bincode` warning |
| Release scripts | `scripts/tests/test_release_scripts.sh` | Pass |
| Release configuration | `scripts/validate_release_configuration.py` | Pass, all 15 gates including AppIcon |
| License compliance | `uv tool run --from reuse==5.1.1 reuse lint` | Pass, REUSE 3.3 / 254 of 254 files |
| Deterministic project | regenerate with XcodeGen and require identical diff | Pass, XcodeGen 2.45.4 |
| AppIcon asset compiler | standalone macOS and iPhone/iPad `actool` compiles | Pass, macOS `AppIcon.icns`/`Assets.car` and iPhone/iPad asset output produced |
| macOS/iPadOS Xcode archives | unsigned archive construction | Local Xcode 26.6 build-service pipe deadlock documented; exact-main hosted macOS build passed in run 29782445124. iPad archive remains outside this direct-download artifact |
| Native smoke | `./script/build_and_run.sh --verify` | Pass, app built and process launched with `ai.rsitech.LiteratureAtlas` |

The formal Codex Security scan is excluded by explicit user direction. This
does not waive the repository-native tests, dependency audit, CodeQL workflow,
or secret-pattern gate required by the protected branch.

## Distribution evidence

The artifact was built unsigned by the credential-free exact-main workflow,
transport-verified, signed locally with Developer ID, packaged, submitted once
to Apple, stapled after acceptance, and then verified from public downloads.

| Evidence | Result |
| --- | --- |
| Merged source SHA | `88f7d5e7c373226eb3861277ba9ca6a57f5e8774`; embedded source revision matched |
| Signed app tree SHA-256 | `21a699b74a0578cb5636513601b0cab62810e750948127203271949cca8afdaf`; SPDX namespace digest over paths, modes, symlinks, and file hashes |
| DMG SHA-256 | Pre-staple approved/submitted: `48d647b0595ab0554d8a1418a76ffce82b2b9fdc54512488f6325ac83d8101e9`; published post-staple: `f2fc0c5ec19831213e1dcd0ea4d6fe104a890fdaae821a581e5ce5d4af108c20` |
| Checksum-file SHA-256 | `30f31497601620afaa1196feb0fb00523d4071a2b91ab35848da741dd442d5ad`; downloaded checksum reports DMG `OK` |
| App SPDX SBOM SHA-256 | `cd5d9b6cb620b3ec7191e3bdb9e6aba7004d35227f5230d0eb49bb9598c76440`; 42 files |
| Notary submission ID/status | `68cc41be-2f44-4650-a731-ec1e5a042f3f` / `Accepted`; Apple summary `Ready for distribution`, no issues |
| Stapler validation | Pass on the exact submitted DMG after ticket attachment |
| Gatekeeper assessment | Pass on signed app: `source=Notarized Developer ID`, origin `Developer ID Application: Rafal Sikora (2NY8A789TN)` |
| Mounted app byte equality | Pass; deterministic path/mode/type/hash manifests were identical |
| Relocated launch/log smoke | Pass at `2026-07-21T04:08:08Z`; quarantined copy launched, remained alive, and fatal-log scan was clean |
| Org release URL | [LiteratureAtlas 1.0.0](https://github.com/rsitech-ai/LiteratureAtlas/releases/tag/v1.0.0), published `2026-07-21T04:09:36Z` |
| Remote asset byte verification | Pass for DMG, checksum, and app SPDX SBOM through authenticated draft download and unauthenticated public URLs |

The preserved Apple primary evidence is in
[`NOTARY_SUBMISSION.json`](NOTARY_SUBMISSION.json) and
[`NOTARY_LOG.json`](NOTARY_LOG.json).

The DMG is an unsigned transport container. Apple documents in its
[notarization prerequisites](https://developer.apple.com/news/?id=12232019a)
that disk images do not need a code signature. The submitted DMG ticket is validated with
`stapler`; Gatekeeper is evaluated against the Developer ID-signed app inside.
The formal Codex Security scan remained excluded by explicit user direction.
