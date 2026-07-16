# Technical security boundary

The distributed macOS build is a sandboxed local application. It receives
read-only security-scoped access to folders explicitly selected by the user and
writes mutable data beneath `Application Support/LiteratureAtlas/Output`.

The `DISTRIBUTED_APP_BUILD` compile condition excludes checkout-only Python
execution and installation, environment API keys, the dormant remote compiler
provider, and repository-relative Rust dynamic loading. Prompts are copied into
the application bundle. Contributor SwiftPM builds retain local development
tools and therefore have a wider trust boundary.

Document content, filenames, paths, generated outputs, questions, credentials,
signing identities, notary profiles, and notarization records are sensitive.
Paths and errors use private unified-log privacy; raw question text is not copied
into analytics events. Exported local graphs and paper JSON may contain source
paths and must be treated as user-private data.

Signing and notarization credentials stay outside Git and ordinary CI. Build,
signing, DMG creation, submission, and publication are separate gates.

Release validation includes locked dependency checks, secret/history review,
binary marker scans, sandbox entitlement checks, exact Developer ID authority,
DMG checksums, retained Apple submission evidence, stapling, and Gatekeeper.
See [SECURITY.md](../../SECURITY.md) for reporting policy and
[PRIVACY_DATA_MAP.md](../release/1.0.0/PRIVACY_DATA_MAP.md) for the current data map.
