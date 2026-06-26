# TODO

## Tasks
- [ ] Add immersive galaxy design spec (DoD: `docs/superpowers/specs/2026-06-26-immersive-galaxy-ui-design.md` describes scope, components, risks, and validation)
- [ ] Add shared galaxy visual system (DoD: reusable SwiftUI helpers cover backdrop, cards, hero headers, stat pills, and action styling)
- [ ] Upgrade root shell and shared cards (DoD: app root uses animated galaxy backdrop and existing card call sites compile)
- [ ] Refresh Ingest UI (DoD: ingest screen has immersive hero, status deck, clearer actions, and no behavior changes)
- [ ] Refresh Q&A UI (DoD: question screen has polished empty/loading/answer/evidence states and no behavior changes)
- [ ] Lightly tune analytics/shared overlays (DoD: top-level surfaces reuse shared galaxy styling without large chart rewrites)
- [ ] Validate SwiftPM build and tests (DoD: `swift build`, `swift test`, and app launch smoke completed or blockers recorded)
- [ ] Memory update: record visual-system convention if implemented (DoD: `MEMORY.md` updated only for durable repo knowledge)

## In progress
- [ ] Add immersive galaxy design spec

## Done
- [x] Preserved previous document/knowledge-base work on `feat/andrzej_literatureatlas-document-kb-snapshot`
- [x] Created implementation branch `feat/andrzej_immersive-galaxy-ui`
