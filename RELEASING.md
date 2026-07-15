# Direct-download release runbook

This runbook prepares evidence; it does not authorize Apple uploads, Git tags,
GitHub Releases, or public announcements.

## 1. Establish the candidate

Record a clean commit, version, build number, owner-supplied official bundle ID,
exact Developer ID Application identity, release owner, and approved production
icon. Confirm every item in [BLOCKERS.md](docs/open-source/BLOCKERS.md).

## 2. Run source gates

Run the full matrix in [docs/build/README.md](docs/build/README.md), regenerate
the Xcode project, and require a clean diff. The release validator must report no
blockers.

## 3. Build without credentials

```bash
script/build_official.sh \
  --product-name LiteratureAtlas \
  --bundle-id "$OFFICIAL_BUNDLE_ID" \
  --version "$VERSION" \
  --build "$BUILD_NUMBER" \
  --output dist/official
```

Inspect architecture, resources, privacy manifest, and absence of checkout-only
runtime strings before signing.

## 4. Sign with Developer ID

```bash
script/sign_developer_id.sh \
  --app dist/official/LiteratureAtlas.app \
  --identity "$DEVELOPER_ID_APPLICATION"

script/verify_distribution.sh \
  --app dist/official/LiteratureAtlas.app \
  --mode official
```

The signer works on a staged copy and replaces the unsigned app only after a
verified signature. If keychain authorization fails, resolve it interactively;
do not export a private key into the repository or command history.

## 5. Create and inspect the DMG

```bash
script/create_dmg.sh \
  --app dist/official/LiteratureAtlas.app \
  --output "dist/official/LiteratureAtlas-$VERSION.dmg"
```

Record the exact app/DMG SHA-256 values, source commit, tools, and third-party
notices. Reconcile source and artifact SBOMs.

## 6. Approval-gated Apple submission

`notarytool submit` is an external Apple write. Run the following only after the
release owner approves this exact DMG and submission:

```bash
script/notarize_dmg.sh \
  --dmg "dist/official/LiteratureAtlas-$VERSION.dmg" \
  --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" \
  --submit
```

The script retains the structured submission response and full Apple log,
requires `Accepted`, staples and validates the DMG, then checks Gatekeeper.

```bash
script/verify_distribution.sh \
  --app dist/official/LiteratureAtlas.app \
  --dmg "dist/official/LiteratureAtlas-$VERSION.dmg" \
  --mode notarized
```

Also test a freshly downloaded/quarantined copy on supported hardware.

## 7. Publication gate

Update the changelog, reports, manifest, SBOMs, notices, signature/notary
evidence, and rollback instructions. A tag, GitHub Release, public artifact, or
announcement needs separate explicit approval. If a candidate is compromised,
withdraw the artifact, document the affected hashes, rotate exposed credentials,
and revoke the certificate through Apple when warranted.
