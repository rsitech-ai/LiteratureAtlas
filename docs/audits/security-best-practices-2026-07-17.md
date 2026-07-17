# Security best-practices review — 2026-07-17

## Result

No unresolved repository-owned security vulnerability was validated. The local
contributor build and distributed Release build have intentionally different
capabilities; policy tests prove that Python execution, relative Rust library
loading, environment API keys, and dormant remote compilation are excluded from
the distributed build.

## Trust boundaries reviewed

| Boundary | Controls verified |
| --- | --- |
| Selected local files | Read-only security-scoped bookmarks, stale refresh, balanced scope lifetime, explicit access errors. |
| Markdown/PDF/JSON input | Type/range/finite/dimension validation, canonical identity deduplication, explicit malformed-input reporting. |
| DuckDB/Parquet | Parameterized file paths, validated dynamic identifiers, guaranteed connection close. |
| Python process | Canonical project virtual environment, frozen lock sync, explicit executable resolution, no silent global fallback. |
| Rust C ABI | Versioned length-aware query symbol, null/overflow/dimension/finite checks, documented non-null pointer and positive-weight contracts, panic containment. |
| Local diagnostics | Paths and raw user questions are excluded from unified logs and analytics events. |
| Release scripts | Strict input validation, exact source revision, clean-source recheck, explicit signer/notary authority, atomic evidence. |
| Distributed app | Sandbox, hardened runtime policy, bundled prompts, no checkout-only execution capability. |

## Dependency and supply-chain evidence

- Python frozen environment: NumPy 2.5.1, SciPy 1.18.0, scikit-learn 1.9.0;
  `pip-audit` found no known vulnerability in the installed environment.
- Rust: `hnsw_rs 0.3.4`; `cargo audit` found no vulnerability. RustSec reports
  `RUSTSEC-2025-0141` because transitive `bincode 1.3.3` is unmaintained. The
  affected crate is used internally by `hnsw_rs`; LiteratureAtlas exposes no
  bincode deserialization surface, and Rust acceleration is excluded from the
  distributed app. Recheck when `hnsw_rs` removes or upgrades that dependency.
- Lockfiles remain mandatory even when GitHub dependency-review cannot access
  an owner-disabled dependency graph; unexpected API and permission failures
  remain fail-closed.
- SPDX source and artifact namespaces bind path, file type, mode, symlink target,
  and SHA-256. Official signed
  candidates still require a new post-staple SBOM and provenance reconciliation.

## Privacy review

- Question analytics records length/retrieval/answer lifecycle without raw
  question text; generated question filenames use a SHA-256 digest.
- Logs do not expose document paths, API keys, credentials, or user content.
- The committed privacy manifests cover the validated required-reason file
  timestamp API. Owner-provided App Privacy answers remain external release
  evidence and were not inferred.

## Residual risks and ownership

- Developer ID credentials, notarization, Apple privacy answers, legal rights,
  branch protection, private vulnerability reporting, and public release are
  owner-controlled and remain `blocked:external`.
- The unmaintained transitive `bincode` dependency is an accepted maintenance
  risk, not a validated vulnerability; monitor upstream `hnsw_rs` releases.
- The contributor build intentionally runs local Python and can read explicit
  environment API keys. It must not be presented as the distributed capability
  boundary; the Release compilation checks enforce that distinction.
