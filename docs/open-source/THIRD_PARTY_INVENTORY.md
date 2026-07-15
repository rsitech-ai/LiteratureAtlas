# Third-party inventory

## Exact distributed app closure

The first direct macOS app embeds no third-party Python environment, Rust FFI
library, or remote Swift package. It uses Apple SDK/system frameworks and bundled
project resources. Artifact string inspection found no checkout Python,
`OPENAI_API_KEY`, rebuild-script, or Rust-library markers.

## Contributor source closure

- SwiftPM remote dependencies: 0.
- Rust direct dependencies: `hnsw_rs 0.3.3`; the exact transitive graph is
  resolved in `analytics/ffi/Cargo.lock`.
- Python direct dependencies: DuckDB, NumPy, pandas, scikit-learn, PyArrow.
- Python dev dependencies: pytest and Ruff; exact versions and transitives are
  resolved in `analytics/uv.lock`.

For the supported Apple Silicon contributor target, the Rust CycloneDX inventory
contains 72 components including the project root (71 third-party components),
and the Python inventory contains 18 components. Every component in those two
ecosystem SBOMs has license metadata; all observed expressions are permissive
open-source licenses. Unknown third-party licenses: 0.

Current Rust advisory review found no known vulnerability and one unmaintained
crate warning for `bincode 1.3.3`. The Python environment is locked and tested;
an independent current advisory/SBOM tool result remains required before an
official release.

Canonical distribution notices are in
[THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md). Exact source and artifact
SBOMs are under [`sbom/`](sbom/). A future exact official signed-app SBOM remains
a publication gate.
