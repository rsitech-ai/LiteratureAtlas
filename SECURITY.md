# Security policy

The default branch is the current development line. Supported release versions
and their Apple trust state are stated explicitly on the GitHub Releases page;
do not infer support or notarization from a tag alone.

## Reporting

Do not disclose vulnerabilities, private documents, credentials, document
paths, signing material, or exploit details in a public issue or pull request.
Use [GitHub private vulnerability reporting](https://github.com/rsitech-ai/LiteratureAtlas/security/advisories/new)
or email `info@rsitech.ai` for confidential security reports. Do not open a
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
