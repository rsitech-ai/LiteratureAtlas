# Open-source status

**Direct-download verdict: released.** The canonical repository is public at
`rsitech-ai/LiteratureAtlas`, uses Apache-2.0 for project-authored work, and is
maintained by RSI Tech. Rafal Sikora is the confirmed copyright owner and
release authority. Existing historical MIT grants remain valid.

## Verified current state

- The clean org baseline has no PDF path, none of the four audited PDF blobs,
  and no legacy personal email. GitHub authored PR #4's merge commit with the
  account merge identity rather than the repository-configured no-reply email;
  the reviewed project commit uses the requested no-reply identity.
- Public and confidential project contact is `info@rsitech.ai`; GitHub private
  vulnerability reporting is enabled.
- DCO 1.1, CODEOWNERS, maintainer, governance, conduct, branding, support, and
  security routes are defined.
- Production AppIcon artwork is committed for every declared macOS, iPhone,
  iPad, and marketing rendition; the fail-closed release validator passes
  without an artwork exception.
- Distributed macOS builds are native, sandboxed, local-only, and exclude
  checkout-only Python, environment-key, remote-provider, and relative-Rust
  execution paths.
- A valid `Developer ID Application: Rafal Sikora (2NY8A789TN)` identity and a
  usable external notary profile are available locally. Neither credential is
  stored in the repository.
- Migration PR #4 passed all required checks and merged through protected
  `main`; exact merged source `88f7d5e7c373226eb3861277ba9ca6a57f5e8774`
  produced the official Developer ID-signed and Apple-notarized artifact.
- [`v1.0.0`](https://github.com/rsitech-ai/LiteratureAtlas/releases/tag/v1.0.0)
  is public with DMG, checksum, and application SPDX SBOM assets that were
  downloaded and verified byte-for-byte. The superseded personal prerelease is
  removed and its repository is private/archived recovery evidence.
- The formal Codex Security scan is excluded from this migration by explicit
  direction. Repository-native CodeQL, dependency review, locked dependency
  audits, license checks, and secret-pattern checks remain scoped gates.

## Remaining external lane

The macOS direct-download lane is complete. iPad App Store publication remains
separate and requires its own identifiers, distribution identity/profiles, App
Store Connect metadata, physical-device acceptance, and explicit upload
authority. No App Store readiness is implied by the macOS release.

See [the gate matrix](PUBLICATION_GATE_MATRIX.md) and
[blockers](BLOCKERS.md).
