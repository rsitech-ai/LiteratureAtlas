# End-to-end implementation audit — 2026-07-17

## Verdict

- Repository implementation: **repo-ready**, pending final PR/hosted-check/merge proof.
- Local contributor app: **runtime-proven** with an isolated Markdown corpus.
- Official Developer ID/notarized artifact: **blocked:external**.
- App Store / public binary publication: **blocked:external** by approved icon
  artwork, Apple credentials, notarization, legal provenance, and owner-managed
  repository settings.
- No unresolved repository-owned blocker or high-severity finding remains.

## Scope and authority

The audit reconstructed the full path from source discovery through SwiftUI
ingestion, persistence, analytics export, Python/DuckDB processing, optional
Rust FFI acceleration, generated Xcode targets, release packaging, and native
macOS interaction. It reviewed production source and tests line by line where a
boundary or failure mode was material, then exercised a fresh app against a
disposable fixture at `/private/tmp/LiteratureAtlas-UI-Audit` without changing
the user's 3,919-paper corpus.

No Developer ID key, notarization submission, public release, legal assertion,
or destructive user-data action was performed.

## Authoritative references

- Apple: [App Sandbox file access and security-scoped bookmarks](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox),
  [hardened runtime](https://developer.apple.com/documentation/security/hardened-runtime),
  [configuring hardened runtime](https://developer.apple.com/documentation/xcode/configuring-the-hardened-runtime/),
  [notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution),
  and [privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files).
- DuckDB: [Python DB API](https://duckdb.org/docs/stable/clients/python/dbapi) and
  [securing DuckDB](https://duckdb.org/docs/stable/operations_manual/securing_duckdb/overview).
- Rust/Cargo: [unwinding safety](https://doc.rust-lang.org/std/panic/fn.catch_unwind.html),
  [Rust 2021 C-unwind behavior](https://doc.rust-lang.org/edition-guide/rust-2021/c-unwind-abi.html),
  and [Cargo `rust-version`](https://doc.rust-lang.org/cargo/reference/rust-version.html).
- Python scientific stack: current NumPy, SciPy, and scikit-learn release
  documentation; the frozen environment was also recreated and import-tested
  on the audited macOS host.
- GitHub: workflow, dependency-review, dependency-graph, and CodeQL behavior
  was checked against current GitHub documentation and the repository's policy
  tests.

## Architecture and flow verification

| Boundary | Expected flow | Verified result |
| --- | --- | --- |
| Source access | User-selected folder -> durable read-only bookmark -> balanced security scope | Existing bookmark tests and native ingest/relaunch proof pass. |
| Ingestion | Validate PDF/Markdown -> parse metadata/body -> embed -> commit canonical paper/chunk state -> publish memory -> derive document/Markdown exports | Canonical write failures publish neither papers nor chunks; frontmatter year, final section range, duplicate identity, checksum skip, and source-kind counts are correct. |
| App state | Canonical persistence succeeds before in-memory publication; derived-export failures stay visible; async work cannot publish stale results | Paper/project transactions, project-note deletion, per-paper task cancellation, and clustering run tokens are covered by regressions. |
| Analytics | Strict validated JSON/parquet -> parameterized DuckDB writes -> finite deterministic summary | Frozen rebuild and isolated artifact/topic audits pass with no warning or finding. |
| Rust FFI | Swift/C ABI lengths agree; null pointers, mismatched lengths, and non-finite floats are rejected; non-null pointers satisfy the documented C contract; panics do not cross C | The length-aware query uses a versioned symbol so a stale four-argument dylib cannot be called through the five-argument ABI. Header, Swift, Rust, strict Clippy, and six FFI tests agree. |
| Distribution | Debug contributor runtime may use checkout tools; Release distributed runtime is self-contained | Policy validator and macOS/iPadOS Release builds pass. |
| Release evidence | Exact clean source -> unsigned candidate -> signing -> notarization evidence -> post-staple verification | Scripts fail closed on mixed source, invalid identity, colliding evidence paths, missing approval, and mismatched artifacts. |

## Material findings resolved

1. DuckDB export paths containing apostrophes were interpolated into SQL. COPY
   destinations are now parameterized and covered by a regression.
2. Python output admitted NaN/Infinity and malformed optional fields. Boundary
   normalization and strict JSON serialization now reject non-finite output.
3. The C ABI read an HNSW query pointer before knowing its length. The versioned
   `atlas_query_index_v2` ABI now carries and validates `query_len`; a cached
   legacy dylib is rejected instead of invoked with an incompatible signature.
4. Paper/chunk ingestion and strategy-project create/update/delete could publish
   memory state before a failed save or silently leave exported notes. Canonical
   state now commits before publication, rollback/failure paths are explicit,
   and derived-note failures remain visible without discarding user drafts.
5. Per-paper and clustering tasks could publish stale results after selection,
   cancellation, or a newer run. Operation/run identities now guard every
   post-await publication.
6. The app could report an ingest skip solely from a preserved timestamp. It
   now validates content checksum, deduplicates paper identities, and recomputes
   source-kind counts after each run.
7. Markdown frontmatter years were ignored and the final section excluded its
   actual last line. Both parser defects have focused tests and native proof.
8. A successful ingest did not reliably produce the expected Obsidian vault
   assets. Ingestion now exports the atlas, setup note, CSS snippet, and paper
   note without overwriting user tails.
9. Analytics load failure was silent in the UI. The exact missing/invalid
   `analytics.json` error is now visible and accessible.
10. Single-paper analytics emitted scikit-learn and pandas warnings. Single-row
    factor handling and numeric cutoff comparison are now warning-free.
11. Claim similarity materialized a dense all-pairs matrix and crashed on an
    empty vocabulary. Bounded nearest-neighbor retrieval caps candidates per
    claim and handles empty text deterministically.
12. The lock selected a SciPy 1.15.3 wheel that failed to load on the audited
    macOS/Python host. Direct scientific-stack floors and a refreshed lock now
    produce NumPy 2.5.1, SciPy 1.18.0, and scikit-learn 1.9.0 from a frozen sync.
13. `hnsw_rs` was one patch behind. Version 0.3.4 passes the strict Rust gate;
    its transitive `bincode 1.3.3` is unmaintained but has no validated
    vulnerability and no app-exposed deserialization path.
14. Topic-focus and artifact audits could accept malformed/non-finite input or
    fail with an unhelpful traceback. They now fail closed with explicit errors.
15. SBOM identity did not bind file type/mode/link target and the generator used
    a stale default timestamp. Source and artifact namespaces now hash complete
    path state, and timestamps default to current UTC while retaining deterministic
    `SOURCE_DATE_EPOCH`; dependency SBOMs were regenerated from both current locks.
16. Example smoke output retained private fixtures by default. Cleanup is now
    automatic; retention requires explicit `--keep-workspace`.
17. Official builds could finish from mixed source after a mid-build edit.
    Revision is captured before compilation, rechecked after it, and mixed
    candidate/app/dSYM output is rejected.
18. Notarization response and log output could alias the same path. Collision is
    rejected before any submission.
19. Localized chart integers exposed publication year 2026 as `2.026` in Polish
    UI/accessibility. Year labels are verbatim and timeline/factor/idea-flow
    charts expose explicit ungrouped semantic summaries.
20. Accessibility activation of a sidebar row published navigation during a
    SwiftUI view update. Selection now commits on the next main run-loop turn.
21. Pointer hover callbacks and width-preference callbacks could synchronously
    mutate view state during layout. Both callbacks are deferred, and chart
    task cancellation bookkeeping no longer participates in view observation.
22. Python analytics retried a failed managed interpreter under global Python.
    An explicit override is now exclusive; otherwise only `analytics/.venv` is
    accepted, and its nonzero result is returned without replaying mutations.
23. Duplicate paper exports were selected before freshness and corpus-dimension
    resolution. Canonical/fresh selection and deterministic modal dimensions now
    precede normalization in both the app loader and analytics rebuild.
24. PR review found that the topic-focus audit still rejected a stale duplicate
    export even though the app and analytics rebuild already resolve duplicate
    paper IDs by freshness. The audit now applies the same deterministic rule,
    with a regression proving that the newest export wins.
25. PR review found that ingest skip validation hashed the full source document
    synchronously on `AppModel`'s main actor. Checksum I/O and SHA-256 work now run
    in a cancellable utility task, while only the resulting state publication
    returns to the main actor.

## Native scenario matrix

| Scenario | Expected | Result |
| --- | --- | --- |
| Fresh build and launch | Process starts from current source | Verified repeatedly with `./script/build_and_run.sh --verify`. |
| Six sidebar destinations | Ingest, Universe, Q&A, Insights, Projects, Analytics render | Verified by real native accessibility interaction. |
| Folder picker cancel | No mutation or error | Verified. |
| Markdown ingest | One success, outputs generated, year 2026 visible | Verified with isolated fixture. |
| Repeat ingest | Unchanged content skips exactly once by checksum | Verified. |
| Obsidian export | Atlas/setup/snippet/paper note exist | Verified on disk. |
| Project create/delete | Create persists; destructive delete asks for confirmation | Create and confirmation/cancel verified without irreversible delete. |
| Python rebuild | Canonical `analytics/.venv` used exclusively and UI reloads summary | Verified; rebuilt without warnings, and missing managed Python fails closed. |
| Missing analytics | Exact recovery error is visible | Verified after recoverably removing only the fixture summary. |
| Year accessibility | Year is read as 2026, not 2.026 | Verified for timeline, factor exposure, and idea flow. |
| Artifact health | Output audit has zero findings; singleton topic audit passes with fixture-appropriate thresholds | Verified. |
| Relaunch | Persisted fixture paper is restored | Verified. |

The Computer Use accessibility snapshot itself causes macOS 26 AppKit
`Invalid view geometry` diagnostics even on the static Universe screen before
any app navigation. A control run proved those diagnostics are injected by the
automation snapshot. The app-owned sidebar publication warning found during
that investigation was fixed and did not recur. Normal launch/process checks
show no app crash or app-owned error path.

A final automation-free relaunch remained alive and emitted no SwiftUI geometry,
application-code, or crash fault. macOS AppKit/App Intents did emit a host-service
registration diagnostic because `com.apple.linkd.autoShortcut` rejected its XPC
connection. `com.apple.linkd` itself was running; SIP prevented manually
kickstarting that Apple service. The signal is host-framework-owned, reproducible
without an app intent integration, and did not affect launch or interaction.

## Verification evidence

- Swift package: 68 XCTest cases passed, one explicitly opt-in corpus smoke
  skipped, and four Swift Testing bookmark tests passed with warnings as errors.
- Python: frozen lock sync/import passed; Ruff format/lint passed; 39 tests
  passed; installed-environment audit found no known vulnerability.
- Rust: formatting, strict Clippy, six tests, and release build passed.
- RustSec: no vulnerability; one allowed unmaintained transitive warning for
  `bincode 1.3.3` through `hnsw_rs`.
- Release policy: shell syntax, the complete release-script regression suite,
  and configuration validation passed with only `app_icon_artwork` explicitly
  allowed.
- Xcode: generated project is byte-stable; unsigned macOS and iPadOS Simulator
  Release builds passed in isolated DerivedData with no diagnostic output.
- Runtime: current bundle launched, isolated ingest/rebuild/audits passed, and
  the final accessibility interaction exposed correct year semantics with no
  app-owned publication fault.

## Residual external blockers

- Approved production app icon artwork and brand/copyright chain of title.
- Developer ID private-key authorization, signing, notarization upload,
  stapling, quarantine/Gatekeeper validation, and exact signed-artifact SBOM.
- Owner-controlled GitHub branch protection, dependency graph/security
  settings, private reporting, governance, and public release/tag decisions.
- Third-party PDF history and other previously documented legal/history risks.

## Final readiness label

- **repo-ready** after the reviewed PR and hosted checks pass.
- **runtime-proven** for the local contributor app and isolated end-to-end flow.
- **blocked:external** for Developer ID/notarized/App Store/public release.
