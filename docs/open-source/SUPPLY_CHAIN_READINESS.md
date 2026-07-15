# Supply-chain readiness

Ordinary CI is credential-free and should retain `contents: read` only. Action
references, compiler/tool versions, locked environments, timeouts, and
concurrency must be pinned in reviewed workflows. Signing/notarization must stay
local for the first release; no pull-request job may receive Apple credentials.

GitHub-side required checks, branch protection, dependency graph, Dependabot
security updates, full-SHA enforcement, restricted actions, CodeQL activation,
and optional Scorecard publication are owner-controlled settings and remain
blocked until separately approved.

Pinned-tool source, Python, Rust, and community-app SBOMs exist under `sbom/`.
The ecosystem SBOMs contain no component with missing license metadata. An exact
official signed-app SBOM and a provenance attestation are still required; no
official release may claim completion before those artifacts and the containing
commit are reconciled.
