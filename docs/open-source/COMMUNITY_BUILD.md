# Community-build evidence

The canonical policy and commands are in
[docs/community-build/README.md](../community-build/README.md).

Current verification produced an Apple Silicon, ad-hoc signed,
`io.github.s1korrrr.LiteratureAtlasCommunity` application from merge commit
`95d0031a0ee67a9f91cd0d915de75e1f42137daa`, with sandbox entitlement and no
checkout-only runtime markers. A copy extracted from the DMG launched from a
relocated `/private/tmp` path and quit cleanly. The DMG was mounted, compared
exactly with the verified app, validated with `hdiutil`, and accompanied by a
matching SHA-256 file and exact-app SPDX SBOM.

The artifact is published as the clearly labeled, non-notarized prerelease
[`v1.0.0-community.1`](https://github.com/s1korrrr/LiteratureAtlas/releases/tag/v1.0.0-community.1).
It is a community download, not an official Developer ID-signed, notarized, or
App Store release.
