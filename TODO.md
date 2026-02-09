# TODO

## Tasks
- [x] Integrate analytics health checks into app rebuild flow (DoD: rebuild triggers output + topic audits automatically)
- [x] Add app state + UI visibility for health-check status/logs (DoD: Analytics view shows message and log panel)
- [x] Add manual app trigger for health checks (DoD: button in Analytics backend card works)
- [x] Verify app/CLI sync with regression tests + smoke run (DoD: swift test + python tests + `scripts/run_example_smoke.sh --count 10` pass)
- [x] Memory update: record app-sync behavior (DoD: MEMORY.md updated)

## In progress
- none

## Done
- [x] Refresh `PLAN.md` for integration + sample-run scope
- [x] Added `LITERATURE_ATLAS_SMOKE_FAST` env mode for deterministic ingestion smoke path
- [x] Tuned smoke-run primary-topic threshold to `ceil(40% of sample)` to avoid small-sample false negatives
- [x] Verified two separate random 10-paper smoke runs pass end-to-end
- [x] Root-caused full-corpus drop from 115 -> 114 to paper JSON title-collision overwrite (`My Articles`)
- [x] Fixed `savePaperJSON` to use id-suffixed filenames and safe legacy migration/removal for matching papers only
- [x] Ran full corpus ingest into repo `Output/` and validated analytics + ANN + audits (all pass)
