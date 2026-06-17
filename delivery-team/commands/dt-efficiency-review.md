---
description: Code efficiency review — multi-pass analysis of runtime, memory, bundle, structural, and cognitive efficiency for JS/TS codebases and PRs
argument-hint: <path-or-glob> | pr <number> | codebase [--strict|--lenient]
model: sonnet
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - mcp__notes__write-file
capability-class: content-review
tier: II
domain: [dt]
works-with: {requires-context: [vault-access], upstream-skills: [dt-run], downstream-skills: [dt-release-plan]}
readiness: {state: green, idempotent: true}
cost: {model-class: medium, agent-count: 3, context-budget: large}
---

# Code Efficiency Review

Read context files:
- `~/.claude/commands/context/vault-access.md`

## Purpose

Multi-pass efficiency review for JavaScript/TypeScript code. Analyzes runtime performance, memory efficiency, bundle/load impact, structural waste, and cognitive complexity. Produces a scored assessment with findings classified by the Lean 7 Wastes taxonomy, ranked by consequence severity.

Operates in three modes: targeted file/directory review, PR diff review, or full codebase scan.

## Input

`$ARGUMENTS` = one of:
- `<path-or-glob>` — review specific files or directories (e.g., `src/components/`, `src/**/*.ts`)
- `pr <number>` — review a pull request diff (requires GitHub CLI)
- `codebase` — full codebase scan using code index if available, otherwise key directories
- Append `--strict` for tighter thresholds (competitive/performance-critical code)
- Append `--lenient` for relaxed thresholds (prototypes, internal tools)

If `$ARGUMENTS` is empty, default to `codebase`.

## Phase 0: Context Gathering

Before running passes, collect project context:

1. **Detect stack**: Read `package.json` for dependencies. Note:
   - React version and whether `react-compiler-runtime` is present (React Compiler enabled)
   - Next.js version (App Router vs Pages Router affects SSR patterns)
   - TypeScript config: read `tsconfig.json` for `strict`, `target`, `module` settings
   - Build tool: Vite, webpack, esbuild, turbopack
   - Test framework: Jest, Vitest, Playwright

2. **Detect mode**:
   - If `pr <number>`: run `gh pr diff <number>` to get the diff, `gh pr view <number> --json files` for touched files list. Read full content of each touched file.
   - If path/glob: Glob for matching files, read each.
   - If `codebase`: Look for a code index file (Glob for `**/codebase-index*`, `**/CODEBASE.md`). If found, use it. Otherwise, scan `src/` or the main source directory.

3. **Set thresholds** based on flag:

| Metric | Lenient | Default | Strict |
|--------|---------|---------|--------|
| Cognitive complexity | 25 | 15 | 10 |
| Function length (lines) | 150 | 100 | 50 |
| Bundle size budget (KB) | 500 | 250 | 100 |
| Max sequential awaits | 5 | 3 | 2 |

## Phase 1: Runtime Efficiency Pass

Check for patterns that degrade V8 optimization and runtime performance.

### V8 Deoptimization Patterns
- **`delete` operator on objects** — forces dictionary mode. Suggest: set to `undefined` or use object destructuring to omit.
- **Adding properties after object construction** — breaks hidden class sharing. Suggest: initialize all properties in constructor/literal.
- **Sparse arrays** (holes from `new Array(n)` without fill, or `delete arr[i]`) — forces dictionary mode. Suggest: `Array.from()` or `.fill()`.
- **Polymorphic function arguments** — functions called with different types across call sites. Note when detected but don't over-flag (medium confidence).
- **`try-catch` wrapping entire function bodies** — prevents TurboFan optimization. Suggest: wrap only the throwing code.
- **`arguments` object usage** — disables scope optimizations. Suggest: rest parameters (`...args`).

### Async Anti-Patterns
- **Sequential `await` on independent operations** — detect 2+ sequential `await` calls where results don't depend on each other. Suggest: `Promise.all()`.
- **`await` inside `for`/`forEach`/`while` loops** on independent items — suggest: `Promise.all(items.map(...))`.
- **Missing `Promise.allSettled`** where partial failure is acceptable — note when `Promise.all` is used but individual failures are caught inside.

### Main Thread / Rendering
- **Long synchronous operations** (>50ms threshold) — flag compute-heavy functions without yielding. Suggest: `scheduler.yield()` or `setTimeout(fn, 0)` pattern.
- **Layout thrashing** — reading layout properties (`offsetWidth`, `offsetHeight`, `getBoundingClientRect`, `scrollTop`, `clientHeight`) immediately after writing styles. Suggest: batch reads before writes.
- **Animating layout-triggering CSS properties** (`width`, `height`, `top`, `left`, `margin`) — suggest: `transform` and `opacity`.
- **Scroll/resize listeners without throttle/debounce** — suggest: `IntersectionObserver`, `ResizeObserver`, or `requestAnimationFrame`-based throttle.
- **`setInterval` for animation** — suggest: `requestAnimationFrame`.

