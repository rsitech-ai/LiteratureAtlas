# Open-source status

**Source verdict: release candidate.** The canonical repository is public at
`rsitech-ai/LiteratureAtlas`, uses Apache-2.0 for project-authored work, and is
maintained by RSI Tech. Rafal Sikora is the confirmed copyright owner and
release authority. Existing historical MIT grants remain valid.

## Verified current state

- The clean org repository publishes only rewritten `main`; a fresh clone has
  no PDF path, none of the four audited PDF blobs, and no legacy personal email.
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
- The formal Codex Security scan is excluded from this migration by explicit
  direction. Repository-native CodeQL, dependency review, locked dependency
  audits, license checks, and secret-pattern checks remain scoped gates.

## Remaining release work

The current PR must pass the complete local and hosted matrix and merge. The
exact merged source must then be built by the credential-free unsigned-candidate
workflow, downloaded with its source/digest evidence, Developer
ID signed, notarized, stapled, Gatekeeper-checked, packaged, SBOM-attested, and
published with remotely verified bytes. Until those steps finish, the source is
repo-ready but no RSI Tech binary release is claimed.

See [the gate matrix](PUBLICATION_GATE_MATRIX.md) and
[blockers](BLOCKERS.md).
