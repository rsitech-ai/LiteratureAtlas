# TODO

## Tasks
- [x] Fix Python ruff linting issues (DoD: `ruff check` passes)
- [x] Convert print() to logging module (DoD: no print() in analytics code)
- [x] Add pytest configuration to pyproject.toml (DoD: `pytest` discovers tests)
- [x] Add ruff configuration to pyproject.toml (DoD: config present)
- [x] Review Swift code for issues (DoD: `swift build` and `swift test` pass)
- [x] Review Rust FFI code (DoD: `cargo clippy` and `cargo test` pass)
- [x] Run all tests to verify (DoD: 47 tests pass)
- [x] Memory update: document commands and conventions (DoD: MEMORY.md updated)

## In progress
(none)

## Done
- [x] Fix unused imports (`List`, `Dict` from typing)
- [x] Fix unused variables (`W`, `nmf_components`, `neigh_set`, `best_shared`, `all_methods`, `all_datasets`, `all_metrics`)
- [x] Fix ambiguous variable name (`l` → `lbl`)
- [x] Fix deprecated type hints (`Dict[...]` → `dict[...]`)
- [x] Add logging.basicConfig() in main()
- [x] Add dev dependencies section to pyproject.toml
- [x] Create MEMORY.md with durable knowledge
- [x] Create PLAN.md with audit documentation
- [x] Create TODO.md with task tracking
