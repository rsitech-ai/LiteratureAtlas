# Secret and sensitive-data audit

## Scope and result

The canonical organization repository was created from a sanitized mirror. A
targeted release inventory—not a formal security scan—confirmed that the
current tree and its only published branch contain none of the four prohibited
PDF objects and no legacy personal commit email. Signing certificates and the
notarization keychain profile remain local and are not stored in the repository.
The superseded personal repository is a separate legacy boundary retained only
until the signed/notarized RSI Tech replacement release is remotely verified.

## Controls

Sensitive key/profile extensions and `.env` files are ignored. Distributed
binaries are scanned for checkout-only execution/key markers. Paths/errors use
private unified-log privacy and raw question text is not duplicated to local
events.

GitHub secret scanning, push protection, dependency alerts, automated security
fixes, and private vulnerability reporting are enabled. The exact
signed/stapled artifact must pass the documented release-script marker and
distribution verification before publication. Do not store signing or
notarization credentials in this repository.
