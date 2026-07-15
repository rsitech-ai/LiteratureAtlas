# Community-build evidence

The canonical policy and commands are in
[docs/community-build/README.md](../community-build/README.md).

Local verification produced an Apple Silicon, ad-hoc signed,
`org.literatureatlas.community` application with sandbox entitlement and no
checkout-only runtime markers. A relocated copy launched from `/private/tmp` and
quit cleanly. A DMG was created, verified with `hdiutil`, and accompanied by a
matching SHA-256 file.

These ignored local artifacts are build evidence, not an official download, and
were not uploaded or published.
