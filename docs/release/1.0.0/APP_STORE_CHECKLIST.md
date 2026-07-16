# LiteratureAtlas 1.0.0 App Store Checklist

## Repository and configuration

- [x] Version `1.0.0` and build `1` have one xcconfig source.
- [x] macOS and iPadOS bundle identifiers have one project-spec source.
- [x] Shared schemes run Debug and archive Release.
- [x] Debug and Release both compile through `APP_STORE_BUILD`.
- [x] Deployment floors are macOS/iPadOS 26.0.
- [x] iPadOS target is iPad-only (`TARGETED_DEVICE_FAMILY = 2`).
- [x] macOS App Sandbox and read-only user-selected file access are enabled.
- [x] No unverified iPadOS capabilities are declared.
- [x] Required-reason privacy manifests are packaged.
- [ ] Production AppIcon artwork is complete and approved.
- [ ] Confirm bundle IDs and Apple Team against App Store Connect.

## Quality and security

- [x] Swift tests pass; the full opt-in corpus ingest remains separately gated.
- [x] Swift production build passes.
- [x] Python Ruff format/lint and tests pass.
- [x] Python lock is current and Python dependency audit reports no known vulnerabilities.
- [x] Rust format, strict clippy, and tests pass.
- [x] Rust dependency audit reports no known vulnerabilities; the `bincode` maintenance warning is documented.
- [x] App Store executable string scan finds no OpenAI endpoint, runtime pip command, analytics Python script, or relative FFI library marker.
- [x] Security-scoped folder access begins before sandboxed enumeration.
- [x] No secrets, profiles, certificate fingerprints, raw device identifiers, or private URLs are committed.
- [x] Run complete security diff scan over every changed source-like file; sealed result has zero findings and zero deferred rows.

## Runtime acceptance

- [x] macOS app launches with sandbox/read-only entitlements on the macOS 27 beta host.
- [x] macOS live navigation selects Ingest, Universe, Q&A, Insights, Projects, and Analytics.
- [x] macOS container path is used and `/Output` is not created.
- [x] iPadOS 26.5 simulator build installs and launches.
- [x] iPad compact/split navigation regression has unit and runtime coverage.
- [x] iPadOS 27 beta launches the explicit model-unavailable state without a crash.
- [ ] Run the complete import/Q&A/export flow on an Apple Intelligence-capable physical iPad running iPadOS 26.
- [ ] Run the complete sandbox/import/Q&A/export flow on supported macOS 26 hardware.
- [ ] Validate airplane-mode/offline behavior, permission denial/retry, background/foreground, low storage, interruption, and relaunch recovery on devices.

## Archives and signing

- [x] Fresh unsigned macOS Release archive succeeds.
- [x] macOS archive is universal `arm64` + `x86_64`, contains dSYM and privacy manifest.
- [x] Fresh unsigned iPadOS Release archive succeeds.
- [x] iPadOS archive is device `arm64`, iPad-only, and contains dSYM and privacy manifest.
- [ ] Confirm signing team and identifiers.
- [ ] Install matching App Store profiles.
- [ ] Produce fresh distribution-signed archives from the approved PR head.
- [ ] Inspect final signatures, entitlements, provisioning, architectures, dSYMs, privacy manifests, and icon assets.
- [ ] Run Apple validation on both archives.
- [ ] Upload only after explicit approval.

## App Store Connect and review

- [ ] Name, subtitle, descriptions, keywords, categories, copyright.
- [ ] Support URL, privacy-policy URL, and marketing URL if used.
- [ ] App Privacy answers reconciled with `PRIVACY_DATA_MAP.md`.
- [ ] Age rating questionnaire.
- [ ] Content-rights declaration for user-imported research material.
- [ ] Export-compliance determination.
- [ ] EU DSA trader status and contact verification.
- [ ] Accessibility nutrition labels.
- [ ] Pricing, territories, availability, and release mode.
- [ ] Review contact and final notes based on `APP_REVIEW_NOTES.md`.
- [ ] Approved production icon and marketing screenshots.
- [ ] Final build selected and submitted only after explicit approval.
