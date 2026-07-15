# Contributing

LiteratureAtlas welcomes focused, reviewable changes. The current direct-build
scope is Apple Silicon on macOS 26 or later.

## Before opening a pull request

- Branch from the current default branch and keep unrelated changes separate.
- Do not commit research documents, generated `Output/`, credentials, signing
  material, notarization records, or private logs.
- Add behavior tests for behavior changes and keep errors explicit.
- Preserve the distributed-build boundary: no repository Python execution,
  environment API keys, remote provider, or repository-relative dynamic library.
- Never put vulnerabilities or private documents in a public issue or pull
  request.

Run the complete command matrix in [docs/build/README.md](docs/build/README.md).
If `project.yml` changes, regenerate the Xcode project and prove it is
deterministic.

## Optional analytics and Rust tooling

The Python analytics environment and Rust FFI crate are contributor tools. They
are not included in the first distributed app. Use the locked environments and
follow [analytics/README.md](analytics/README.md).

## Contribution certification

DCO versus a lawyer-reviewed CLA has not been selected. Do not represent commit
sign-off as an enforced acceptance policy until the owner chooses a mechanism
and CI enforces it.

Release signing, notarization, tags, and official publication remain
maintainer-only operations requiring explicit approval.
