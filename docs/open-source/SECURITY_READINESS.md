# Security readiness

No credential leak was validated in the current tracked tree or reachable
history. A prior release-hardening diff received a complete Codex Security scan;
the current release-readiness delta explicitly did not. Manual redacted history
inspection found no credential, while scheduled CodeQL identified three
high-severity deceptive-host alerts in analytics URL classification. The code
and regressions were repaired; PR #11 passed exact-head Swift/Python CodeQL and
reported zero open alerts on the reviewed branch. Dependency review also
executed successfully after the dependency graph was enabled. Dependency
alerts, automated security fixes, private vulnerability reporting, full-length
Action SHA enforcement, strict required checks, and default-branch protection
are enabled. The distributed runtime boundary, persistent security-scoped source
bookmarks, sandbox, private logging, raw-question minimization, release-script
separation, locked developer environments, and exact artifact checks are
positive controls.

Release security remains blocked until the incomplete signed-artifact
SBOM/provenance evidence, absent production icon provenance, unperformed
Developer ID/notary/quarantine proof, and historical IP-bearing objects.

See [the technical boundary](../security/README.md) and
[SECURITY.md](../../SECURITY.md).
