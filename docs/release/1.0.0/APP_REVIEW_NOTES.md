# LiteratureAtlas 1.0.0 App Review Notes — Draft

> Do not paste this into App Store Connect until the bracketed owner fields are completed and the signed build is validated.

## Suggested review notes

LiteratureAtlas is a local research workspace for macOS and iPad. Users select a folder containing PDF or Markdown research documents. The app extracts text, builds a visual knowledge universe, and provides summaries, cited question answering, insights, projects, and local exports.

The submitted build uses Apple's on-device Foundation Models APIs. It does not require an account, subscription, external service, API key, or reviewer credentials. App data and derived artifacts are stored locally in the application container. On macOS, source-folder access is user-selected and read-only.

The app requires a supported device with Apple Intelligence enabled and an available on-device model. When the model is unavailable, the app presents an explicit unsupported state instead of silently using a remote service.

Suggested review path:

1. Launch the app on a supported Apple Intelligence-capable device.
2. Open Ingest and select the supplied review-sample folder: `[OWNER: attach or describe non-confidential sample documents]`.
3. Wait for processing to complete.
4. Open Universe to inspect topics and papers.
5. Open Q&A and ask `[OWNER: sample question]`.
6. Open Insights, Projects, and Analytics to inspect local derived views.
7. Use Export to write a user-requested local artifact.

## Review prerequisites to confirm

- Review-sample documents are licensed for Apple review and contain no private data.
- The reviewer device supports the on-device model in the selected storefront/language.
- Any long-running processing time and expected document count are stated accurately.
- Support contact: `[OWNER REQUIRED]`.
- No login credentials are required.

## Platform notes

- iPad release: iPadOS 26.0 or later, iPad only. iPhone is not supported in 1.0.0.
- Mac release: macOS 26.0 or later, Apple silicon and Intel architectures in the archive.
- OS 27 beta results in this dossier are compatibility observations only and are not the production submission toolchain.

## Contact and compliance placeholders

- Review contact name: `[OWNER REQUIRED]`
- Review contact email: `[OWNER REQUIRED]`
- Review contact phone: `[OWNER REQUIRED]`
- Privacy policy URL: `[OWNER REQUIRED]`
- Support URL: `[OWNER REQUIRED]`
- Notes about content rights/export compliance/DSA: `[OWNER REQUIRED IF APPLICABLE]`
