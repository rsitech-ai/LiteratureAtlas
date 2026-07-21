# Release and publication blockers

## Current direct-download release

No current blocker. PR #4 merged through protected `main`; exact source
`88f7d5e7c373226eb3861277ba9ca6a57f5e8774` produced the Developer ID-signed,
Apple-notarized `v1.0.0` release. Signature, entitlements, hardened runtime,
notarization, staple, Gatekeeper, DMG equality, checksum, SBOM, quarantine,
relocated launch/log, and public remote-byte evidence all passed. The legacy
personal prerelease was then removed and its repository made private/archived.

## Separate App Store lane

iPad App Store publication remains outside this direct-download release. It
requires registered bundle IDs, matching distribution identity/profiles,
App Store Connect metadata, physical-device acceptance, and explicit upload
authority. Direct-download proof does not clear those gates.

The formal Codex Security scan is intentionally not part of this task; existing
repository-native checks are scoped evidence, not an exhaustive substitute.