### React-Specific (if React detected)
- If React Compiler IS enabled: flag unnecessary manual `useMemo`/`useCallback`/`React.memo` as redundant overhead.
- If React Compiler is NOT enabled: flag missing memoization on expensive computations and components receiving stable props.
- **Inline functions/objects in JSX** — creates new references every render, breaks memoization.
- **Array index as list key** — causes incorrect reconciliation on reorder/delete.
- **Large unvirtualized lists** (>50 items) — suggest: `react-window` or `@tanstack/virtual`.
- **Context API with frequently-changing values** — suggest: split contexts or use Zustand/Jotai.
- **Missing `useTransition`/`useDeferredValue`** for heavy state updates (React 18+).

### Node.js-Specific (if Node detected)
- **Sync file ops** (`readFileSync`) outside init — use async equivalents.
- **Buffering large files** — use `stream.pipeline()` with backpressure.
- **CPU-bound work on main loop** — use Worker Threads.
- **Missing cluster mode** — note for HTTP servers.

## Phase 2: Memory Efficiency Pass

### Leak Patterns
- **Event listeners without cleanup** — missing `removeEventListener` at teardown. React: `useEffect` without cleanup return.
- **`setInterval`/`setTimeout` without clear** — timers not cleared on unmount/teardown.
- **Detached DOM references** — variables holding removed DOM nodes.
- **Closures capturing large objects** — long-lived callbacks closing over large datasets.
- **Unbounded caches/Maps** — no size limit or eviction. Suggest: `WeakMap` or LRU cache.

### Allocation Patterns
- **Object creation in hot loops** — pre-allocate or reuse instead.
- **String concatenation in loops** — `+=` in loops. Suggest: `Array.join()`.
- **Spreading large arrays/objects** — `{...largeObj}` when mutation or reference would suffice.

## Phase 3: Bundle & Load Efficiency Pass

### Import Patterns
- **Barrel file imports** — importing from `index.ts` re-export files. Check for `export * from` patterns. Suggest: direct path imports.
- **`import *` (namespace imports)** — imports entire module. Suggest: named imports for tree shaking.
- **Dynamic `import()` missing for heavy components** — large components loaded eagerly that could be lazy. Check for React.lazy() / dynamic import opportunities.
- **CommonJS `require()` in ESM codebase** — prevents tree shaking. Suggest: ESM `import`.

### Dependency Weight
Check `package.json` for heavy deps with native/lighter alternatives:
- `moment` (67KB) → `date-fns`, `Temporal`, `Intl.DateTimeFormat`
- `lodash` full (72KB) → native ES2024+ (`Object.groupBy`, `structuredClone`), `es-toolkit`
- `axios` (13KB) → native `fetch` (Node 18+), `ky` (4KB)
- `uuid` → `crypto.randomUUID()` (native Node 14.17+)
- `classnames` → `clsx` (1KB); `querystring` → `URLSearchParams`; `isomorphic-fetch` → native `fetch`

### TypeScript Config
- `target` below `ES2020` — generates unnecessary polyfills
- `module` not `ESNext` — may prevent bundler tree shaking
- `strict: false` or missing — reduced type safety, harder static analysis
- `noUnusedLocals: false` — dead code not caught at compile time

### Build Config
- Missing `sideEffects: false` in `package.json` for library packages
- No code splitting configured (single bundle for multi-route app)
- Missing bundle size budget enforcement (`size-limit` or `bundlesize`)

## Phase 4: Structural Efficiency Pass

### Dead Code
- **Unused exports** — functions/types exported but never imported. Note: suggest running `knip` for comprehensive detection.
- **Unreachable code** after return/throw/break statements.
- **Commented-out code blocks** — not dead code detection per se, but a maintenance signal.
- **Unused variables/parameters** — should be caught by `noUnusedLocals`/`noUnusedParameters` if enabled.

### Abstraction Overhead
- **Wrapper-of-wrapper patterns** — functions that do nothing but call another function with the same arguments.
- **Over-abstracted utilities** — single-use abstractions that add indirection without reuse.
- **Excessive HOC chains** (React) — suggest: hooks or composition instead.
- **God objects/modules** — single files handling too many concerns (flag files >300 lines with multiple exported functions serving different purposes).

### Data Flow
- **Prop drilling** through 3+ levels — suggest: Context or state management.
- **Redundant state** — state derived from other state that could be computed. `useMemo` for derived values, not `useState` + `useEffect`.
- **N+1 patterns** — loops that make individual API/DB calls instead of batching.

If ≥3 abstraction-overhead or god-object findings, append: "Recommend `/dt-architect` — likely architectural."

## Phase 5: Cognitive Efficiency Pass

### Complexity Metrics
- **Cognitive complexity** — estimate using SonarQube rules: +1 for each flow-breaking construct (if, for, while, switch, catch, ternary), +nesting level bonus for nested structures, +1 per logical operator type change. Flag functions exceeding the threshold.
- **Function length** — flag functions exceeding the line count threshold.
- **Nesting depth** — flag nesting deeper than 4 levels.
- **Parameter count** — flag functions with >4 parameters. Suggest: options object.

