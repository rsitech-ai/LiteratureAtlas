# Open-source status

**Publication verdict: BLOCKED.** The source repository is already public under
MIT, but it is not ready for an official source release or notarized binary. A
separately labeled ad-hoc/not-notarized community prerelease was explicitly
authorized and published on 2026-07-18; it does not clear the official gates.

## Verified current repository state

- Current project-authored source remains under the existing MIT License.
- Distributed macOS builds are native, sandboxed, local-only, and exclude
  checkout-only Python, environment-key, remote-provider, and relative-Rust paths.
- Developer ID, DMG, explicit notarization, retained Apple evidence, stapling,
  Gatekeeper, and artifact-verification scripts fail closed.
- Manual redacted current-tree and reachable-history scans found no credential material; the formal Codex Security scan was excluded for the current delta.
- Swift, Python, Rust, release-script, macOS/iPadOS Release archive, REUSE,
  dependency-audit, source-SBOM, and launch gates pass except the intentional
  approved-AppIcon release blocker. Release compilation treats Swift warnings
  as errors. The supported direct-download lane is Apple Silicon.
- The prior release-hardening diff received a complete Codex Security scan. A
  scheduled scan later opened three deceptive-host CodeQL alerts on current
  `main`; the candidate fixes them and requires exact-head hosted revalidation.
  The dependency-review action was skipped because GitHub's dependency graph
  was disabled at the time, so the historical green workflow alone is not
  evidence that review ran. Dependency alerts/security updates and private
  vulnerability reporting are now enabled; the candidate still requires a
  fresh pull-request run and exact-head closure.

## Historical artifact evidence

- A distinct ad-hoc signed community app and exact verified DMG from source
  commit `647911a` passed all six navigation destinations, a real sandboxed
  Markdown ingest, truthful counters/output checks, and relaunch persistence.
- An Apple Silicon official pre-sign candidate from `647911a` was signature-free,
  contained 35 prompt resources, embedded its source revision, retained its dSYM,
  and had no checkout-only runtime markers.
- Those exact local app directories are no longer retained and were not
  regenerated from the current tree. They are historical snapshots, not current
  package-readiness, signing, notarization, or release evidence.

## Why publication remains blocked

- Four third-party PDF blobs remain reachable in public Git history; at least one
  has non-commercial/no-derivatives terms and another has no verified
  redistribution grant.
- Contributor/employer/contractor/AI provenance and exact rights-holder authority
  are not established, so MPL relicensing is not authorized.
- No approved production icon, trademark owner, official bundle identifier,
  governance roster, DCO/CLA choice, or private conduct-reporting route exists.
- The installed Developer ID private key requires owner keychain authorization;
  no official signed artifact exists.
- No notarization upload, quarantined official-download proof, or physical
  macOS 26 acceptance has been performed. Community tag
  `v1.0.0-community.1` and its GitHub prerelease are explicit non-official
  exceptions, not evidence for Developer ID/notarized publication.

See [the gate matrix](PUBLICATION_GATE_MATRIX.md) and [blockers](BLOCKERS.md).
