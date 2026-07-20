# SBOM evidence

The source inventory was refreshed from the release-readiness candidate on
2026-07-20; dependency inventories were refreshed from the frozen environments
on 2026-07-17. They describe repository
and dependency state, not a signed release artifact. The two app inventories are
exact historical local evidence built from commit
`647911aa3093a9df56f48a048a002e5db458794a`; they are not an attestation for a
future Developer ID-signed artifact. The exact app directories used for those
two inventories are no longer retained, so the commands below are rebuild
recipes rather than evidence that the historical artifacts can be regenerated
from the current worktree.

The published
[`v1.0.0-community.1`](https://github.com/s1korrrr/LiteratureAtlas/releases/tag/v1.0.0-community.1)
assets include a separate exact 40-file app inventory generated from merge
commit `95d0031a0ee67a9f91cd0d915de75e1f42137daa`. Its SHA-256 is
`78dbf5c0fbb07095d86a8a9d410a1eaf1b6240222d7b795397af9c3dda3048a9`.
That release asset is the current community-app evidence; the tracked app
inventories below remain historical snapshots and are intentionally preserved.

| File | Scope | Generator | Records |
|---|---|---|---|
| `source.spdx.json` | Current audited follow-up source snapshot; tracked/unignored source excluding Git, generated outputs, and this SBOM directory | `scripts/generate_spdx_sbom.py`, SPDX 2.3 JSON | 1 package, 250 regular files |
| `community-app.spdx.json` | Exact ad-hoc signed `LiteratureAtlasCommunity.app` built from `647911a` | `scripts/generate_spdx_sbom.py`, SPDX 2.3 JSON | 1 package, 40 regular files |
| `official-unsigned-app.spdx.json` | Exact signature-free official pre-sign app built from `647911a` | `scripts/generate_spdx_sbom.py`, SPDX 2.3 JSON | 1 package, 39 regular files |
| `python-environment.cdx.json` | Locked analytics Python 3.12 environment | cyclonedx-bom 7.2.1, CycloneDX 1.6 | 46 dependency components plus the project root; 0 missing licenses |
| `rust-source.cdx.json` | Rust FFI for `aarch64-apple-darwin` | cargo-cyclonedx 0.5.9, CycloneDX 1.5 | 72 dependency components plus the project root; 0 missing licenses |

The repository generator hashes every regular file with SHA-256, binds paths,
file modes, types, and symlink targets into the source namespace, records one
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

SOURCE_DATE_EPOCH=1784246400 scripts/generate_spdx_sbom.py \
  --source-root . \
  --output docs/open-source/sbom/source.spdx.json

uv tool run --from cyclonedx-bom==7.2.1 \
  cyclonedx-py environment analytics/.venv/bin/python \
  --pyproject analytics/pyproject.toml --mc-type application \
  --sv 1.6 --output-reproducible --of JSON -o /tmp/python-environment.raw.json
scripts/generate_spdx_sbom.py \
  --sanitize-cyclonedx /tmp/python-environment.raw.json \
  --workspace-root . \
  --output docs/open-source/sbom/python-environment.cdx.json

# With cargo-cyclonedx 0.5.9 installed on PATH:
SOURCE_DATE_EPOCH=1784246400 cargo cyclonedx \
  --manifest-path analytics/ffi/Cargo.toml --format json --all \
  --target aarch64-apple-darwin --spec-version 1.5 \
  --override-filename LiteratureAtlas-rust-source.cdx
scripts/generate_spdx_sbom.py \
  --sanitize-cyclonedx analytics/ffi/LiteratureAtlas-rust-source.cdx.json \
  --workspace-root . \
  --output docs/open-source/sbom/rust-source.cdx.json
```

An official release must generate a new SBOM from the exact Developer ID-signed
candidate and reconcile its hashes, source commit, signature/notary evidence,
notices, and provenance attestation after stapling.

SHA-256 values of the committed snapshot files:

```text
1c8dc2d061b7b7dfe58695a4bff38df8fa89548eada54d0d60c86a4a43105c68  community-app.spdx.json
65657374f17e19d5f82fc69567396e062d0a4ee8361bf5bf010ae91a0c1e0132  official-unsigned-app.spdx.json
18b300131e941921511c00a735ee0ba880e1c0c42bc7d5d6f7917bf6dee59f19  source.spdx.json
8bf9f5ce21e191edfb83400b6a57629c09464b2dd07b548fcbc2c9c32fb9a119  python-environment.cdx.json
651d595003f87f5883d42bd59ca3e3a5426dddd5c5f035e3e1af9cb9608d861d  rust-source.cdx.json
```
