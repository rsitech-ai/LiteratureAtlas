# Public/private boundary

| Class | Examples | Rule |
|---|---|---|
| Public source | Swift/Python/Rust code, prompts, tests, policy docs | May be committed after provenance/license review |
| Generated public metadata | Xcode project, Cargo/uv locks, SBOMs without local paths | Regenerate deterministically and review diffs |
| User-private content | PDFs, Markdown notes, questions, paths, `Output/`, exports, crash/log context | Keep local; sanitize before reporting |
| Release-sensitive evidence | Notary response/log, candidate hashes, signing diagnostics | Retain privately until reviewed; publish only safe evidence |
| Credentials/private keys | Developer ID key, API keys, profiles, passwords, `.p8`, `.p12` | Never commit; owner-controlled keychain/environment only |
| Official brand assets | Future icon/logo/store artwork | Publish only with owner/provenance approval |

Distributed app data is stored under Application Support. Contributor builds use
checkout-local `Output/`. Local graph and paper JSON exports may preserve source
paths and must be handled as private user data.
