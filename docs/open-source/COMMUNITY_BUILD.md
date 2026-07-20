# Community-build evidence

The canonical policy and commands are in
[docs/community-build/README.md](../community-build/README.md).

The RSI Tech community identity is
`ai.rsitech.LiteratureAtlasCommunity`. Community builds remain credential-free,
Apple Silicon, sandboxed, hardened-runtime, ad-hoc signed, and explicitly not
notarized. The complete verification path mounts the DMG, compares its app
byte-for-byte with the verified source app, checks the portable checksum, and
launches a relocated copy.

The superseded personal-repository prerelease is retained only until the new
Developer ID-signed/notarized org release is remotely verified. It is not
current org release evidence.
