# SBOM evidence

These inventories describe source/contributor dependencies and the verified
community app. They are not an attestation for a future official signed app.

| File | Scope | Generator | Records |
|---|---|---|---|
| `source.spdx.json` | Repository excluding Git, build/cache, virtualenv, dist, and this SBOM directory | Syft 1.46.0, SPDX JSON | 141 package records |
| `community-app.spdx.json` | `LiteratureAtlasCommunity.app` | Syft 1.46.0, SPDX JSON | 1 app package record |
| `official-unsigned-app.spdx.json` | Signature-free official pre-sign candidate | Syft 1.46.0, SPDX JSON | 1 app package record |
| `python-environment.cdx.json` | Locked analytics Python 3.12 environment | cyclonedx-bom 7.2.1, CycloneDX 1.6 | 18 components; 0 missing licenses |
| `rust-source.cdx.json` | Rust FFI for `aarch64-apple-darwin` | cargo-cyclonedx 0.5.9, CycloneDX 1.5 | 72 components including project root; 0 missing licenses |

Generator binaries/packages were version-pinned. The downloaded Syft Darwin
ARM64 archive was checked against the upstream v1.46.0 checksum list. Recreate
the source SBOM after the final commit and create a new artifact SBOM from the
exact Developer ID-signed app before publication.

Current SHA-256 values:

```text
1cd1473e3c5e01ee38ae8f369fcf42a01f32ee76e8b12754e89f29d3f26820cb  community-app.spdx.json
bf9ded95d6ff86793a7ea259f86c0fe4e0a24aaeff4f4941ddef6825666a0ea7  official-unsigned-app.spdx.json
4376c231aabcf7968ce054b7c9b3eb4a0cc08f6335e41d3b5622c03477e06e86  python-environment.cdx.json
4e09ee4b02b6fa0a97515b640aac08540f20f48c52959faf7b161bdb1a20010a  rust-source.cdx.json
765d33f7e0505e7cb54aec1a9ff40dcb5db7570893467c71b98bbdee3c684ec7  source.spdx.json
```
