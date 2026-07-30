# Flow Dispatch Rules

How `flow-orchestrator` decides which agents to spawn, in what quantity, with what bias. The dynamic-dispatch principle (P2) made operational.

---

## The dispatch question

Every skill invocation routes through one decision: **how much agent capacity does this request warrant?**

Bad answers:
- "Always spawn one of each role" (the `delivery-team` failure mode)
- "Always spawn maximum agents" (token waste, Cognition's failure mode)
- "Let the LLM decide on the fly" (no principled guarantee)

Right answer: orchestrator reads complexity signals, looks up the dispatch table, applies adaptation rules from constitution + flow-state.

---

## Complexity signals (inputs to dispatch)

`flow-orchestrator` reads these signals before spawning anything:

1. **Weight class** — the effort's `weight-class` from `spec/constitution.md` (light | standard | heavy). Read FIRST: it sets the dispatch envelope (row-set, N ceiling, tier policy, depth defaults) that every other signal operates within.
2. **In-scope delta** — how many SR-{NNN} are **new, changed, or explicitly targeted in this generation** — NOT the spec's total size. A refinement generation touching 4 SRs of a 74-SR spec is a 4-SR request. Dispatching on total spec size creates a feedback loop: flow-spec and flow-eval harden the spec, the spec grows, and dispatch width silently inflates with it. The delta signal severs that loop.
3. **Spec novelty** — are the in-scope SRs additive, or do they conflict with existing patterns?
4. **Generation history** — is this gen-1 (cold start) or gen-N (refinement)?
5. **Pareto-front state** — is the front advancing or plateaued?
6. **Dissent state** — are there active dissents in scope?
7. **WIP spread** — current admission cost from `flow-state.yaml`
8. **Temperature** — exploration vs exploitation (annealing state)
9. **Constitution overrides** — explicit dispatch overrides from the effort's constitution

---

## Dispatch table (defaults)

Adapted from Anthropic's multi-agent research system explicit rules.

### Weight class → dispatch envelope

The class table is consulted first. It sets the envelope; the situation table below refines N **within standard and heavy only**. Light class uses its own row-set (plus the hotfix row, which is class-independent).

| Class | gen-1 N | gen-N refinement | Evaluator depth | Chavruta | N ceiling |
|-------|---------|------------------|-----------------|----------|-----------|
| light | 3 (cheap tier) | 1–3 | quick; standard pre-ship | explicit trigger only (see §Light path) | 5 |
| standard | 3–5 | 3 | standard; deep pre-ship | convergence checkpoint | 7 |
| heavy | 5–7 | 3–7 (situation table) | situation table | situation table | 10 |

Light keeps a **real population** — the cost cut comes from model tier and protocol envelope, not width. Three cheap-tier variants preserve three independent spec readings (the population's spec-probe value); a single variant cannot disagree with itself. See §Light path for the escalation backstop.

### `flow-generate` (population size — standard and heavy classes)

| Situation | Generators spawned | Rationale |
|-----------|--------------------|-----------|
| gen-1; 1-3 SRs; additive | **3** | Establish baseline diversity without over-spawning |
| gen-1; 4-10 SRs | **5** | Default population |
| gen-1; >10 SRs OR cross-module | **7** | More variance needed; constitution may push to 10 |
| gen-N>1; Pareto advancing | **3** | Refinement; smaller population sufficient |
| gen-N>1; Pareto plateaued | **5-7** | Need wider variant search to escape local optimum |
| gen-N>1; reheat just fired | **7-10** | Maximum exploration |
| Accessibility-bearing component | **min 7 (heavy class only)** | Constitution override (a11y dimension benefits from diversity). At light/standard: guarantee one a11y-biased variant + the a11y eval dimension instead of raising N. |
| Performance-critical path | **min 5 (heavy class only)** + chavruta on convergence | Constitution override. At light/standard: guarantee one performance-biased variant instead of raising N. |
| Hotfix / critical security | **1** | Bypass population; serialized single variant; decision ledger + ledger audit mandatory (see §Decision ledger) |

### Constraint-bias assignment

When N>1 generators spawn, each gets a different constraint bias. The orchestrator picks from this menu (rotating across generations):

| Bias | Generator prompt emphasis |
|------|---------------------------|
| `simplicity` | Prefer the smallest viable implementation. Inline over abstract. Local reasoning > global indirection. |
| `performance` | Optimize for p95 latency and throughput. Profile-driven. Accept complexity for measurable speed gains. |
| `maintainability` | Prefer composability, low coupling, named abstractions. Optimize for the next person to read this. |
| `security` | Defense in depth. Reject ambiguity at trust boundaries. Verbose audit trails. |
| `reversibility` | Additive over breaking. Feature-flag-friendly. Rollback paths explicit. |
| `convention` | Match existing codebase patterns. Minimum novelty. Boring is good. |
| `radical` | Explicitly explore an alternative paradigm. Used sparingly when temperature is high. |

Default rotation: `simplicity, performance, maintainability, security, convention` (5 biases for default N=5).

When temperature ≥ 0.6, replace one of these with `radical`. When temperature ≤ 0.2, lock to `convention + maintainability + security`.

### Per-bias model tier

Dispatch assigns a model tier per (class, bias) — width is not the only adaptive dimension. Agent frontmatter carries only a default `model:`; the Agent tool's per-call model override is the mechanism, passed at spawn time. Chosen tiers are recorded in the dispatch phase-log entry.

| Bias | light | standard | heavy |
|------|-------|----------|-------|
| convention, simplicity, reversibility | sonnet | sonnet | opus |
| maintainability, performance | sonnet | opus | opus |
| security, radical | — (security-bearing scope escalates the class) | opus | opus or fable (opt-in) |

Evaluators follow the same principle: quick/standard depth → sonnet; deep/adversarial → opus.

**Fable slots (opt-in, population-only).** The Fable pilot (`flow/fable-reassessment.md`) kept generation on opus/sonnet because a Fable refusal has no agent-layer fallback — but that caution is calibrated for single-threaded roles, where a refusal strands the whole step. A population inverts the risk: one refused variant out of N is absorbed (gen-1 var-4's outage + orchestrator recovery is the precedent), making generator slots the lowest-blast-radius Fable adoption site in the suite. Conditions:

1. Constitution opt-in: `fable-permitted-biases: [...]` under Dispatch overrides. Never a silent default.
2. A de-prescriptified generator prompt for Fable runs — the isolation contract stays verbatim (correctness property); the step-by-step implementation procedure is restated outcome-first.
3. At most one fable slot per generation initially; the Pareto front decides whether it earns more.
4. A refused/stranded fable variant is recorded as spend (Rule 5) and its slot noted in the dispatch log.

### `flow-evaluator` (depth)

| Situation | Depth |
|-----------|-------|
| Single-variant prototype run | `quick` |
| Per-variant per-generation default | `standard` |
| Pre-ship convergence checkpoint | `deep` |
| Post-major spec change | `deep` |
| Dissent reactivated | `adversarial` |
| Goodhart signal detected (score climb >30% in 1 gen) | `adversarial` |

### `flow-chavruta` (when to invoke)

| Situation | Invoke? |
|-----------|---------|
| gen-1 complete | No (no convergence yet) |
| Routine gen-N completes | No (let cull handle) |
| Convergence checkpoint approaching (convergence-score > 0.75) | **Yes** |
| Major spec change about to be applied | **Yes** |
| Metastable candidate proposed for ship | **Yes** |
| Performance-critical or security-bearing change | **Yes** (constitution override) |
| Hotfix / critical-path | No (skip; serialize and ship) |

### `flow-dissent-monitor`

Always-on. Triggered on every spec change and every commit to the working tree. Not subject to dispatch decisions.

### `flow-narrator`

Triggered automatically on:
- Every `spec.md` version increment (changelog projection)
- Every `flow-ship` invocation (audience-tiered comms)
- On-demand via `flow-pulse --comms`

Never invoked per-variant.

### `flow-context-curator`

Always available, on-demand. Invoked when:
- A generator's working context exceeds 60% of model limit
- An evaluator needs to reference >3 prior generations
- A chavruta-pair needs prior dissent context

---

## Adaptation rules

The orchestrator overlays these rules on the dispatch table. They are evaluated in order.

### Rule 1: WIP spread ceiling

If `wip-spread > 0.6`, decline new generation spawn. Surface a HITL "system is saturated; wait or cancel in-flight work" message.

### Rule 2: Temperature-driven width

```
generators_per_gen = min(class_ceiling, base_dispatch_count + floor(temperature * base_dispatch_count / 2))
```

The bonus is proportional to the base and capped by the weight class's N ceiling. At temperature 1.0: heavy base 7 → 10 (ceiling); standard base 5 → 7 (ceiling); light base 3 → 4. At temperature 0.0, the base stands unchanged (do not shrink below baseline diversity). A flat bonus (the old `+floor(temp*4)`) is wrong at small bases — it would triple a light generation.

### Rule 3: Constitution overrides

Read `spec/constitution.md`'s `Dispatch overrides` section. Apply BEFORE rule 2. Min-N overrides are **class-scoped**: they raise width only at heavy class. At light and standard they translate to guaranteed bias *presence* (the named bias occupies one of the existing slots) plus the corresponding eval dimension — never to a wider population.

### Rule 4: Dissent reactivation overrides

If `dissents-reactivated > 0` in scope of this request:
- Force chavruta invocation
- Bump evaluator depth one level
- Surface reactivated dissents to the generator's prompt (so it can address them)

### Rule 5: Budget guardrails (MANDATORY)

The constitution MUST specify both `token-budget-per-variant` and `token-budget-per-generation` (`flow-init` writes them from class defaults; a constitution missing either is an init defect — halt and surface). Observed baseline for calibration: an opus full-envelope variant costs ~400k tokens, so a 9-variant heavy generation is ~3.6M.

Three enforcement points:

1. **Admission (orchestrator, at dispatch).** Estimate spend before spawning: `Σ per-variant estimates by tier`. Write the estimate to `flow-state.yaml.spend.last-generation.estimate`. If projected spend exceeds `token-budget-per-generation` by >20%: reduce generator count to fit, OR drop evaluator depth one level, OR HITL with the choice.
2. **In-agent (generator, during the run).** The per-variant budget goes **into every generator's prompt** as a working constraint: "stay within ~{X}k tokens; if the protocol genuinely demands more, raise a `budget-pressure` flag in notes.md rather than silently expanding." At ~400k per variant, admission control alone cannot work — the envelope discipline has to live where the tokens are spent.
3. **Actuals (at generation completion).** Write `spend.last-generation.observed` with a `precision` tag naming how the figure was produced (`variant-count-x-tier-weight` floor estimate; `operator-cost` when the operator supplies `/cost` or ccusage figures; `transcript-parse` if wired). Crude is acceptable; unlabeled is not. The next dispatch reads `observed` to calibrate its estimate — without this feedback the estimates never learn, and cost invariance stays invisible in-system.

Refused, stranded, or failed variants count as spend — they consumed tokens.

### Rule 6: Cognition's constraint (P1)

**Generators write only to their own variant directory.** Orchestrator never spawns parallel agents writing to a shared path. This is hard-coded; not adjustable.

---

## Light path

Light class defaults to 3 cheap-tier generators with quick evaluator depth and no chavruta. The population is retained deliberately — it is the empirical spec probe, and the light class buys its cost reduction from tier and envelope instead of width. **Escalation is a backstop for widening further, not the primary mitigation.** The orchestrator proposes the next generation at N=5 and/or opus tier for the fork-relevant biases (HITL in preference-articulator mode; automatic in autonomous mode) when:

- Variants raise ≥2 HIGH-severity decision-ledger entries, or diverge on a decision point the eval suite cannot discriminate, or
- The evaluator finds a genuine design fork — two defensible readings of an SR producing materially different implementations, or
- The dissent monitor reactivates a dissent in scope

Security- or incident-bearing scope never dispatches light: `flow-init` auto-proposes heavy, and a light effort that grows security-bearing SRs surfaces a class-promotion HITL (never silent).

## Interpretation panel (pre-generation spec probe)

Part of the probe moves to where it is cheapest: **before implementation**. Available as `flow-spec --panel` or as a pre-dispatch step in `flow-generate` (recommended for every gen-1; cheap enough to be routine).

Spawn 3–5 cheap-tier parallel **readers** — reads only, P1-clean, ~5–8k tokens each versus ~400k per implementation. Each receives the in-scope SCN/SR slice and, without seeing the others, commits to a structured reading:

1. Its interpretation of each SR, one sentence each
2. Every decision point where the text admits ≥2 readings, and which it would pick
3. An implementation sketch — interfaces and control flow, no code

The orchestrator diffs the readings. Divergence = located spec ambiguity, routed to `flow-spec` for amendment **before any generator runs**. Convergent readings raise confidence the spec is tight. This is the same mechanism as Anthropic's parallel-readers result cited under P1: parallel intelligence feeding one decision-maker.

The panel does not replace the population — a panel predicts divergence; a population demonstrates it, including forks nobody articulates. Light class runs panel + N=3; heavy class gains the panel as a pre-filter so its expensive population argues about fewer known ambiguities.

## Decision ledger

Every generator maintains `decision-ledger.md` in its variant directory: one entry per point where the spec admitted ≥2 readings, with the reading chosen, what a reasonable implementer choosing otherwise would have produced, and a severity tag (LOW | MEDIUM | HIGH). This generalizes ad-hoc `ambiguity.md` documentation into a first-class, auditable artifact; `ambiguity.md` remains the HITL escalation flag for HIGH entries.

The evaluator audits the ledger — mandatory at deep/adversarial depth **and for any N=1 dispatch** (hotfix): for each entry, "would the eval suite detect the difference between the two readings?" A *no* is a suite-gap finding, surfaced exactly as cull findings are. On the hotfix path this is the only spec probe there is — a single variant cannot disagree with itself, so its ledger plus the audit is the analytical substitute.

## Pre-spawn hygiene

Every `/flow-generate` invocation runs a hygiene sweep against the target base branch BEFORE making the dispatch decision. The goal is to spawn each generation against a fresh, clean main — preventing the baseline-drift failure mode where flow generations accumulate against a stale baseline while upstream merges pile up.

This sweep is **not optional**; it is a precondition to dispatch. The orchestrator may surface findings as HITL items but does not bypass the sweep.

### Sweep procedure

1. **Inventory** — list all open PRs targeting the base branch:
   ```
   gh pr list --base main --limit 50 --json number,title,isDraft,headRefName,mergeable,mergeStateStatus,statusCheckRollup,reviewDecision,author
   ```
2. **Bucket each PR by CI status + author**:
   - **Renovate-bot, all checks passing** → auto-merge candidate
   - **Renovate-bot, one or more checks failing** → triage signal
   - **Renovate-bot, mergeStateStatus=DIRTY (conflict)** → wait-for-rebase; renovate auto-regenerates within ~10 min
   - **Renovate-bot, blocked by missing `workflow` OAuth scope** → tooling-fix needed (operator runs `gh auth refresh -s workflow` OR merges via UI)
   - **Human-authored** → never auto-merge; note as "in-flight, operator-owned"
   - **Draft PRs** → ignore
3. **Action per bucket**:
   - Auto-merge candidates: approve + squash-merge + delete-branch, one at a time (each merge moves main; subsequent PRs may need rebase)
   - Triage signals: see §Failing renovate PR as architecture-probe below
   - Wait-for-rebase: note in dispatch log; do not block dispatch
   - Tooling-fix: surface as HITL; do not block dispatch
   - Human-authored: do not touch; note in dispatch log
4. **Fast-forward local main** to absorb merged PRs:
   ```
   git fetch origin main && git merge --ff-only origin/main
   ```
5. **Verify post-state**: active checkout is on `main`, local HEAD matches `origin/main`, no uncommitted tracked changes.

### Failing renovate PR as architecture-probe

A renovate dependency-update PR that fails CI is **not noise** — it is automated probe data showing the codebase has a coupling to the failing version. Treat each failing renovate PR as one of three categories:

- **Maps to an existing Linear migration ticket** (e.g., a failing `astro` major-version bump while `BET-NNN: Astro X→Y migration` is filed): record a phase-log entry confirming the migration is still required. Do NOT formalize as a new dissent — the ticket already exists.
- **Architectural coupling not yet captured**: surface as a chavruta candidate at the next convergence checkpoint. Examples: a security-flagged dep bump that fails because of an API surface change that wasn't anticipated in the spec.
- **Tactical (lint/lockfile/test) failure**: note in dispatch log; operator triages separately. Not chavruta material.

The orchestrator's job is to **route**, not resolve. The triage decision (which category) is HITL when ambiguous.

### Blocking vs non-blocking conditions

| Condition | Behavior |
|---|---|
| Local main diverges from `origin/main` | **HARD HALT.** Reconcile before spawn. |
| Unmerged passing renovate PRs exist | **HARD HALT.** Merge passing PRs first; the alternative is the baseline-drift the sweep is designed to prevent. |
| Failing renovate PR exists | **SOFT** — note in dispatch.md; spawn proceeds. The failure is signal, not gate. |
| Conflict-state renovate PR exists | **SOFT** — log and proceed; renovate will rebase. |
| Workflow-scope-blocked renovate PR exists | **SOFT** — surface as HITL tooling-fix; spawn proceeds. |
| Human-authored PR in flight | **SOFT** — note in dispatch.md; spawn proceeds (the operator owns the timing). |

### Output

The sweep produces a `pre-spawn-hygiene` block in the generation's `dispatch.md`:

```markdown
## Pre-spawn hygiene sweep

**Date**: {ISO8601}
**Main HEAD pre-sweep**: {sha}
**Main HEAD post-sweep**: {sha}
**Merged during sweep**: {list of PR numbers + squash SHAs}
**Failing PRs noted**: {list with failing-check breakdown}
**Conflict PRs (renovate will rebase)**: {list}
**Workflow-scope blocked (operator)**: {list}
**Human-authored in flight (operator)**: {list}
```

### When this runs

- **Always** before `/flow-generate` (every generation spawn)
- **Optionally** on `/flow-pulse` (read-only state report) to surface drift without merging
- **NOT** during `/flow-cull`, `/flow-chavruta`, `/flow-spec`, `/flow-ship` — these operate on existing artifacts, not new spawns

### Known tooling gotchas

- **gh OAuth `workflow` scope**: PRs that modify `.github/workflows/*.yml` require the gh CLI auth to have the `workflow` scope. Without it, `gh pr merge` errors with `refusing to allow an OAuth App to create or update workflow ... without 'workflow' scope`. Fix: `gh auth refresh -s workflow` and re-run; or merge via GitHub UI.
- **Self-approval on bot PRs**: renovate-authored PRs can be approved by the operator (they are not the author). Human-authored PRs may require a different reviewer per branch protection.
- **Sequential merges drift mergeability**: merging PR-A may cause PR-B to become `CONFLICTING` if both touch the same file (e.g., `pnpm-lock.yaml`). Renovate auto-rebases within ~10 min. The sweep should not retry conflicted PRs in the same invocation.

---

## Worked examples

### Example 1: Cold-start small effort

- Request: `/flow-generate` on a fresh effort with 4 SRs, additive
- Signals: class=standard, gen=1, in-scope delta=4 (small), Pareto=empty, dissents=0, WIP=0, temp=0.3
- Decision: 5 generators with biases [simplicity, performance, maintainability, security, convention]. Evaluator depth: standard. Chavruta: no.

### Example 1b: Light-class port

- Request: `/flow-generate` on a docs-site integration port of already-working code
- Signals: class=light, gen=1, in-scope delta=6, additive, no security-bearing scope, temp=0.4
- Decision: 3 generators, all cheap tier (sonnet), with biases [convention, simplicity, reversibility]. Evaluator depth: quick. Chavruta: no. Rule 2 bonus floor(0.4×1.5)=0 → N stays 3. Per-variant budget in every generator prompt.

### Example 2: Plateaued mid-effort

- Request: `/flow-generate` after gen-3 with Pareto unchanged for 2 generations
- Signals: gen=4, SRs=12, Pareto plateaued, dissents=2, WIP=0.3, temp=auto-reheating to 0.7
- Decision: Trigger `flow-anneal` reheat first (sets temp=0.7). Then 7 generators with biases [simplicity, performance, maintainability, security, convention, radical, reversibility]. Evaluator depth: deep. Chavruta: deferred until convergence.

### Example 3: Convergence checkpoint

- Request: `/flow-converge` after gen-5; convergence-score=0.84
- Signals: Pareto stable, dissents=2, candidates clustered, metastable candidate present
- Decision: Invoke chavruta-pair. Evaluator depth: deep. Spawn 1 narrator instance to draft change projection. HITL preference-articulator mode for the ship decision.

### Example 4: Hotfix path

- Request: `/flow-generate --hotfix` for critical security issue
- Signals: explicit hotfix flag set
- Decision: **Bypass population search.** N=1 generator with security bias, evaluator depth=adversarial (single variant must pass), no chavruta. Constitution override required to permit single-variant ship.

---

## Anti-patterns

Things `flow-orchestrator` is forbidden from doing:

1. **Spawning parallel generators against the same target path** (P1 violation)
2. **Spawning more than 10 generators in one generation** (Cognition's failure-mode warning; HITL required to override)
3. **Spawning subagents from inside a subagent** (limit depth to 2; orchestrator → generator/evaluator/chavruta-pair, no further)
4. **Skipping the evaluator** for a variant that will be considered for the Pareto front
5. **Modifying flow-state.yaml from a subagent** (only orchestrator and the dedicated state-writing skills mutate state)

---

## Dispatch transparency

Every dispatch decision is logged to `flow-state.yaml.phase-log`:

```yaml
phase-log:
  - "2026-05-13T14:22:00Z dispatch: gen-4 spawn / 7 generators / biases [simp,perf,maint,sec,conv,rad,rev] / depth=deep / chavruta=deferred / reason=plateau-detected, reheat-fired"
```

Operators can audit dispatch decisions post-hoc. Dispatch rationale is itself a tunable parameter — if a pattern produces poor outcomes, the rule changes (and that change is a constitution amendment).
