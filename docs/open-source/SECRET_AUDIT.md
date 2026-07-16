# Secret and sensitive-data audit

## Scope and result

The current tracked tree and all reachable Git objects were scanned with
redacted pattern/fingerprint inspection. No Apple private key, certificate
export, provisioning profile, App Store Connect key, API credential, bearer
token, SSH private key, cloud/database credential, `.env` secret, or notary
profile was found. Credential-shaped candidates: 0. Rotated secrets: 0 because
no exposed credential was identified.

One personal email occurs in commit metadata. It is an author identifier, not a
credential, and is not reproduced here. Historical PDFs are IP exposure, not
secret exposure.

## Controls

Sensitive key/profile extensions and `.env` files are ignored. Distributed
binaries are scanned for checkout-only execution/key markers. Paths/errors use
private unified-log privacy and raw question text is not duplicated to local
events.

The post-evidence exact-commit rerun found zero credential signatures in the
current tree or reachable revisions and zero open GitHub secret-scanning alerts.
GitHub secret scanning and push protection are enabled. A future official
release must separately scan the exact signed/stapled artifact. Do not store
signing or notarization credentials in this repository.
