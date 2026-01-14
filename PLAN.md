# Plan

## Context
- Comprehensive code audit to bring codebase to production-ready state
- Goal: fix bugs, remove dead code, ensure tests pass, improve code quality

## Assumptions
- All existing tests should continue to pass
- No breaking changes to public APIs or data formats
- Changes should be minimal and focused on correctness

## Constraints
- Do not change Output/ schema
- Preserve backward compatibility with existing JSON files
- Do not add new features, only fix existing issues

## Options considered
1) Full rewrite of problematic modules
2) Targeted fixes for identified issues only
Chosen: 2 because it minimizes risk and keeps changes reviewable

## Execution plan
1. ✅ Scan repo structure and understand architecture
2. ✅ Run static analysis (ruff, clippy, swift build)
3. ✅ Fix Python linting issues (unused imports/variables, deprecated types)
4. ✅ Convert print() to logging module
5. ✅ Add pytest/ruff configuration to pyproject.toml
6. ✅ Verify all tests pass (Swift, Python, Rust)
7. ✅ Create MEMORY.md with durable knowledge

## Test plan
- Run `swift test` — 42 tests, all passed
- Run `python -m pytest analytics/tests -v` — 2 tests, all passed
- Run `cargo test --manifest-path analytics/ffi/Cargo.toml` — 3 tests, all passed
- Run `python -m ruff check analytics/` — all checks passed

## Risks and rollback
- Risk: Import reordering breaks something → Rollback: revert import changes
- Risk: Logging changes affect downstream consumers → Rollback: revert to print()

## Memory impact
- Added: Working test commands for all stacks
- Added: Lint/format commands
- Added: Architecture overview and conventions
- Added: Known pitfalls

## Notes / Results (fill in at end)
- Changes: Fixed 9 ruff errors in rebuild_analytics.py, added pyproject.toml config
- Tests run: 47 total (42 Swift + 2 Python + 3 Rust), all passed
- Tradeoffs: Kept broad exception handling in Python for graceful fallbacks
