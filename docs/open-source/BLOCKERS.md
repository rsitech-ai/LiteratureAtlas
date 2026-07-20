# Release and publication blockers

## Current direct-download release

1. Merge the Apache/RSI Tech migration through an exact-head green org PR.
2. Build the exact merged source through the credential-free unsigned-candidate
   workflow, then verify its embedded source revision and transport checksum.
3. Sign it with Developer ID Application Team
   `2NY8A789TN`, and complete digest-bound Apple notarization.
4. Retain signature, entitlement, hardened-runtime, notarization, staple,
   Gatekeeper, DMG equality, checksum, SBOM, relocation, and launch/log evidence.
5. Publish and remotely verify the org release assets before retiring the old
   personal prerelease and making the personal repository private/archived.

## Separate App Store lane

iPad App Store publication remains outside this direct-download release. It
requires registered bundle IDs, matching distribution identity/profiles,
App Store Connect metadata, physical-device acceptance, and explicit upload
authority. Direct-download proof does not clear those gates.

The formal Codex Security scan is intentionally not part of this task; existing
repository-native checks are scoped evidence, not an exhaustive substitute.
