# Flow State Model

How `flow` represents the world. Every skill reads from and writes to artifacts conforming to this model.

---

## Top-level directory layout

```
project-root/
  spec/                          # Version-controlled. Source of truth.
    spec.md                      # EARS-formatted executable spec
    constitution.md              # Governance: prohibitions, preferences, escalation
    history/                     # Append-only spec evolution log
      spec-v{semver}-{date}.md
  evals/                         # Version-controlled. Multi-objective eval suite.
    datasets/
      {dimension}-real.jsonl     # Real-world tasks (20-50 per dimension)
      {dimension}-adversarial.jsonl  # Adversarial holdouts (Goodhart mitigation)
    graders/
      {dimension}.md             # Grader specification per objective dimension
    harness.yaml                 # Eval runner configuration; thresholds
  efforts/                       # GITIGNORED. Working artifacts.
    {effort-slug}/
      flow-state.yaml            # Current effort state (see §State schema)
      generations/
        gen-{N}/
          population/
            {variant-id}/        # One directory per generated variant
              implementation/    # Variant code (does not touch main tree)
              constraint-bias.md # The bias this variant was generated under
              eval-result.yaml   # Multi-dimensional scores
          summary.md             # Cull decision rationale
        gen-{N+1}/
          ...
      dissents-active.yaml       # CROSS-GENERATION dissents w/ reactivation conditions
      shipped/                   # Variants promoted to production
        ship-{date}-{semver}.md  # Ship record
        post-ship-eval/          # Continuous eval running in production
```

**Version control rules**:
- `spec/`, `evals/`, and `efforts/{effort-slug}/dissents-active.yaml` and `efforts/{effort-slug}/shipped/` are committed.
- `efforts/{effort-slug}/flow-state.yaml` and `efforts/{effort-slug}/generations/` are gitignored. These are working artifacts.
- The project's `.gitignore` should include: `efforts/*/flow-state.yaml`, `efforts/*/generations/`.

**Effort resolution**:
1. Explicit argument (user passes effort slug).
2. `flow.yaml` at project root with `active-efforts: [...]`. If exactly one is active, use it.
3. Branch fallback: `git branch --show-current`, slugified.
4. Ambiguity: list candidates and ask.

---

## State schema — `flow-state.yaml`

```yaml
schema-version: "1.0"
effort: customer-portal-rewrite        # kebab-case slug
created: "2026-05-13"
current-generation: 4
status: in-flight                       # in-flight | converged | shipped | abandoned

# Convergence state
convergence-score: 0.62                 # 0..1; threshold for ship is configurable, default 0.85
convergence-trend: rising               # rising | flat | falling
generations-since-progress: 0           # Reheat trigger fires at 3+

# Temperature (exploration ↔ exploitation)
temperature: 0.4                        # 0..1; 1.0=full explore, 0.0=full exploit
temperature-floor: 0.1                  # Never go below this; preserves variance
last-reheat: null                       # ISO datetime of last reheat event
reheat-triggers-armed:
  - eval-plateau-detected
  - architectural-blocker
  - debt-signal-spike

# WIP pricing (market-maker spread)
wip-spread: 0.12                        # admission cost for new work, 0..1
wip-in-flight:
  generators: 3
  evaluators: 1
  chavruta-pairs: 0
wip-spread-formula: "0.05 * generators + 0.10 * chavruta_pairs + 0.02 * evaluators"

# Pareto front (best score per dimension across surviving variants)
pareto-front:
  correctness: 0.94
  performance: 0.81
  maintainability: 0.78
  accessibility: 1.0
  security: 0.92
  cost: 0.55                            # token / compute cost; 1.0 = under budget
pareto-front-source:
  correctness: "gen-4/population/var-2"
  performance: "gen-4/population/var-5"
  maintainability: "gen-3/population/var-1"
  accessibility: "gen-4/population/var-2"
  security: "gen-4/population/var-2"
  cost: "gen-2/population/var-3"

# Metastable candidates (stable intermediate states)
metastable-candidates:
  - variant: "gen-3/population/var-1"
    stability: 0.91                     # how immovable from this state
    spec-proximity: 0.62                # how close to final spec
    reversibility: high                 # high | medium | low
    blast-radius: low                   # low | medium | high

# Active dissents (cross-generation memory)
active-dissents: 4
dissents-reactivated: 1                 # In the current generation
last-dissent-check: "2026-05-13T14:22:00Z"

# HITL mode (function, not gate level)
hitl-mode: preference-articulator       # preference-articulator | comprehension-auditor | reactivation-watch | autonomous
hitl-pending: 0                         # Count of items awaiting human input

# Dispatch state
dispatch:
  orchestrator-policy: complexity-adaptive  # Always; do not change
  generators-per-gen-default: 5
  generators-per-gen-current: 5         # Adjusted by orchestrator per request
  evaluator-depth: standard             # quick | standard | deep | adversarial
  chavruta-on-convergence: true         # invoke chavruta when converging
  chavruta-on-major-spec-change: true   # invoke chavruta when spec.md changes >20%

# Audit
last-update: "2026-05-13T14:22:00Z"
updated-by: flow-orchestrator
phase-log:                              # Append-only event log
  - "2026-05-13T09:00:00Z gen-3 culled, survivors: 2 of 5"
  - "2026-05-13T11:30:00Z chavruta-pair completed, 2 new dissents recorded"
  - "2026-05-13T14:22:00Z gen-4 spawned, generators: 3, temperature: 0.4"
```

