# LiteratureAtlas 1.0.0 Privacy and Data Map

## Product boundary

The App Store build is designed as a local research workspace. It accepts documents selected by the user, processes them with Apple's on-device Foundation Models APIs and local algorithms, and stores derived artifacts inside the application container. No network document compiler is present. The runtime Python pipeline and repository-relative Rust loader are excluded at compile time from `APP_STORE_BUILD`.

This map describes verified code and packaged behavior. It does not replace the product owner's App Store Connect privacy attestation or privacy policy.

## Data flow

| Data | Source | Processing | Storage | Transmission | User control |
| --- | --- | --- | --- | --- | --- |
| PDF and Markdown contents | User-selected folder | Text extraction, summaries, embeddings, topic/claim analysis | Derived paper/chunk JSON and Markdown under the app container | No transmission path found in App Store build | User chooses the source folder; source access is read-only |
| File metadata | Selected files | File type, path, modification timestamps, page/year inference | Included where needed in local paper/index artifacts | No transmission path found | Follows selected-folder scope |
| Questions and generated answers | User input and on-device model output | Local retrieval and synthesis | Answer text under local `Output/qa`; a SHA-256 question digest is used only in the filename. Raw question text remains in session memory for product features and is not stored in diagnostics/events | No transmission path found | Removed by deleting the app/container; no dedicated erase UI is verified |
| Research notes, reading state, project data | User input | Local organization and analytics | Local JSON/Markdown under the app container | No transmission path found | Edited/deleted through product flows where exposed; full reset is not verified |
| Embeddings, clusters, claim graphs, analytics | Derived locally | On-device model and deterministic local computation | Local app-container artifacts | No transmission path found | Removed with app data |
| Operational logs and user events | App behavior | Local diagnostics/aggregate analytics | Local text/JSONL in the app container and OSLog | No first-party telemetry endpoint found | No dedicated diagnostics deletion/export UI is verified |

## Network and SDK inventory

- Document compilation is on-device in every build; the repository contains no OpenAI compiler endpoint or API-key path.
- App Store compilation excludes the Python analytics launcher and dependency installer.
- App Store compilation disables the relative `dlopen` Rust FFI path and uses the pure-Swift fallback.
- No third-party runtime SDK is linked by either application target.
- Apple's Foundation Models framework is the model-processing boundary. The release owner must confirm Apple's current platform behavior and reflect it accurately in the privacy policy.

## Required-reason APIs

Both platform manifests declare `NSPrivacyAccessedAPICategoryFileTimestamp` with:

- `3B52.1` for timestamps on files the user granted access to.
- `C617.1` for timestamps inside the app container.

Distribution verification lints the packaged manifest and requires both reason
codes under `NSPrivacyAccessedAPICategoryFileTimestamp`.

The manifests intentionally omit `NSPrivacyCollectedDataTypes`; an empty declaration would be an unverified privacy claim. App Store Connect answers remain owner-attested.

## Sandbox and retention

- macOS entitlement: App Sandbox plus `com.apple.security.files.user-selected.read-only`.
- Distribution verification inspects the shipped signature and fails unless read-only
  user-selected access is `true` and the read-write entitlement is absent.
- iPadOS entitlement file is intentionally empty; document access is mediated by the system picker/container.
- The selected macOS folder's security scope is opened before enumeration and closed when ingestion finishes.
- Mutable output uses `Application Support/LiteratureAtlas/Output` within the application container for App Store builds.
- No automatic cloud sync, remote analytics upload, account system, advertising identifier, tracking permission, contacts, location, camera, microphone, health, payment, or authentication flow was found.
- Local derived data persists until the user removes it or deletes the app/container. A dedicated “erase all local data” control is not verified and should be considered for a later privacy-control release.

## App Store privacy decisions requiring an owner

- Confirm whether any future support, crash reporting, sync, or model-service configuration transmits document content, questions, identifiers, diagnostics, or usage data.
- Confirm the privacy-policy URL and make its retention/deletion language match the shipped build.
- Determine App Store Connect data types from actual production operations, not from this source audit alone.
- Confirm whether imported research documents may contain personal data and describe the app's local-processing boundary appropriately.
