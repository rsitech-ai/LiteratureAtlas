# Security policy

No supported public release exists yet. The default branch is pre-release source
and an official notarized download has not been published.

## Reporting

Do not disclose vulnerabilities, private documents, credentials, document
paths, signing material, or exploit details in a public issue or pull request.
GitHub private vulnerability reporting is currently disabled and no alternative
monitored private channel has been approved. Safe private reporting is therefore
a release blocker; retain the details until the repository owner enables and
publishes a real route.

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