---

## Eval result schema — `eval-result.yaml`

One per variant per generation.

```yaml
variant: "gen-4/population/var-2"
generation: 4
constraint-bias: simplicity              # The bias this variant was generated under
generated-at: "2026-05-13T12:00:00Z"
evaluator-version: "1.2.0"

scores:                                  # Per-dimension; 0..1
  correctness:
    score: 0.94
    grader: "graders/correctness.md@v1.2"
    dataset-used: ["real:correctness-real-v3", "adversarial:correctness-adv-v1"]
    failures: 3                          # Out of 50 tasks
    failure-details: "evals-failures/var-2-correctness.md"
  performance:
    score: 0.81
    grader: "graders/performance.md@v1.0"
    p95-latency-ms: 142
    p99-latency-ms: 380
  maintainability:
    score: 0.62
    grader: "graders/maintainability.md@v1.1"
    cyclomatic-complexity-p95: 12
    coupling-score: 0.4
  accessibility:
    score: 1.0
    grader: "graders/accessibility.md@v1.0"
    axe-violations: 0
  security:
    score: 0.92
    grader: "graders/security.md@v1.0"
    high-severity: 0
    medium-severity: 1
  cost:
    score: 0.71
    tokens-to-generate: 24500
    tokens-to-evaluate: 8200

pareto-position:                         # Computed by flow-cull
  dominated-by: []                       # Variants that strictly dominate this one
  dominates: ["var-3", "var-5"]          # Variants this strictly dominates
  on-pareto-front: true                  # In this generation's Pareto front
  pareto-rank: 1                         # 1 = front; 2 = second-front; etc.

metastable-assessment:                   # From flow-evaluator metastable detection
  is-metastable-candidate: false
  stability: 0.74
  spec-proximity: 0.81
  rationale: "Implements core requirements but deferred two enhancement ACs"
```

---

## Dissent object schema — entry in `dissents-active.yaml`

```yaml
- id: "dissent-2026-05-13-0001"
  raised-at: "2026-05-13T11:30:00Z"
  raised-by: "flow-chavruta-pair / stability-bias"
  generation: 4
  context: "gen-4 convergence checkpoint"
  position: |
    The simplicity-bias variant (var-2) eliminates the retry middleware
    in favor of inline retry logic. The stability-bias reviewer argues
    this breaks isolation: if a future requirement adds rate-limit
    handling, every callsite must be updated, not one middleware.
  counterposition: |
    The velocity-bias reviewer argues middleware adds indirection for a
    use case that may not materialize. The inline form is testable and
    locally reasoned.
  provisional-resolution: "Accept inline form for this effort."
  reactivation-conditions:
    - type: spec-change
      trigger: "spec.md adds requirement related to rate-limiting"
      match: "spec.md contains 'rate limit' OR 'throttle' (case-insensitive)"
    - type: code-change
      trigger: "Inline retry callsites exceed 3"
      match: "grep -c 'withRetry' src/ > 3"
    - type: time
      trigger: "Re-evaluate at every major spec version"
      match: "spec semver major increment"
  status: active                         # active | reactivated | acknowledged | resolved
  last-checked: "2026-05-13T14:22:00Z"
```

