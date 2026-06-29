# TODO

## Tasks
- [x] Reproduce sidebar click failure (DoD: click target and unchanged view captured)
- [x] Fix sidebar selection contract (DoD: `RootView` uses explicit sidebar buttons that set `nav.selectedTab`)
- [x] Remove layout-time bridge analysis (DoD: `BridgingSection.body` no longer calls claim/influence path generation)
- [x] Runtime-click every sidebar row (DoD: Ingest, Universe, Q&A, Trading, Projects, Analytics all switch views)
- [x] Run Swift tests (DoD: `swift test` passes)
- [x] Memory update: sidebar selection and bridge-analysis convention (DoD: `MEMORY.md` updated)

## In progress
- None.

## Done
- [x] Verified click reaches the LiteratureAtlas sidebar row text but does not update the selected detail view.
- [x] Verified the app can route to Literature Atlas/Ingest, Knowledge Universe, Q&A, Trading lens, Projects, and Analytics after the fix.
