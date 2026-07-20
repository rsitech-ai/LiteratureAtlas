# Release and publication blockers

## Legal and ownership

1. Confirm exact copyright holder and contributor/employer/contractor/AI
   provenance; authorize or reject future MPL-2.0/CC-BY-4.0 licensing.
2. Resolve four third-party PDF blobs in reachable public history through a new
   clean-history repository or an explicitly approved coordinated rewrite.
3. Classify release screenshots and provide approved production AppIcon artwork.
4. Confirm trademark owner, protected marks, and permission route.

## Governance and safety

5. Appoint maintainers, release manager, security responder, and conduct
   responder; approve decision/appeal rules.
6. Choose DCO 1.1 versus a lawyer-reviewed CLA and enable its enforcement.
7. Enable a monitored private conduct route. GitHub private vulnerability
   reporting is enabled for security reports.
Default-branch protection, strict required checks, conversation resolution,
dependency alerts/security updates, private vulnerability reporting, and
full-length Action SHA enforcement are enabled. Restricted Action allowlisting
and public Scorecard publication remain optional owner decisions, not evidence
for the official release gates below.

## Apple release

8. Confirm official bundle ID, Developer ID identity, release owner, and support
   metadata.
9. Approve exact source commit `647911a` (or rebuild from the approved successor)
    and authorize its Developer ID private key in the keychain. The local
    signature-free pre-sign candidate is verified; no signing was attempted in
    this audit pass.
10. Explicitly approve the exact notarization upload, then retain submission/log,
    staple, Gatekeeper, quarantine, and supported-hardware evidence.
11. Generate and reconcile the exact future signed/stapled-artifact SBOM,
    notices, hashes, signature/notary evidence, and source-release mapping.

No notarization upload, official production tag/release, visibility mutation,
history rewrite, or official announcement has been performed. Community tag
`v1.0.0-community.1` and its ad-hoc/not-notarized GitHub prerelease were
published under explicit authorization and do not clear any blocker above.