When a reactivation condition matches, `flow-dissent-monitor` sets `status: reactivated` and surfaces the dissent in `flow-pulse` output. The human (or `flow-orchestrator`) must `acknowledge` (accept the trade-off remains valid), `mitigate` (modify the code to address the dissent), or `resolve` (formally retire the dissent).

---

## Spec history — `spec/history/`

Every change to `spec/spec.md` writes a snapshot. Naming: `spec-v{major}.{minor}.{patch}-{YYYY-MM-DD}.md`.

```yaml
# Front matter of each history file
---
version: "1.4.0"
parent: "1.3.2"
changed-at: "2026-05-13"
change-type: minor                       # major | minor | patch | restructure
change-summary: "Added rate-limit AC and 429 response handling"
diff-summary: |
  + AC-7: Rate-limit responses return HTTP 429 with Retry-After header
  + AC-8: Burst tolerance is configurable per tenant
  ~ AC-3: Updated to specify max retry count of 3
---
```

`flow-spec-writer` writes these. `flow-narrator` reads them to generate audience-tiered comms.

---

## Constitution — `spec/constitution.md`

Governance rules for the effort. Author-once-update-rarely. Read by every agent.

```markdown
# Constitution — customer-portal-rewrite

## Prohibitions
- No PII in logs.
- No client-side state for billing operations.
- No new direct database access from frontend.

## Preferences (soft)
- Prefer composition over inheritance.
- Prefer feature flags over branch coupling.
- Prefer additive spec changes over restructures.

## Escalation triggers (HITL surface)
- Spec change requires deprecating a public API → preference-articulator mode
- Two consecutive generations fail to advance Pareto front → comprehension-auditor mode
- Dissent reactivated 3+ times across efforts → preference-articulator mode

## Dispatch overrides
- Performance-critical paths → always invoke chavruta on convergence
- Accessibility-bearing components → minimum N=7 generators
- Token-cost dimension always present in eval Pareto

## Violation policy
- This constitution may be amended via `flow-spec`. Amendments are versioned.
- Skill invocations that violate this constitution halt and surface a dissent.
```

---

## Reading and writing

| Skill / Agent | Reads | Writes |
|---------------|-------|--------|
| `flow-init` | (none required) | `spec/spec.md`, `spec/constitution.md`, `evals/harness.yaml`, `flow-state.yaml` |
| `flow-spec` | `spec/spec.md`, `spec/history/` | `spec/spec.md`, `spec/history/spec-v{N}.md` |
| `flow-eval` | `evals/` | `evals/datasets/`, `evals/graders/`, `evals/harness.yaml` |
| `flow-generate` | `spec/`, `flow-state.yaml`, prior `generations/` | `generations/gen-{N}/population/{var}/` |
| `flow-cull` | `generations/gen-{N}/population/`, `eval-result.yaml` files | `flow-state.yaml`, `generations/gen-{N}/summary.md` |
| `flow-converge` | `flow-state.yaml`, `generations/gen-{N}/` | `flow-state.yaml` |
| `flow-chavruta` | converging variants, `spec/`, prior `dissents-active.yaml` | `dissents-active.yaml` (append), `generations/gen-{N}/dissents/` |
| `flow-dissent` | `dissents-active.yaml`, recent commits | `dissents-active.yaml` (status field updates) |
| `flow-pulse` | `flow-state.yaml`, `dissents-active.yaml` | (read-only) |
| `flow-anneal` | `flow-state.yaml`, eval-trend signals | `flow-state.yaml` (temperature, reheat fields) |
| `flow-ship` | shipped variant, `spec/history/` | `shipped/`, optional Linear/GitHub mirror |

**Writes outside this map are violations.** Agents must not write to artifacts they are not authorized for.
