# Direct-distribution and open-source audit — 2026-07-16

## Verdict

- Repository implementation: **repo-ready**, pending PR/CI/merge verification.
- Community artifact from `647911aa3093a9df56f48a048a002e5db458794a`:
  **package-ready local evidence**.
- Official Developer ID/notarized artifact: **blocked:external**.
- Open-source publication: **blocked** by legal/history, artwork/brand,
  governance/reporting, and Apple owner gates.
- Codex Security: explicitly deferred by the owner; not run or claimed.
- Independent review: no blocker, high, or important finding in
  `origin/main...6633779`.

## Scope and standards

The pass covered the SwiftUI application, persistence and ingestion flow,
Python analytics, Rust FFI, release/signing/notary scripts, Xcode configuration,
GitHub Actions, licensing/governance documentation, SBOMs, repository settings,
fresh-build behavior, app runtime, DMG contents, and exact source mapping.

Release assumptions were checked against Apple's hardened-runtime,
security-scoped bookmark, sandbox file-access, privacy-manifest, Developer ID,
and notarization documentation. Workflow assumptions were checked against
GitHub's Actions runner, Dependabot ecosystem/options, and security-update
documentation.

## Material findings resolved

1. The sandbox could ingest a selected folder only during the original session;
   source-document actions had no durable app-scoped bookmark. A persistent,
   read-only bookmark store, entitlement, stale refresh, scope balancing, user
   error surfaces, and tests were added.
2. Real folder-picker testing found bookmark creation happened outside the
   selected URL's temporary security scope. Bookmark creation now activates and
   balances that scope.
3. A second real ingest found the original picker URL could not enumerate after
   bookmark creation. Async ingestion now resolves the persistent bookmark and
   holds its scope for the complete task; a suspension/lifetime test covers it.
4. The community build ignored display-name/source-revision overrides because
   explicit plist/xcconfig values had higher precedence. The plist now derives
   its display name from `PRODUCT_NAME`; a generated effective xcconfig binds
   product, bundle ID, version, build, and exact commit.
5. The generated xcconfig initially admitted newline/control-character
   injection through line-oriented validation. Release inputs now reject control
   characters, ambiguous trailing whitespace, malformed bundle IDs, versions,
   and build numbers.
6. Distribution verification previously trusted the supplied app while only
   structurally checking a DMG. It now mounts the DMG and compares every entry's
   type, mode, size, link target, and SHA-256 before verifying its embedded app.
7. Official verification now binds Developer ID authority, secure timestamp,
   Team ID, bundle ID, version/build, architecture, minimum macOS, entitlements,
   and embedded source revision. Notary submission binds an owner-approved DMG
   hash and retains atomic response/log evidence.
8. Release builds now retain dSYMs, reject dirty official source, recover safely
   from signer interruption, use the hardened runtime, and fail on Swift
   warnings. Xcode `-quiet` keeps the transcript warning/error focused.
9. Placeholder/zero-hash artifact SBOMs and a private Rust workspace path were
   replaced by deterministic real-file SHA-256 inventories and sanitized
   CycloneDX evidence. Numeric `SOURCE_DATE_EPOCH` is converted correctly.
10. Analytics ingestion now deduplicates canonical paper IDs, validates finite
    and dimensionally consistent embeddings, and reports malformed event lines.
    Swift fallback embeddings are stable across launches.
11. Rust FFI build/query boundaries reject overflow and non-finite values before
    the C ABI and now have HNSW round-trip coverage. Zero/nonpositive weighted
    graph edges are rejected.
12. Ingestion and persistence no longer silently convert failures into success;
    counters, partial export warnings, note-save errors, and clustering cancel
    state are explicit.

## Runtime evidence

The relocated community app in `/private/tmp` was ad-hoc signed with hardened
runtime and sandbox/bookmark entitlements. A real HID click sweep opened Ingest,
Universe, Q&A, Insights, Projects, and Analytics. The system folder picker then
selected an isolated Markdown fixture. The app reported:

```text
1 succeeded · 0 skipped · 0 failed
Documents: 1
Progress: 100%
```

It wrote paper, document, chunk, index, and Markdown export artifacts under its
container. After quitting and relaunching, Universe restored `PAPERS 1`. The
focused unified-log query contained no error/fault records. The bookmark sidecar
is stored outside exported paper JSON.

## Artifact evidence

