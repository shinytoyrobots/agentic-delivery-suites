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

1. **Spec scope** — how many SR-{NNN} does this request touch?
2. **Spec novelty** — are the SRs additive, or do they conflict with existing patterns?
3. **Generation history** — is this gen-1 (cold start) or gen-N (refinement)?
4. **Pareto-front state** — is the front advancing or plateaued?
5. **Dissent state** — are there active dissents in scope?
6. **WIP spread** — current admission cost from `flow-state.yaml`
7. **Temperature** — exploration vs exploitation (annealing state)
8. **Constitution overrides** — explicit dispatch overrides from the effort's constitution

---

## Dispatch table (defaults)

Adapted from Anthropic's multi-agent research system explicit rules.

### `flow-generate` (population size)

| Situation | Generators spawned | Rationale |
|-----------|--------------------|-----------|
| gen-1; 1-3 SRs; additive | **3** | Establish baseline diversity without over-spawning |
| gen-1; 4-10 SRs | **5** | Default population |
| gen-1; >10 SRs OR cross-module | **7** | More variance needed; constitution may push to 10 |
| gen-N>1; Pareto advancing | **3** | Refinement; smaller population sufficient |
| gen-N>1; Pareto plateaued | **5-7** | Need wider variant search to escape local optimum |
| gen-N>1; reheat just fired | **7-10** | Maximum exploration |
| Accessibility-bearing component | **min 7** | Constitution override (a11y dimension benefits from diversity) |
| Performance-critical path | **min 5** + chavruta on convergence | Constitution override |
| Hotfix / critical security | **1** | Bypass population; serialized single variant |

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
generators_per_gen = base_dispatch_count + floor(temperature * 4)
```

At temperature 1.0, default N=5 becomes N=9. At temperature 0.0, default N=5 stays N=5 (do not shrink below baseline diversity).

### Rule 3: Constitution overrides

Read `spec/constitution.md`'s `Dispatch overrides` section. Apply BEFORE rule 2.

### Rule 4: Dissent reactivation overrides

If `dissents-reactivated > 0` in scope of this request:
- Force chavruta invocation
- Bump evaluator depth one level
- Surface reactivated dissents to the generator's prompt (so it can address them)

### Rule 5: Budget guardrails

Constitution may specify `token-budget-per-generation`. Orchestrator estimates spend before spawning. If projected spend exceeds budget by >20%:
- Reduce generator count to fit budget OR
- Drop evaluator depth one level OR
- HITL with the choice

### Rule 6: Cognition's constraint (P1)

**Generators write only to their own variant directory.** Orchestrator never spawns parallel agents writing to a shared path. This is hard-coded; not adjustable.

---

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
- Signals: gen=1, SRs=4 (small), Pareto=empty, dissents=0, WIP=0, temp=0.3
- Decision: 5 generators with biases [simplicity, performance, maintainability, security, convention]. Evaluator depth: standard. Chavruta: no.

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
