# AGENTS.md

## A) Purpose
- This is the agent operating manual for this repo. It is the single source of truth for how work MUST be planned, executed, tested, and finalized.
- WHY MEMORY EXISTS: Agents need durable, repo-wide working memory to avoid re-discovering facts and to keep decisions consistent. MEMORY.md is the concise, evergreen record of repo structure, working commands, architecture boundaries, conventions, pitfalls, and key decisions.
- PLAN.md, TODO.md, and MEMORY.md are different and MUST be kept distinct:
  - PLAN.md = short-lived, per-task plan (context, options, steps, tests, risks, memory impact). Updated before/during/after the task.
  - TODO.md = actionable checklist with definitions of done. Updated continuously during execution.
  - MEMORY.md = durable project knowledge and decisions. Not a plan and not a TODO list.

## B) Required workflow (the contract)

### Start-of-task checklist
- MUST read: AGENTS.md, MEMORY.md (if it exists), PLAN.md (if it exists), TODO.md (if it exists).
- MUST confirm scope, constraints, and success criteria before coding.
- If MEMORY.md is missing: MUST create it before coding (unless explicitly forbidden by the task). If creation is forbidden, record "MEMORY.md missing" in PLAN.md and TODO.md and create it at the earliest allowed moment.
- If PLAN.md or TODO.md is missing: MUST create it before coding.

### Memory step (MEMORY.md requirements)
- MUST be concise, factual, and evergreen.
- MUST include stable repo knowledge (structure, commands that work, boundaries, conventions, pitfalls, decisions).
- MUST NOT include secrets, tokens, credentials, personal data, or private URLs.
- MUST update MEMORY.md when:
  - new working commands are discovered
  - architectural boundaries or conventions are learned/changed
  - a meaningful decision/tradeoff is made

### Planning step (PLAN.md requirements)
PLAN.md MUST include:
- Context, assumptions, constraints
- At least 2 approach options considered, plus the chosen approach and why
- Step-by-step execution plan
- Test plan (what tests will be added/updated and how they fail before/pass after)
- Risks and rollback
- Memory impact (what should be added/updated in MEMORY.md)

### TODO step (TODO.md requirements)
TODO.md MUST include:
- Small, verifiable tasks with explicit definition of done for each
- Links to relevant files/paths where possible
- A specific "Memory update" task when new durable knowledge is learned
- Status updates as work progresses (in-progress/done)

### Execution step (implementation and commit discipline)
- MUST follow existing architecture, naming, layering, and patterns.
- MUST keep changes minimal, correct, and production-ready.
- MUST NOT leave partial features, placeholders, TODOs, or temporary fallbacks.
- MUST handle errors explicitly; do not swallow exceptions or fail silently.
- SHOULD keep outputs deterministic where possible.
- Commits MUST be small and reviewable.
- Commits MUST NOT include failing tests.
- Commit messages MUST describe intent and scope.

### Validation step (quality gates)
- MUST run all relevant format, lint, typecheck, and test commands for the affected stack(s).
- MUST ensure no new warnings or build failures.
- MUST update docs when public behavior changes.
- If a required gate does not exist, add a TODO to create it.

### Close-out step
- MUST update PLAN.md with final notes (what changed, tests run, tradeoffs).
- MUST ensure TODO.md is fully checked off.
- MUST update MEMORY.md if new durable knowledge or decisions were created.
- MUST confirm no placeholders/TODOs remain in code.

## C) Plan/TODO/MEMORY templates (copy-paste ready)

### PLAN.md template
```markdown
# Plan

## Context
- <what/why>

## Assumptions
- <assumption 1>

## Constraints
- <constraint 1>

## Options considered
1) <option 1>
2) <option 2>
Chosen: <option> because <reason>

## Execution plan
1. <step 1>
2. <step 2>

## Test plan
- <test to add or update>

## Risks and rollback
- <risk> -> <rollback>

## Memory impact
- <what should be added to MEMORY.md>

## Notes / Results (fill in at end)
- Changes:
- Tests run:
- Tradeoffs:
```

### TODO.md template
```markdown
# TODO

## Tasks
- [ ] <task> (DoD: <explicit definition of done>)
- [ ] <task> (DoD: <explicit definition of done>)
- [ ] Memory update: <what to record> (DoD: MEMORY.md updated)

## In progress
- [ ] <task>

## Done
- [x] <task>
```

### MEMORY.md template
```markdown
# MEMORY

## Repo overview (languages/frameworks)
- <summary>

## Commands
- Setup/install: <command(s) that work>
- Format: <command(s) that work>
- Lint: <command(s) that work>
- Typecheck: <command(s) that work>
- Tests: <command(s) that work>

## Architecture notes
- <boundaries, layering, key modules>

## Conventions
- <naming, error handling, logging>

## Known pitfalls / sharp edges
- <pitfall>

## Decision log
- YYYY-MM-DD: <decision> (links: <file paths>)
```