### Readability Patterns
- **Clever over clear** — bitwise operations for non-performance-critical code, obscure ternary chains, regex without comments for complex patterns.
- **Inconsistent naming** — mixed conventions (camelCase/snake_case) within the same module.
- **Magic numbers/strings** — hardcoded values without named constants.

### Tradeoff Detection
When a finding in Passes 1-4 (runtime efficiency) conflicts with cognitive efficiency, surface the tradeoff explicitly:
- "This optimization improves runtime by [X] but increases cognitive complexity from [Y] to [Z]. Consider whether the performance gain justifies the maintenance cost."

## Waste Classification

Classify each finding using the Lean 7 Wastes taxonomy:

| Waste Type | Code Manifestation |
|------------|-------------------|
| **Overproduction** | Dead code, unused exports, over-engineered abstractions |
| **Over-processing** | Unnecessary re-renders, redundant transforms, premature optimization |
| **Waiting** | Synchronous blocking, sequential awaits on independent ops, unthrottled I/O |
| **Inventory** | Stale caches, unbounded maps, accumulated tech debt |
| **Transportation** | Unnecessary data copying, excessive serialization, prop drilling |
| **Motion** | Excessive indirection, wrapper-of-wrapper, unnecessary abstraction layers |
| **Defects** | Memory leaks, V8 deoptimizations, incorrect async patterns |

## Scoring

Score each dimension 0-10:

### Runtime (Pass 1) — 0-10
| Score | Criteria |
|-------|----------|
| 0-3 | V8 deoptimization patterns, sequential awaits, layout thrashing, no yielding |
| 4-6 | Some async issues, minor rendering concerns, mostly optimized |
| 7-10 | Clean async patterns, no deopt triggers, proper yielding and throttling |

### Memory (Pass 2) — 0-10
| Score | Criteria |
|-------|----------|
| 0-3 | Multiple leak patterns, unbounded caches, allocation in hot loops |
| 4-6 | Minor leak risks, some unnecessary allocation, mostly clean |
| 7-10 | Proper cleanup, bounded caches, allocation-aware hot paths |

### Bundle (Pass 3) — 0-10
| Score | Criteria |
|-------|----------|
| 0-3 | Heavy deprecated deps, barrel files, no code splitting, CJS in ESM |
| 4-6 | Some heavy deps, partial splitting, minor import issues |
| 7-10 | Lean deps, proper splitting, ESM throughout, tree-shaking optimized |

### Structure (Pass 4) — 0-10
| Score | Criteria |
|-------|----------|
| 0-3 | Significant dead code, deep abstraction layers, god objects, N+1 patterns |
| 4-6 | Some unused code, minor abstraction overhead, mostly modular |
| 7-10 | No dead code, clean module boundaries, efficient data flow |

### Cognitive (Pass 5) — 0-10
| Score | Criteria |
|-------|----------|
| 0-3 | High complexity scores, deep nesting, magic numbers, clever code |
| 4-6 | Some complex functions, moderate nesting, mostly readable |
| 7-10 | Low complexity, clear naming, well-structured, self-documenting |

**Total: 0-50.** Interpretation:
- 0-15: Critical efficiency debt — immediate attention needed
- 16-30: Moderate — targeted improvements recommended
- 31-40: Good — minor refinements available
- 41-50: Excellent — well-optimized codebase

## Output Format

```markdown
# Efficiency Review: {scope}
**Generated**: {YYYY-MM-DD HH:MM}
**Skill**: /dt-efficiency-review
**Stack**: {detected stack summary}
**Threshold**: {strict|default|lenient}
**Data freshness**: Code as of {commit hash or "current working tree"}
---

## Score: {N}/50
**Runtime**: {n}/10 | **Memory**: {n}/10 | **Bundle**: {n}/10 | **Structure**: {n}/10 | **Cognitive**: {n}/10

## Critical Findings
{Findings ranked by consequence severity. Each finding includes:}
- **Issue**: {description}
- **Waste type**: {Lean waste classification}
- **Location**: {file:line or pattern description}
- **Impact**: {estimated severity — Critical/High/Medium/Low}
- **Fix**: {specific recommendation with code example if helpful}

## Quick Wins
{Top 5 changes with highest impact-to-effort ratio, each actionable in <15 minutes}

## Recommendations
{Medium-effort improvements, grouped by pass}

## Observations
{Lower-priority findings and tradeoff callouts}

## Dependency Audit
{If heavy deps found: table of current → recommended with size savings}

## Tooling Recommendations
{CI tools: ESLint plugins, bundle budgets, automated checks}

## Methodology
Five-pass: Runtime → Memory → Bundle → Structural → Cognitive. Lean 7 Wastes classification. Scored 0-50. Thresholds: {level used}
```

## Execution Strategy

Phase 0 sequential, then 3 parallel haiku agents: Passes 1-2 (Runtime+Memory), Pass 3 (Bundle), Passes 4-5 (Structure+Cognitive). Main skill synthesizes and scores. PR mode: touched files + dependents. Codebase mode: hot paths first.

## Persistence

Write output to vault:
- **Path**: `docs/Delivery-Team/{date}/dt-efficiency-review-{scope}.md`
- Use local vault write when available
- Fallback to `mcp__notes__write-file`
