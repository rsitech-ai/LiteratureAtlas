# Secret and sensitive-data audit

## Scope and result

The canonical organization repository was created from a sanitized mirror. A
targeted release inventory—not a formal security scan—confirmed that the
current tree and its published history contain none of the four prohibited PDF
objects. The sanitized baseline contains no legacy personal commit email;
GitHub authored PR #4's merge commit with the account merge identity rather
than the repository-configured no-reply email. Signing certificates and the
notarization keychain profile remain local and are not stored in the repository.
After the signed/notarized replacement was remotely verified, the superseded
personal release/tag were removed and its repository made private and archived.

## Controls

Sensitive key/profile extensions and `.env` files are ignored. Distributed
binaries are scanned for checkout-only execution/key markers. Paths/errors use
private unified-log privacy and raw question text is not duplicated to local
events.

GitHub secret scanning, push protection, dependency alerts, automated security
fixes, and private vulnerability reporting are enabled. The published exact
signed/stapled artifact passed the documented release-script marker and
distribution verification. Do not store signing or notarization credentials in
this repository.
