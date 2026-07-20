# Security policy

No supported official release exists yet. The default branch is pre-release
source and an official notarized download has not been published. The existing
community prerelease is ad-hoc signed, not notarized, and unsupported.

## Reporting

Do not disclose vulnerabilities, private documents, credentials, document
paths, signing material, or exploit details in a public issue or pull request.
Use [GitHub private vulnerability reporting](https://github.com/s1korrrr/LiteratureAtlas/security/advisories/new)
for security reports. This route is enabled for the repository; do not open a
public issue for a suspected vulnerability.

No bug bounty, response-time promise, or embargo SLA is offered.

## Security boundary

Distributed app builds are sandboxed and local-only. Repository Python
execution, environment API keys, the dormant remote provider, and
repository-relative Rust loading are compiled out. Users explicitly select
read-only source folders; mutable output remains in Application Support.

Release checks cover locked dependencies, secret patterns, distributed-binary
strings, entitlements, Developer ID signatures, DMG integrity, notarization, and
Gatekeeper. Technical details are in
[docs/security/README.md](docs/security/README.md).
