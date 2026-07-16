# Open-source status

**Publication verdict: BLOCKED.** The source repository is already public under
MIT, but it is not ready for an official source release or notarized binary.

## Verified locally

- Current project-authored source remains under the existing MIT License.
- Distributed macOS builds are native, sandboxed, local-only, and exclude
  checkout-only Python, environment-key, remote-provider, and relative-Rust paths.
- A distinct ad-hoc signed community app and exact verified DMG build without
  Apple credentials. The relocated app passed all six navigation destinations,
  a real sandboxed Markdown ingest, truthful counters/output checks, and relaunch
  persistence from source commit `647911a`.
- Developer ID, DMG, explicit notarization, retained Apple evidence, stapling,
  Gatekeeper, and artifact-verification scripts fail closed.
- A fresh Apple Silicon official pre-sign candidate from `647911a` is provably
  signature-free, contains 35 prompt resources, embeds its source revision,
  retains its dSYM, and has no checkout-only runtime markers.
- Current-tree and reachable-history scans found no credential material.
- Swift, Python, Rust, release-script, and Xcode Release gates pass except the
  intentional approved-AppIcon release blocker. Release compilation treats
  Swift warnings as errors.
- Codex Security was explicitly deferred and was not run; the code-level audit
  found no unresolved critical/high implementation issue.

## Why publication remains blocked

- Four third-party PDF blobs remain reachable in public Git history; at least one
  has non-commercial/no-derivatives terms and another has no verified
  redistribution grant.
- Contributor/employer/contractor/AI provenance and exact rights-holder authority
  are not established, so MPL relicensing is not authorized.
- No approved production icon, trademark owner, official bundle identifier,
  governance roster, DCO/CLA choice, or private security/conduct route exists.
- The installed Developer ID private key requires owner keychain authorization;
  no official signed artifact exists.
- No notarization upload, quarantined-download proof, physical macOS 26 acceptance,
  public tag, or GitHub Release has been authorized or performed.

See [the gate matrix](PUBLICATION_GATE_MATRIX.md) and [blockers](BLOCKERS.md).
