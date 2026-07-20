# Security readiness

The Apache/organization migration intentionally excludes a formal Codex
Security scan at maintainer direction. That exclusion is recorded rather than
being presented as completed evidence. The protected pull request still runs
the repository's automated Swift/Python CodeQL, dependency review, lockfile
audit, REUSE, build, and test checks. Dependency alerts, automated security
fixes, private vulnerability reporting, full-length Action SHA enforcement,
strict required checks, and default-branch protection are enabled. The
distributed runtime boundary, persistent security-scoped source bookmarks,
sandbox, private logging, raw-question minimization, release-script separation,
locked developer environments, and exact artifact checks remain positive
controls.

Release publication remains blocked only until the exact merged-source app has
been built, Developer ID signed, notarized, stapled, quarantine tested, given an
artifact-specific SPDX SBOM, and remotely verified. Production icon provenance
and canonical-history sanitization are complete.

See [the technical boundary](../security/README.md) and
[SECURITY.md](../../SECURITY.md).
