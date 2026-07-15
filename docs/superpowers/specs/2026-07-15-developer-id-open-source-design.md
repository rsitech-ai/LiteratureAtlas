# LiteratureAtlas Developer ID and Open-Source Design

## Outcome

LiteratureAtlas will ship as a macOS application downloaded outside the Mac App Store. The official artifact will be built from an exact source revision, signed with the owner's Developer ID Application identity, submitted to Apple's notary service, stapled, and distributed as a drag-and-drop disk image. The public repository will also provide a credential-free community build and the governance, licensing, security, provenance, and contribution material expected of a real open-source project.

This design does not authorize a notarization upload, GitHub release publication, repository-visibility change, credential rotation, license reclassification, or legal identity claim. Those remain explicit owner-controlled actions.

## Current State

- GitHub already reports `s1korrrr/LiteratureAtlas` as public, with `main` as the default branch.
- The tracked project is already distributed under MIT. Existing MIT grants cannot be withdrawn.
- The adopted technical baseline is commit `c7f4215`, which adds deterministic XcodeGen macOS/iPadOS application targets, sandbox/container runtime boundaries, privacy manifests, release validation, and a versioned App Store dossier.
- That baseline explicitly excluded Developer ID distribution and remains blocked on production icon artwork and Apple account state.
- The SwiftPM lane remains the contributor test surface.

## Options Considered

1. Extend the original hand-built SwiftPM bundle script.
2. Reuse the deterministic Xcode macOS application target, export an unsigned Release app, and wrap it with explicit community-signing, Developer ID signing, DMG, notarization, and verification scripts.
3. Replace the existing project with a new packaging system or third-party installer.

Chosen: option 2. It preserves the already-tested application target, Info.plist, assets, privacy manifest, and hardened runtime configuration while keeping private signing state outside the project. A custom installer is unnecessary for a self-contained application.

## Distribution Architecture

### Common staged app

One deterministic macOS Release build produces the unsigned application payload. It accepts reviewed overrides for product name, bundle identifier, version, build number, and output directory. It does not discover or select signing identities automatically.

The staged app must:

- use Application Support for persistent data;
- load prompts and immutable notices from bundle resources;
- contain a valid privacy manifest and complete release metadata;
- compile out source-checkout Python installation and analytics controls;
- use the pure-Swift fallback unless a separately verified Rust library is deliberately embedded;
- contain no Apple credentials, notary profile, update private key, or official local configuration.

### Community build

The community path signs the staged app ad hoc by default. It supports a distinct product name and bundle identifier and requires no Apple Developer membership. It uses no official update feed or protected signing material. Modified public distributions must rebrand and use their own identifiers, signing, support, privacy, and update configuration.

### Official build

The official path accepts an explicitly supplied Developer ID Application identity and signs nested code from the inside out, then signs the main app with hardened runtime and a secure timestamp. The script must refuse ad hoc, Apple Development, Mac App Distribution, or missing identities when official mode is requested.

The official artifact is a read-only compressed DMG containing the signed app and an Applications link. Notarization is a separate, approval-gated command that requires an existing Keychain credential profile. The workflow records the submission identifier and complete sanitized notary log, staples the accepted ticket, and re-runs Gatekeeper validation.

## Runtime Boundaries

- The macOS direct-distribution build uses the application container-safe data path already implemented by the adopted release branch.
- Bundled prompts remain resources of the Xcode target.
- Python analytics remains an open-source contributor/research lane. Official distributed builds do not offer package installation or execute checkout-relative scripts.
- Rust FFI remains optional. The first official artifact uses the Swift fallback unless a universal or declared-architecture dylib is placed in `Contents/Frameworks`, linked with `@rpath`, license-inventoried, and signed before the app.
- The dormant OpenAI provider is not selected in distributed builds. No API key is embedded. Any future network provider requires a separate privacy/security design.

## Licensing and Branding

The effective license remains MIT until the owner explicitly approves a future license and confirms relicensing rights. The proposed future map is:

- source, tests, and scripts: MPL-2.0;
- documentation: CC-BY-4.0;
- community assets: CC-BY-4.0 or CC0;
- official name, icon, logo, domains, and release artwork: reserved trademark material;
- third-party material: original upstream license;
- contributions: DCO 1.1 unless the owner chooses a lawyer-reviewed CLA.

The repository will record this as a proposal and publication blocker, not as an approved legal fact. It will not overwrite valid third-party notices or imply that the current generic `LiteratureAtlas contributors` line establishes ownership.

## Public Repository and Contribution Model

The repository will provide:

- accurate build, test, community-build, release, and troubleshooting instructions;
- contribution, DCO, governance, maintainers, support, security, privacy, code-of-conduct, roadmap, changelog, release, trademark, and branding policies;
- issue and pull-request templates that prohibit public vulnerability reports;
- least-privilege CI with pinned third-party actions where practical;
- locked dependency validation, secret checks, license/REUSE checks, required-file validation, community bundle validation, and SBOM generation;
- a publication gate matrix and machine-readable manifest that distinguish completed local gates from owner, Apple, and GitHub-setting blockers.

Policies that require an owner-supplied private moderation contact, exact legal entity, or trademark-owner identity will fail closed and name the missing approval.

## Release Integrity

Every official source release will map one exact tag and commit to:

- the DMG and SHA-256 checksum;
- source and artifact SBOMs;
- third-party notices;
- Xcode, SDK, Swift, Rust, Python, and dependency-lock versions;
- signing identity category and Team ID, without private-key material;
- notarization submission ID and accepted log;
- build workflow and provenance evidence.

The project promises traceability, not byte-for-byte reproducibility of Apple-signed artifacts.

## Security and Privacy

- Public source is the threat-model baseline; client secrecy is never an authorization control.
- Current-tree and reachable-history secret scans are required before publication claims.
- Official signing and notarization credentials are never available to untrusted pull requests.
- Private vulnerability reporting, secret scanning, push protection, dependency review, and branch-protection recommendations are separate GitHub gates.
- No production user data, local `Output`, source PDFs, environment files, Keychain items, certificates, profiles, or logs containing private document content enter release artifacts.

## Testing and Acceptance

The machine-verifiable completion bar is:

1. Swift, Rust, and Python format/lint/test gates pass from locked dependencies.
2. Deterministic Xcode generation and unsigned macOS Release build pass.
3. Community app staging, relocation, ad-hoc signing, launch, and bundle-resource tests pass without a source checkout at runtime.
4. Official-mode scripts fail closed without an explicit Developer ID identity and notary credential reference.
5. If an eligible identity and explicit action approval are available, Developer ID signature, hardened runtime, timestamp, DMG, notarization, stapling, Gatekeeper, and quarantined clean-account launch pass.
6. Secret/history, dependency/license, REUSE, SBOM, CI-safety, governance, and documentation gates produce auditable evidence.
7. Final code and security reviews have no unresolved critical, high, or publication-blocking medium findings.

## Owner-Controlled Blockers

The final verdict cannot exceed `NOT READY` or `BLOCKED` until the owner explicitly confirms:

- final software license;
- exact copyright holder;
- exact trademark owner and protected marks;
- DCO versus CLA;
- private conduct-reporting contact;
- official bundle identifier and signing Team ID;
- production icon and brand provenance;
- automatic-update policy and signing-key custody;
- approval for each notarization upload and public release action.

## Rollback

The direct-distribution layer is additive. If it fails, remove its scripts, configuration, documentation, and workflow changes while retaining the already-committed Xcode/App Store baseline. No rollback may discard user commits, rewrite public history, revoke existing MIT grants, or remove external release evidence.
