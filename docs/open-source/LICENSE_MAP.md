# License map

## Effective license

Rafal Sikora has confirmed copyright and licensing authority for the
project-authored current tree. That work is offered under Apache-2.0 and
publicly maintained by RSI Tech. Historical snapshots already received under
MIT keep those grants; this change does not withdraw them.

| Logical group | Current treatment | Publication status |
|---|---|---|
| Project-authored code, tests, prompts, and docs | Apache-2.0; copyright 2025-2026 Rafal Sikora | Pass |
| `DCO.txt` and its REUSE license copy | `LicenseRef-DCO-1.1`; verbatim distribution terms; copyright The Linux Foundation and contributors | Pass; not relicensed |
| Apple SDKs/system frameworks | Apple terms; not vendored or relicensed | Compatible platform dependency |
| Python packages | Upstream licenses in frozen environment SBOM | Pass with retained upstream notices |
| Rust crates | Upstream licenses in Cargo lock/SBOM | Pass with retained upstream notices |
| Generated metadata | Generated from project/upstream declarations | Regenerate on release source |
| Historical PDFs | Absent from canonical org history and all published refs | Pass in fresh clone |
| RSI Tech/LiteratureAtlas branding | No registered-mark claim; redistribution rules in `BRANDING.md` | Pass |

Apache-2.0 section 5 supplies the default inbound contribution terms. The
project also requires Developer Certificate of Origin 1.1 sign-offs.
