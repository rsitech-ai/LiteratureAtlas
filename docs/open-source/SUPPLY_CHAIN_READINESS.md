# Supply-chain readiness

Ordinary CI is credential-free and should retain `contents: read` only. Action
references, compiler/tool versions, locked environments, timeouts, and
concurrency must be pinned in reviewed workflows. Signing/notarization must stay
local for the first release; no pull-request job may receive Apple credentials.

The authenticated 2026-07-20 repository check found secret scanning, push
protection, dependency alerts, Dependabot security updates, private
vulnerability reporting, and full-length Action SHA enforcement enabled.
Projects and Wiki are disabled and merged branches are deleted automatically.
Legacy personal-repository PR #11 executed dependency review and passed its
substantive hosted checks; it is historical evidence, not proof for the new org
head.
`main` requires an up-to-date pull request, nine named checks, and
resolved conversations; force pushes and branch deletion are disabled. Secret
validity and non-provider-pattern checks were requested but remain
unavailable/disabled for this repository. The organization repository already
enforces its selected-actions/full-SHA policy. Immutable releases and optional
public Scorecard publication remain separate owner decisions. The PR workflow detects an
unavailable dependency graph only after confirming repository API access,
reports it as an explicit warning, and preserves the independent Cargo/Python
lockfile audits instead of producing a false dependency-review failure. Any
permission, repository-access, forbidden, or unexpected API status fails closed.

A deterministic source SPDX inventory and pinned-tool Python/Rust CycloneDX
inventories exist under `sbom/`. Historical community/unsigned-app inventories
were removed because they did not describe the forthcoming exact merged-source
artifact. The ecosystem SBOMs contain no component with missing license
metadata. An exact official signed-app SBOM and provenance record are still
required; no official release may claim completion before those artifacts and
the containing commit are reconciled.
