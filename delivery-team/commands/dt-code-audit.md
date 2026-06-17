---
description: Holistic codebase health audit — architecture, test quality, security posture, maintainability, and conventions
argument-hint: <path-or-glob> | pr <number> | codebase [--focus=architecture|tests|security|maintainability]
model: sonnet
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - Agent
  - mcp__notes__write-file
capability-class: content-review
tier: II
domain: [dt]
works-with:
  requires-context: [vault-access, dt-definition-of-done, dt-github-practices]
  upstream-skills: [dt-run, dt-efficiency-review]
  downstream-skills: [dt-start, dt-release-plan]
  compatible-agents: [dt-qa-tester, dt-backend-dev, dt-frontend-dev]
readiness:
  state: green
  idempotent: true
  warm-start: false
cost:
  model-class: medium
  agent-count: 4
  web-calls: none
  context-budget: large
---

# Code Audit

Read context files:
- `~/.claude/commands/context/vault-access.md`
- `~/.claude/commands/context/dt-definition-of-done.md`
- `~/.claude/commands/context/dt-github-practices.md`

## Purpose

Holistic codebase health assessment that complements `/dt-efficiency-review` (which focuses on performance). This skill audits the dimensions that determine whether a codebase is healthy to work in: architectural coherence, test confidence, security posture, and maintainability.

Use when:
- Starting work on an unfamiliar codebase
- Periodic health check between sprints
- Before a major refactor or architecture decision
- After a period of rapid feature work to assess accumulated debt
- Preparing for a new team member joining the project

Do NOT use when reviewing a specific story (use `/dt-story-review` + `/dt-run` QA gate) or optimizing performance (use `/dt-efficiency-review`).

## Input

`$ARGUMENTS` = one of:
- `<path-or-glob>` — audit specific files or directories
- `pr <number>` — audit changed files in a pull request plus their immediate dependents
- `codebase` — full codebase audit using code index if available
- Append `--focus=<dimension>` to run a single dimension in depth: `architecture`, `tests`, `security`, `maintainability`

If `$ARGUMENTS` is empty, default to `codebase`.

## Phase 0: Context Gathering

1. **Detect stack**: Read `package.json`, `tsconfig.json`, build config. Note framework, language version, test framework, linter config, CI pipeline.

2. **Detect scope**:
   - If `pr <number>`: `gh pr diff <number>`, `gh pr view <number> --json files`. Read full content of touched files plus files that import them (one hop).
   - If path/glob: Glob for matching files, read each.
   - If `codebase`: Use code index (`**/codebase-index*`, `**/CODEBASE.md`) if available. Otherwise scan main source directory.

3. **Gather project signals**:
   - `git log --oneline -50` — recent change velocity and patterns
   - `git log --diff-filter=M --name-only -50` — most frequently changed files (change hotspots)
   - Check for `.eslintrc*`, `.prettierrc*`, `biome.json` — linting/formatting config
   - Check for CI config (`.github/workflows/`, `.gitlab-ci.yml`, etc.)

## Phase 1: Architecture & Design

Assess structural health of the codebase.

### Module Boundaries
- **Circular dependencies** — detect import cycles between modules/directories. Use `grep -r` on import statements to build a rough dependency graph between top-level directories.
- **Boundary violations** — components importing from sibling module internals instead of public API/index. Flag cross-cutting imports that bypass module boundaries.
- **Colocation** — are related files (component, test, types, styles) colocated or scattered? Neither is wrong, but inconsistency within the same project signals drift.

### Coupling & Cohesion
- **Fan-out** — files that import from 10+ distinct modules. High fan-out = high coupling.
- **Fan-in** — files imported by many others. High fan-in = core abstractions; changes here have blast radius.
- **God modules** — files >400 lines with multiple exported functions serving different concerns.
- **Shotgun surgery signals** — check git history for files that frequently change together but live in different modules. `git log --format=format: --name-only -50 | sort | uniq -c | sort -rn | head -20` for most-changed files.

### Layering
- **Data flow direction** — do dependencies flow inward (clean architecture) or are there upward dependencies (e.g., domain importing from UI)?
- **Abstraction consistency** — are similar concerns handled at the same abstraction level? Flag mixed raw SQL alongside ORM calls, raw fetch alongside API client wrappers.

### API Surface
- **Overly broad exports** — modules exporting internals that should be private. Count exports vs actual external usage.
- **Inconsistent API patterns** — different modules using different patterns for the same concern (error handling, validation, response shaping).

## Phase 2: Test Health

Assess confidence in the test suite.

