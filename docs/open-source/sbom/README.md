# SBOM evidence

The canonical repository tracks one deterministic current-source SPDX inventory
and frozen Python/Rust dependency inventories. Historical app inventories tied
to the superseded personal prerelease were removed; the next app inventory must
be generated from the exact Developer ID-signed/stapled release candidate and
published beside that release.

| File | Scope | Generator |
|---|---|---|
| `source.spdx.json` | Current tracked/unignored source excluding Git, generated outputs, and this SBOM directory | `scripts/generate_spdx_sbom.py`, SPDX 2.3 JSON |
| `python-environment.cdx.json` | Frozen analytics Python 3.12 environment | cyclonedx-bom 7.2.1, CycloneDX 1.6 |
| `rust-source.cdx.json` | Rust FFI for `aarch64-apple-darwin` | cargo-cyclonedx 0.5.9, CycloneDX 1.5 |

The source generator hashes regular files, paths, modes, types, and symlink
targets; excludes its own output; uses reproducible timestamps when
`SOURCE_DATE_EPOCH` is set; and writes atomically. Dependency inventories retain
upstream license expressions and sanitize local workspace paths.

```bash
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

Final source/dependency hashes and the exact release-app SBOM hash are recorded
only after the release source and artifact are sealed.