### Example (condensed)
```markdown
# PLAN.md (example)
## Context
- Add a guard when analytics.json is missing to avoid a crash.
## Assumptions
- Missing analytics is recoverable by rebuilding Output/analytics.
## Constraints
- Do not change Output/ schema.
## Options considered
1) Throw and show error banner only.
2) Auto-trigger rebuild and show status.
Chosen: 2 because it keeps UX smooth while preserving explicit errors.
## Execution plan
1. Add guard + status in AnalyticsStore.
2. Add unit test for missing file path.
3. Update docs for new behavior.
## Test plan
- Add XCTest that fails when analytics.json is absent.
## Risks and rollback
- Risk: rebuild loop -> rollback to error-only path.
## Memory impact
- Record analytics rebuild command and new behavior.

# TODO.md (example)
- [ ] Add guard in AnalyticsStore (DoD: missing file does not crash)
- [ ] Add XCTest for missing analytics.json (DoD: test fails before, passes after)
- [ ] Update docs (DoD: README mention of behavior)
- [ ] Memory update: analytics behavior + commands (DoD: MEMORY.md updated)
```

## D) Testing policy
- Meaningful tests MUST assert behavior, not implementation details.
- Tests MUST fail before the change and pass after.
- Prefer unit tests; add integration tests when behavior spans modules or IO boundaries.
- Bug fixes MUST include a reproduction test for the bug.
- Flaky tests MUST be fixed at the root cause; do not skip or ignore them.
- Record new or verified test commands in MEMORY.md.

## E) Coding and architecture standards
- Follow existing patterns first; do not invent new layering or naming without justification.
- Respect dependency boundaries; no hidden coupling or duplicated logic.
- Error handling MUST be explicit and observable (no silent failures).
- Logging MUST be purposeful and not leak secrets or PII.
- Performance: avoid obvious slow paths; measure if uncertain.
- Security: never add secrets; sanitize inputs where relevant.
- Record repo-wide conventions or changes in MEMORY.md.

## F) Definition of Done
- TODO.md is fully checked off.
- PLAN.md updated with final notes and tests run.
- All relevant format/lint/typecheck/tests are green.
- Public behavior changes are documented.
- No placeholders, TODOs, or temporary fallbacks remain.
- MEMORY.md was reviewed at start, and updated if any durable knowledge/decision emerged.
- MEMORY.md contains no secrets or private data.

## G) Repo-specific integration

### Stacks detected
- Swift (SwiftPM): app code in `Sources/`, tests in `Tests/`.
- Python (analytics): code and tests in `analytics/`.
- Rust: `analytics/ffi` (FFI library). The former standalone `analytics/rust` CLI is not part of the current tree.
- CI: `.github/workflows/ci.yml` runs `cargo build --manifest-path analytics/ffi/Cargo.toml --release` and `swift test`.

### Commands found in this repo

Setup/install:
- Swift build: `swift build`
- Rust FFI build: `cargo build --manifest-path analytics/ffi/Cargo.toml --release`
- Python env + deps: `uv sync --project analytics --extra dev --frozen` (managed environment: `analytics/.venv`)

Format:
- Python: `analytics/.venv/bin/python -m ruff format --check analytics scripts`
- Rust: `cargo fmt --manifest-path analytics/ffi/Cargo.toml --check`
- No Swift formatter is configured; choose and document one before making formatting a required gate.

Lint:
- Python lint (configured): `analytics/.venv/bin/python -m ruff check analytics scripts`
- Rust lint (configured): `cargo clippy --locked --manifest-path analytics/ffi/Cargo.toml --all-targets --all-features -- -D warnings`
- Swift warnings are enforced with `swift test -Xswiftc -warnings-as-errors`; no separate Swift linter is configured.

Typecheck/build:
- Swift: `swift build`
- Rust: `cargo build --manifest-path analytics/ffi/Cargo.toml --release`
- No Python type checker configured.
- TODO to add: choose and document a type checker (e.g., mypy or pyright).

Tests:
- Swift: `swift test`
- Python: `analytics/.venv/bin/python -m pytest analytics/tests`
- Python unittest fallback: `analytics/.venv/bin/python -m unittest discover -s analytics/tests`
- Rust FFI: `cargo test --manifest-path analytics/ffi/Cargo.toml`

Integration/verification commands:
- Analytics rebuild: `analytics/.venv/bin/python analytics/rebuild_analytics.py`
- Rust FFI verification: `cargo test --manifest-path analytics/ffi/Cargo.toml`

### Required follow-up for missing gates
- If format/lint/typecheck commands remain missing, add tasks to TODO.md to introduce and document them, then record final commands in MEMORY.md.
