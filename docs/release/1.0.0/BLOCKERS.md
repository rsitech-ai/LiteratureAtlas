# LiteratureAtlas 1.0.0 Blockers

## Blocking submission

| ID | Blocker | Owner | Evidence needed to close |
| --- | --- | --- | --- |
| B-01 | Production AppIcon artwork is absent | Product/design owner | Approve a visual direction; commit the complete macOS/iPadOS icon set; pass `app_icon_artwork` validation and asset-catalog compilation |
| B-02 | Bundle identifiers and Apple Team are local defaults only | Apple account owner | Confirm/register `com.literatureatlas.app` and `com.literatureatlas.app.ios`, confirm Team `2NY8A789TN`, then set the single centralized team/identifier values |
| B-03 | Matching App Store provisioning is unavailable | Apple account owner | Install/select valid Mac App Store and iPadOS App Store profiles for the confirmed identifiers and team |
| B-04 | Distribution-signed archives and Apple validation are unverified | Release lead after B-02/B-03 | Create fresh immutable signed archives, inspect signatures/entitlements, then run Organizer/App Store validation without uploading |
| B-05 | Physical-device first-release acceptance is missing | Product owner/release QA | Run iPadOS 26 on an Apple Intelligence-capable iPad and macOS 26 on supported hardware; cover launch, import, processing, Q&A, export, lifecycle, permissions, offline behavior, and recovery |
| B-06 | App Store metadata and legal/compliance answers are unknown | Product/legal owner | Supply app name/subtitle/description/keywords/categories, support and privacy URLs, age rating, content rights, export compliance, DSA trader status, accessibility labels, pricing, territories, release mode, and reviewer contact |
| B-07 | App privacy answers are not owner-attested | Privacy/product owner | Confirm whether locally processed documents/questions are ever transmitted or linked outside the app; complete App Privacy answers against `PRIVACY_DATA_MAP.md` |
| B-08 | Final marketing screenshots are not approved | Product/design owner | Capture populated, production-like macOS and iPad screens at App Store dimensions; review for PII/licensing and approve the final set |

## Non-blocking tracked debt

- `bincode 1.3.3` is reported as unmaintained (`RUSTSEC-2025-0141`) but no vulnerability is reported. The FFI is excluded from App Store runtime loading; migrate deliberately in a separate compatibility-tested change.
- A macOS `leaks` snapshot reported 20,016 bytes in framework XPC root cycles after about 20 minutes. No LiteratureAtlas-owned frame appeared in the leak graph. Recheck with Instruments on the signed release candidate if physical-device acceptance shows growth.
- iPadOS 27 beta did not have Apple Intelligence enabled, so compatibility evidence covers graceful fallback and launch, not end-to-end model output.

## Explicit non-blockers

- Xcode 27 beta is not required for current submission. Production archives were built with Xcode 26.6 and SDK 26.5; OS 27 was compatibility-only.
- No iPhone listing is planned for 1.0.0. `TARGETED_DEVICE_FAMILY = 2` prevents an unsupported iPhone promise.
- The absence of App Store Connect access did not prevent repository hardening, unsigned archive construction, or local runtime proof.
