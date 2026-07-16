# Supply-chain readiness

Ordinary CI is credential-free and should retain `contents: read` only. Action
references, compiler/tool versions, locked environments, timeouts, and
concurrency must be pinned in reviewed workflows. Signing/notarization must stay
local for the first release; no pull-request job may receive Apple credentials.

The authenticated 2026-07-16 repository check found secret scanning and push
protection enabled. Main branch protection, Dependabot security updates, private
vulnerability reporting, immutable releases, required checks, restricted
actions, and optional public Scorecard publication remain owner-controlled and
disabled or unenforced.

Deterministic source, community-app, and official unsigned-app SPDX inventories
plus pinned-tool Python/Rust CycloneDX inventories exist under `sbom/`.
The ecosystem SBOMs contain no component with missing license metadata. An exact
official signed-app SBOM and a provenance attestation are still required; no
official release may claim completion before those artifacts and the containing
commit are reconciled.
