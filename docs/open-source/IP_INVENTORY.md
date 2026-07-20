# Intellectual-property inventory

| Scope | Current disposition | Evidence | Required action |
|---|---|---|---|
| Swift source and tests | Existing MIT notice; ownership not fully proven | Git history; root `LICENSE` | Owner/employer/contractor/AI provenance attestation |
| Python analytics source and scripts | Existing MIT notice; ownership not fully proven | Git history | Same chain-of-title review |
| Rust FFI source | Existing MIT notice; ownership not fully proven | Git history | Same chain-of-title review |
| Prompts and documentation | Existing repository MIT scope; origin not individually attested | Tracked files and Git history | Confirm authored/adapted/AI-assisted provenance |
| Generated Xcode project and lock files | Generated metadata | `project.yml`, Cargo and uv locks | Regenerate deterministically; preserve upstream metadata |
| Release evidence screenshots | Provenance not classified | `docs/release/1.0.0/evidence/` | Owner review; replace/remove if rights are uncertain |
| Production icon/brand artwork | Absent | Release validator | Supply approved original artwork and owner identity |
| Current sample research documents | None | Current-tree inventory | Continue requiring user-supplied authorized corpora |

## Reachable historical PDFs

Four PDFs introduced in root history and later deleted remain downloadable from
the already-public Git object graph. The audit associated them with arXiv
identifiers 1703.00308, 2302.06962, 2302.07911, and 2210.13996. The observed
terms include one arXiv distribution-only record, one CC BY-NC-ND 4.0 record,
and two CC BY 4.0 records. Those terms are not uniformly suitable for an
unrestricted official open-source repository history.

Publication requires either a new clean-history repository from the audited
source snapshot or an owner-approved destructive rewrite of every public ref,
followed by host/cache coordination. Rewriting does not revoke copies already
obtained. No history rewrite was performed.

## Contributors and ownership

Git history contains three human author-name forms, `Rafal`, `Rafał Sikora`, and
`s1korrrr`, plus automated Dependabot commits. No DCO, CLA, mailmap, employer
release, contractor assignment, or rights attestation was found. Git metadata
is not chain-of-title evidence. Exact copyright holder and authority to
relicense remain owner/legal-review blockers.
