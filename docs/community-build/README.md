# Community macOS build

Community packaging is credential-free, Apple Silicon-only, and intended for
macOS 26 or later. It produces an ad-hoc signed app, not an Apple-notarized or
official project release.

Choose a distinct name and a bundle namespace you control:

```bash
script/build_community.sh \
  --product-name LiteratureAtlasCommunity \
  --bundle-id org.example.LiteratureAtlasCommunity \
  --version 1.0.0 \
  --build 1 \
  --output dist/community

script/verify_distribution.sh \
  --app dist/community/LiteratureAtlasCommunity.app \
  --mode community

script/create_dmg.sh \
  --app dist/community/LiteratureAtlasCommunity.app \
  --output dist/community/LiteratureAtlasCommunity-1.0.0.dmg
```

The DMG script also creates a `.sha256` file and verifies the disk image.
Relocate the app outside the checkout and perform a clean launch before sharing
it. Gatekeeper may warn about an ad-hoc signed build because no Apple
notarization ticket exists.

Community distributors must replace official-looking branding and release
metadata, disclose modifications, and provide their own support. They may not
reuse official checksums or imply endorsement. See [BRANDING.md](../../BRANDING.md).