### Coverage Analysis
- Run coverage if available (`npm test -- --coverage`, `npx vitest --coverage`, etc.). If coverage tooling is not configured, note as a finding.
- **Coverage distribution** — identify untested directories and files. Flag business-critical paths with zero coverage.
- **Testing trophy shape** — ratio of unit / integration / e2e tests. Flag suites that are heavily unit-tested but lack integration tests (inverted trophy).

### Test Quality
- **Assertion density** — tests with zero or one assertion. Flag tests that only check `.not.toThrow()` or `expect(result).toBeDefined()` (coverage theater).
- **Test isolation** — shared mutable state between tests (`beforeAll` mutations, global variables). Flag test files where test order matters.
- **Mock depth** — tests that mock 3+ dependencies. Over-mocking produces false confidence.
- **Snapshot overuse** — large snapshot files, snapshots of implementation details rather than output.
- **Flakiness signals** — `.skip`, `.only`, `retry` annotations, `setTimeout` in tests, time-dependent assertions.

### Missing Test Categories
- **Error paths** — are error/failure scenarios tested, or only happy paths?
- **Edge cases** — empty inputs, boundary values, concurrent access
- **Contract tests** — if the project has API consumers, are there contract tests?

## Phase 3: Security Posture

Assess security hygiene beyond story-level checks.

### Dependency Security
- `npm audit` or equivalent — report known vulnerabilities by severity
- Check for pinned vs range versions in `package.json`. Unpinned major ranges in production dependencies = risk.
- Check `package-lock.json` / `yarn.lock` age — stale lock files miss security patches.

### Code Patterns
- **Input validation** — are external inputs (API params, query strings, form data) validated at the boundary? Check for schema validation (Zod, Joi, ajv) at route handlers.
- **SQL/NoSQL injection** — raw string interpolation in queries. Check for parameterized queries.
- **XSS vectors** — `dangerouslySetInnerHTML`, `innerHTML`, unescaped template literals in HTML output.
- **Auth/authz patterns** — are route handlers consistently protected? Check for middleware application consistency.
- **Secrets in code** — grep for API keys, tokens, passwords, connection strings. Check `.gitignore` covers `.env*`.
- **CORS configuration** — overly permissive (`*`) CORS headers.
- **Error exposure** — stack traces, internal paths, or database errors returned in API responses.

### Supply Chain
- **Post-install scripts** — check `package.json` for `postinstall` scripts that execute arbitrary code.
- **Dependency count** — flag unusually high dependency counts for the project scope.

## Phase 4: Maintainability & DX

Assess how easy the codebase is to work in.

### Onboarding Friction
- **README completeness** — setup instructions, architecture overview, contribution guide. Missing or outdated README is the #1 onboarding blocker.
- **Environment setup** — are required env vars documented? Is there a `.env.example`?
- **Build complexity** — how many steps from clone to running? Flag undocumented prerequisites.

### Consistency
- **Linter/formatter enforcement** — is there a linter config? Is it enforced in CI? Check for `.eslintrc*` + CI step.
- **Pattern consistency** — are similar problems solved the same way across the codebase? Flag divergent patterns for the same concern (multiple HTTP clients, multiple state management approaches, multiple form handling patterns).
- **Naming conventions** — mixed casing styles, inconsistent file naming, divergent component patterns.

### Change Amplification
- **Config duplication** — same values defined in multiple places (ports, URLs, feature flags).
- **Copy-paste code** — near-duplicate functions or components. Run heuristic detection on functions >10 lines.
- **Missing abstractions** — 3+ files doing the same multi-step operation inline instead of through a shared utility.

### Debt Signals
- **TODO/FIXME/HACK inventory** — `grep -rn 'TODO\|FIXME\|HACK\|XXX\|TEMP\|WORKAROUND'` with file and line. Classify by age using `git blame`.
- **Deprecated API usage** — framework APIs marked for removal in the next major version.
- **Dead feature flags** — flags that are always on/off with no conditional paths.

## Scoring

Score each dimension 0-10:

### Architecture (Phase 1) — 0-10
| Score | Criteria |
|-------|----------|
| 0-3 | Circular dependencies, god modules, no clear boundaries, high coupling |
| 4-6 | Some boundary violations, moderate coupling, mostly coherent structure |
| 7-10 | Clean module boundaries, consistent layering, low coupling, clear API surfaces |

### Test Health (Phase 2) — 0-10
| Score | Criteria |
|-------|----------|
| 0-3 | Low coverage, coverage theater, no integration tests, flaky tests |
| 4-6 | Moderate coverage, some quality issues, gaps in error path testing |
| 7-10 | Strong coverage, good trophy shape, high assertion quality, isolated tests |

