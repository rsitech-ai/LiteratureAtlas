# LiteratureAtlas 1.0.0 Security Status

## Status

`PASS WITH EXTERNAL RELEASE BLOCKERS`

No validated high- or critical-severity exploitable issue remains in the repository-side App Store runtime boundary. Distribution signing, Apple validation, physical-device permission behavior, and final owner privacy/legal attestations are still required.

The exact local branch diff received a complete Codex Security full-file scan of all 20 changed source-like files. The sealed result contains zero reportable findings, zero deferred rows, and complete coverage for the selected diff inventory:

- Report: `/private/var/folders/g6/mrhqfgk15_d2gjj52991r1jr0000gn/T/codex-security-scans/LiteratureAtlas/0d99116_20260715T140429Z/report.md`
- Snapshot: `codex-security-snapshot/v1:sha256:428594bedcaf6a1f2ebe279e8950442f1db9f2a0b0200988a891d073f684bda8`
- Canonical artifacts: sealed `scan-manifest.json`, `findings.json`, and `coverage.json`

This is a branch-diff scan, not an exhaustive repository-wide audit. Documentation and images were excluded from runtime deep review; added documentation lines were still checked for obvious credential patterns.

## Closed release findings

| Finding | Resolution | Verification |
| --- | --- | --- |
| App executed external Python and installed dependencies at runtime | Python analytics and install controls are excluded from `APP_STORE_BUILD` | Release compiler condition, validator, archive executable string scan |
| Rust FFI loaded from repository-relative paths | App Store build disables relative `dlopen` and uses the pure-Swift path | Release compiler condition, validator, executable string scan |
| Mutable data depended on repository/current working directory | App Store build writes under container Application Support and bundles prompts | Focused `AppPaths` tests; sandboxed runtime container evidence; `/Output` absent |
| App Store product retained a dormant OpenAI endpoint | Provider is excluded from `APP_STORE_BUILD` | Compiler condition and packaged executable string scan |
| No application sandbox/entitlements/privacy manifests | Least-privilege platform files are committed and packaged | Validator, build logs, codesign entitlement inspection, archive inspection |
| Folder enumeration happened before security-scoped access | Selected folder scope now opens before `fileExists`/enumeration | Red/green validator regression test and source-order gate |
| Known Rust advisories in `bytes` and `crossbeam-epoch` | Lock updated to `bytes 1.11.1` and `crossbeam-epoch 0.9.20`; `anyhow` and `rand` also refreshed | `cargo audit`, strict clippy, tests |

## Dependency status

- Rust: no known vulnerability reported by `cargo-audit 0.22.2` for the FFI lock.
- Rust maintenance warning: `bincode 1.3.3`, `RUSTSEC-2025-0141`, unmaintained. This is tracked debt and not loaded through the App Store runtime FFI boundary.
- Python: lock is current; exported production requirements report no known vulnerabilities through `pip-audit --disable-pip`.
- Application products: no third-party runtime frameworks or SDKs are linked.

## Signing and sandbox evidence

- Local macOS Debug runtime was ad-hoc signed “Sign to Run Locally” with App Sandbox, read-only user-selected files, and debug-only `get-task-allow`.
- Unsigned archives intentionally have no Team/signing identity. They prove deterministic Release construction, not distributability.
- The final distribution archive must not contain `get-task-allow` and must be signed with the confirmed App Store team/profile.

## Lightweight runtime diagnostics

- After about 20 minutes, the macOS runtime was idle at 0.0% CPU with roughly 20 MB RSS in the point-in-time `ps` sample.
- `leaks` reported 20,016 bytes across 417 allocations. The report's roots were Apple framework XPC cycles (Link/AppIntents); no LiteratureAtlas-owned frame was present. Treat this as a compatibility-runtime observation, not proof of zero leaks.
- Physical-device Instruments/ETTrace evidence is not available and remains part of final release-candidate acceptance.

## Remaining security gates

- Distribution signature, profile, entitlement, hardened-runtime, and archive validation inspection.
- Physical macOS 26 and iPadOS 26 permission-denial/retry, malformed-input, interruption, low-storage, lifecycle, and offline tests.
- Owner confirmation of privacy/support operations and any production telemetry not represented in this repository.
