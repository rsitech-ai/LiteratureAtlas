# SBOM evidence

These inventories cover the current source ecosystems and exact local app
evidence built from commit `647911aa3093a9df56f48a048a002e5db458794a`.
They are not an attestation for a future Developer ID-signed artifact.

| File | Scope | Generator | Records |
|---|---|---|---|
| `source.spdx.json` | Tracked/unignored repository source excluding Git, generated outputs, and this SBOM directory | `scripts/generate_spdx_sbom.py`, SPDX 2.3 JSON | 1 package, 245 regular files |
| `community-app.spdx.json` | Exact ad-hoc signed `LiteratureAtlasCommunity.app` built from `647911a` | `scripts/generate_spdx_sbom.py`, SPDX 2.3 JSON | 1 package, 40 regular files |
| `official-unsigned-app.spdx.json` | Exact signature-free official pre-sign app built from `647911a` | `scripts/generate_spdx_sbom.py`, SPDX 2.3 JSON | 1 package, 39 regular files |
| `python-environment.cdx.json` | Locked analytics Python 3.12 environment | cyclonedx-bom 7.2.1, CycloneDX 1.6 | 18 components; 0 missing licenses |
| `rust-source.cdx.json` | Rust FFI for `aarch64-apple-darwin` | cargo-cyclonedx 0.5.9, CycloneDX 1.5 | 72 components including the project root; 0 missing licenses |

The repository generator hashes every regular file with SHA-256, records one
package-to-file `CONTAINS` relationship per file, excludes its own output from
the source inventory, converts numeric `SOURCE_DATE_EPOCH` to an SPDX timestamp,
and writes atomically. The Rust CycloneDX file is sanitized so no developer
workspace path is published.

Recreate the artifact inventories from exact app directories:

```bash
SOURCE_COMMIT=647911aa3093a9df56f48a048a002e5db458794a
SOURCE_DATE_EPOCH="$(git show -s --format=%ct "$SOURCE_COMMIT")" \
  scripts/generate_spdx_sbom.py \
  --app /path/to/LiteratureAtlasCommunity.app \
  --version 1.0.0+647911a \
  --output docs/open-source/sbom/community-app.spdx.json

SOURCE_DATE_EPOCH="$(git show -s --format=%ct "$SOURCE_COMMIT")" \
  scripts/generate_spdx_sbom.py \
  --app /path/to/LiteratureAtlas.app \
  --version 1.0.0+647911a-unsigned \
  --output docs/open-source/sbom/official-unsigned-app.spdx.json

scripts/generate_spdx_sbom.py \
  --source-root . \
  --output docs/open-source/sbom/source.spdx.json
```

An official release must generate a new SBOM from the exact Developer ID-signed
candidate and reconcile its hashes, source commit, signature/notary evidence,
notices, and provenance attestation after stapling.

Current SHA-256 values:

```text
1c8dc2d061b7b7dfe58695a4bff38df8fa89548eada54d0d60c86a4a43105c68  community-app.spdx.json
65657374f17e19d5f82fc69567396e062d0a4ee8361bf5bf010ae91a0c1e0132  official-unsigned-app.spdx.json
2d0be934d8c1666f28515b0f4ddd522a6cd9ee7eab6aa204955f0c1f89101629  source.spdx.json
4376c231aabcf7968ce054b7c9b3eb4a0cc08f6335e41d3b5622c03477e06e86  python-environment.cdx.json
204900d5f3865ef0c8065479e31d378770422f425e7fee68ba74faf7e0448906  rust-source.cdx.json
```