### Security (Phase 3) — 0-10
| Score | Criteria |
|-------|----------|
| 0-3 | Known vulnerabilities, missing input validation, secrets in code, no auth consistency |
| 4-6 | Some unpatched deps, partial validation, mostly secure patterns |
| 7-10 | Clean audit, consistent validation, no secrets, enforced auth, tight CORS |

### Maintainability (Phase 4) — 0-10
| Score | Criteria |
|-------|----------|
| 0-3 | No docs, inconsistent patterns, high duplication, many TODOs, broken DX |
| 4-6 | Partial docs, some inconsistency, moderate debt, functional DX |
| 7-10 | Complete docs, consistent patterns, low duplication, clean DX, enforced linting |

**Total: 0-40.** Interpretation:
- 0-10: Critical health debt — structural improvements needed before feature work
- 11-20: Moderate — targeted improvements alongside feature work
- 21-30: Healthy — minor refinements, standard maintenance
- 31-40: Excellent — well-maintained, low friction codebase

### Architecture-drift trigger

If the Architecture score (Phase 1) is ≤ 4 OR the audit surfaces ≥ 3 module-boundary violations, append to the Improvement Plan a recommendation: "Run `/dt-architect` against the current codebase to produce a fresh-eyes architecture proposal. Compare to actual structure to scope a targeted refactor with explicit ADRs." The audit itself does not auto-invoke dt-architect — the recommendation is for the human reviewer to act on.

## Output Format

```markdown
# Code Audit: {scope}
**Generated**: {YYYY-MM-DD HH:MM}
**Skill**: /dt-code-audit
**Stack**: {detected stack summary}
**Scope**: {files audited count, lines of code estimate}
**Data freshness**: Code as of {commit hash or "current working tree"}
---

## Health Score: {N}/40
**Architecture**: {n}/10 | **Tests**: {n}/10 | **Security**: {n}/10 | **Maintainability**: {n}/10

## Critical Findings
{Findings that need immediate attention — security vulnerabilities, broken tests, architectural violations that block work}

## Improvement Plan
{Top 10 prioritized improvements, each with:}
- **Finding**: {description}
- **Dimension**: {Architecture|Tests|Security|Maintainability}
- **Severity**: {Critical|High|Medium|Low}
- **Effort**: {S|M|L|XL}
- **Location**: {file:line or pattern description}
- **Recommendation**: {specific action}

## Architecture Assessment
{Module boundary analysis, coupling hotspots, layering observations}

## Test Health Assessment
{Coverage summary, trophy shape, quality findings, missing categories}

## Security Assessment
{Vulnerability summary, pattern findings, supply chain observations}

## Maintainability Assessment
{DX friction points, consistency findings, debt inventory}

## Change Hotspots
{Top 10 most-frequently-changed files with coupling analysis — these are where investment in quality pays off most}

## Quick Wins
{Top 5 changes with highest impact-to-effort ratio, each actionable in <30 minutes}

## Methodology
Four-dimension audit: Architecture → Test Health → Security → Maintainability. Scored 0-40. Complements /dt-efficiency-review (performance-focused) — run both for a complete picture.
```

## Execution Strategy

Phase 0 runs sequentially to gather context. Then launch 4 parallel sonnet subagents:
1. **Architecture agent** — Phase 1 (import analysis, coupling, boundaries)
2. **Test health agent** — Phase 2 (coverage, quality, missing categories)
3. **Security agent** — Phase 3 (audit, patterns, supply chain)
4. **Maintainability agent** — Phase 4 (DX, consistency, debt signals)

Each agent returns structured findings with scores. Main skill synthesizes, resolves cross-cutting findings (e.g., a missing test is both a test health and security issue), deduplicates, and produces the final scored report.

When `--focus=<dimension>` is set, run only that agent at greater depth instead of all four in parallel.

## Persistence

Write output to vault:
- **Path**: `docs/Delivery-Team/{date}/dt-code-audit-{scope}.md`
- Use local vault write when available
- Fallback to `mcp__notes__write-file`

## HITL Checkpoints

None — this is an advisory skill. Findings are recommendations, not gates. Critical security findings should be flagged prominently but do not block automatically.

## Chaining

After audit, suggest based on findings:
- Security vulnerabilities found → "Run `npm audit fix` and review the changes, then re-run `/dt-code-audit --focus=security`"
- Architecture issues → "Consider creating improvement stories with `/dt-start` for the next sprint"
- Test gaps → "Run `/dt-efficiency-review` for the performance dimension, then prioritize test improvements"
- For a complete codebase picture → "Run `/dt-efficiency-review codebase` for the performance complement to this health audit"
