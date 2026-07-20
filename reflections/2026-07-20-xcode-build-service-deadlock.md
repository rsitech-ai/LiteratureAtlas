# Reflection: Xcode build-service deadlock and hosted handoff

## Task

- **ID / title:** RSI Tech exact-source macOS release build
- **Date:** 2026-07-20
- **Scope:** Produce an official unsigned app from the exact merged source without weakening release verification.
- **Authority boundary:** Local diagnosis and credential-free hosted build configuration; do not terminate unrelated builds, upload Apple credentials, or claim signing/notarization before artifact proof.

## Success and Risk

- **Success criteria:** Obtain a checksummed unsigned app and dSYM whose embedded source revision equals protected `main`, then sign and notarize that exact app locally.
- **Hypothesis 1:** LiteratureAtlas source or asset compilation causes the archive to stall.
- **Hypothesis 2:** Parallel Xcode scheduling causes a project-local deadlock that serial execution avoids.
- **Hypothesis 3:** The local Xcode 26.6 build service is deadlocked independently of LiteratureAtlas and requires a clean hosted build environment.
- **Rollback path:** Delete the manual workflow before merge and retain the validated source/configuration if hosted execution cannot reproduce the build.

## Candidate Directions

| Candidate | Expected benefit | Main risk | Evidence before choice | Decision |
|---|---|---|---|---|
| A: keep retrying local archive variants | No workflow addition | Repeated hangs and interference with unrelated developer work | Default, serialized, and one-job LiteratureAtlas archives stalled | Rejected |
| B: terminate all Xcode build services and retry | May clear shared state | Would disrupt unrelated projects outside task authority | SpaceLens and CodexWatch had active build-service processes with the same wait state | Rejected |
| C: credential-free exact-main hosted unsigned build, local signing | Clean builder while Apple credentials remain local | Adds a short-lived transport handoff that must be bound to source and checksums | Direct compiler and `actool` probes passed; GitHub provides the required macOS/Xcode runner | Retained |

## Evidence

- **First meaningful failure signal:** `xcodebuild archive` stopped making progress while the Xcode build-service child compiler blocked writing its driver output to an unread pipe.
- **Commands or runtime checks:** Repeated default, serialized, and `-jobs 1` archives; standalone `actool`; direct compiler probe; process sampling for LiteratureAtlas and two unrelated workspaces.
- **What the evidence ruled in or out:** Asset compilation and the direct compiler completed quickly, ruling out the AppIcon and source frontend as the stall. Independent projects exhibited the same build-service state, ruling in a shared local Xcode environment failure rather than a LiteratureAtlas regression.

## Decision

- **Root cause or remaining unknown:** Xcode 26.6 build-service orchestration on the local macOS 27 beta environment deadlocks while a child compiler writes driver output. The deeper Apple-toolchain cause remains external.
- **Retained fix / direction:** A manually dispatched, read-only GitHub workflow runs only on `main`, verifies exact checkout and deterministic XcodeGen output, builds without signing credentials, validates embedded revision/bundle/version/architecture, and uploads checksummed transport archives. Developer ID signing and notarization remain local.
- **Why alternatives were rejected:** Further retries produced no stronger evidence, and killing shared Xcode processes would exceed the repository task's authority. Moving signing to CI would unnecessarily expose Apple credentials.
- **Residual risk:** The hosted runner can expose a separate toolchain incompatibility; publication remains blocked until the downloaded bytes, signature, notarization, stapling, Gatekeeper result, SBOM, and remote release assets are all verified.
- **Rollback trigger:** Remove the workflow if it cannot build the exact protected-main SHA or if its source/checksum bindings cannot be independently verified.

## Reusable Lesson

- **Pattern to retain:** Separate credential-free compilation from local credentialed signing, and bind the handoff with an embedded source revision plus transport checksums.
- **Pattern to avoid:** Do not treat repeated Xcode build-service hangs as project evidence when direct compiler/asset probes and unrelated projects show a shared orchestration fault.
- **Where it applies next:** macOS direct-download releases when the local Xcode build service is unreliable but signing identities and notarization credentials must remain on the maintainer machine.