- Community app source revision: `647911aa3093a9df56f48a048a002e5db458794a`
- Community DMG SHA-256:
  `9abd68e553405fd98c4adc47fb77691dc84d70db2fd8f05f5a3ffd5590c0e6c9`
- Community app and mounted DMG app: exact manifest match
- Community dSYM: retained
- Official pre-sign bundle: `com.literatureatlas.app`, version `1.0.0` (build 1)
- Official pre-sign architecture: `arm64`
- Official pre-sign source revision: `647911aa3093a9df56f48a048a002e5db458794a`
- Official pre-sign signature state: `code object is not signed at all`
- Official pre-sign prompts: 35
- Official pre-sign dSYM: retained
- Checkout-only executable markers: absent

## Test evidence

- Swift: 59 XCTest cases passed, one explicit corpus-input smoke skipped; four
  Swift Testing bookmark cases passed; warnings treated as errors.
- Python: 24 tests passed; Ruff format/lint passed.
- Rust FFI: five tests passed; `cargo fmt` and strict Clippy passed.
- Release scripts: negative/positive policy, signature, DMG, notary-evidence,
  provenance, dSYM, workflow-trigger, and input-boundary cases passed.
- Xcode: macOS and iOS Release builds passed; the distribution build transcript
  was warning/error clean with Swift warnings-as-errors enabled.
- Fresh clone: commit `a8f2f2a` restored the locked Python environment and
  repeated the complete Swift/Python/Rust/release-policy suite plus macOS and
  iOS Release builds. Both redirected Xcode diagnostic transcripts were empty.
- Release validator: every gate passed except the explicitly named
  `app_icon_artwork` owner blocker.
- Hygiene: actionlint and offline pedantic zizmor reported no workflow finding;
  REUSE 3.3 and CFF validation passed; Python/Rust advisory checks found no
  vulnerability; exact-tree/history signature matching and GitHub secret
  scanning found zero credential alert.
- Hosted PR: GitHub's dependency-review action reported that the repository
  dependency graph is disabled. The workflow now requires a successful
  repository API preflight, warns and skips only for an unavailable graph on
  that accessible repository, fails closed on permission/access/unexpected
  statuses, and still fails on findings whenever the graph is enabled;
  Cargo/Python lockfile audits remain mandatory.
- Hosted CI also caught two runner-only assumptions before merge: Python
  3.12.13 is absent from the `macos-26` arm64 toolcache, and XcodeGen 2.45.4's
  archive has a nested `xcodegen/bin` root. The workflow now pins available
  Python 3.12.10 and the checksum-verified extracted binary path; local policy
  tests and official manifest/archive inspection cover both corrections.

## Residual and external blockers

- Four third-party PDF blobs remain reachable in public history. Rewriting
  history is destructive and was not authorized.
- Copyright/trademark authority, production icon provenance, DCO/CLA choice,
  governance roster, and private conduct/security routes remain unconfirmed.
- GitHub main is unprotected; Dependabot security updates, private vulnerability
  reporting, and immutable releases are disabled.
- `bincode 1.3.3` is an unmaintained transitive Rust contributor dependency; no
  validated vulnerability was found, and Rust acceleration is compiled out of
  the distributed app.
- Developer ID key authorization, signing, notarization upload, stapling,
  Gatekeeper/quarantine acceptance, exact signed-artifact SBOM/provenance, tag,
  and public release remain owner-controlled external actions.

## PR and merge closeout

- PR: <https://github.com/s1korrrr/LiteratureAtlas/pull/4>
- Reviewed head: `d6f231346cbae8ca92e1fb448bf7142369dd0938`
- Merge commit: `c335fbdae87b940c39483fa47761a6d57cf0593d`
- Hosted result: all nine checks passed, including Apple/Swift distributed
  bundle, Python, Rust, release policy, REUSE, dependency review, and
  Python/Swift CodeQL.
- Review result: the only inline concern was resolved with effective Xcode
  build-setting evidence; all review threads were resolved and the PR reported
  a clean merge state before merge.
- Exact-main result: the merge tree matched the reviewed PR tree. The local
  `main` checkout matched `origin/main` and repeated Swift, Python, Rust,
  release-policy, release-validator, and deterministic source-SBOM checks.
- Cleanup result: superseded release branches, obsolete worktrees, and old
  temporary release/fresh-clone directories were removed after ancestry and
  clean-state proof. The exact `647911a` artifact evidence bundle was retained.
