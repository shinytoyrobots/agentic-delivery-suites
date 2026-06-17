---
description: Check convergence — Pareto-front stability + inter-variant similarity. Either advance to next generation or trigger chavruta + ship preparation.
argument-hint: "[--force-ship | --force-iterate]"
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
capability-class: review
tier: II
domain: [flow]
works-with:
  requires-context: [flow-state-model, flow-eval-protocol, flow-philosophy, flow-dispatch-rules, vault-access]
  upstream-skills: [flow-cull]
  downstream-skills: [flow-chavruta, flow-ship, flow-generate]
  compatible-agents: [flow-orchestrator, flow-evaluator]
readiness:
  state: green
  idempotent: true
  warm-start: true
cost:
  model-class: high
  agent-count: 1
  web-calls: none
  context-budget: medium
---

# Flow Converge

Read context files:
- `~/.claude/commands/context/flow-state-model.md`
- `~/.claude/commands/context/flow-eval-protocol.md`
- `~/.claude/commands/context/flow-philosophy.md`
- `~/.claude/commands/context/flow-dispatch-rules.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Read the current generation's Pareto front and decide: **advance** (run another generation) or **ship** (promote a survivor / metastable candidate to production). Convergence is the exit condition (P5); there is no calendar-based ending.

## Convergence criteria

A generation is **converged** when:

1. `convergence-score ≥ ship-threshold` (default 0.85; configurable per effort)
2. Pareto front has been stable for ≥ 2 generations (no dimension's best variant has changed)
3. All in-scope SR-{NNN} have a passing variant on the Pareto front
4. No active invariant failures across the Pareto front
5. No `generations-since-progress >= 5` (auto-failure signal if true)

Alternative: a **metastable candidate** may be promoted even if convergence isn't full, when:
- Constitution permits metastable shipping
- The candidate's stability ≥ 0.90
- Reversibility is high (rollback path clear)
- HITL preference-articulator approves

## Procedure

### Step 1: Read state

- `flow-state.yaml`
- `generations/gen-{N}/summary.md`
- `generations/gen-{N}/population/var-*/eval-result.yaml`
- `dissents-active.yaml` (any reactivated dissents in scope?)
- `spec/spec.md` (final consistency check)

### Step 2: Compute convergence-score

Per harness.yaml. Default formula:

```
convergence_score = 0.4 * pareto_front_stability
                  + 0.3 * spec_proximity
                  + 0.2 * weighted_score
                  + 0.1 * invariant_pass_rate
```

Where:
- `pareto_front_stability`: fraction of front members unchanged vs prior generation
- `spec_proximity`: fraction of SR-{NNN} with passing variant on Pareto front
- `weighted_score`: weighted-scalar of front's best per-dimension scores (Goodhart-aware: cap at 0.95 to prevent gaming)
- `invariant_pass_rate`: fraction of front members passing all INV-*

### Step 3: Classify outcome

Three possibilities:

| Convergence | Action |
|-------------|--------|
| `convergence_score >= ship_threshold` AND stability criteria met | **Ship** path |
| `convergence_score >= 0.60` AND metastable candidate present AND constitution permits | **Metastable ship** path |
| Otherwise | **Iterate** path |

### Step 4a: Ship path

If shipping:

1. Identify the recommended survivor variant (highest weighted scalar on the Pareto front)
2. Invoke `flow-chavruta` for convergence-checkpoint adversarial review
3. After chavruta returns:
   - If dissents raised: surface them; HITL preference-articulator if any are blocking
   - If no blocking dissents: proceed to `flow-ship`
4. Mark the variant for ship; suggest `/flow-ship` as next step

### Step 4b: Metastable path

If shipping a metastable candidate:

1. Identify the candidate with highest stability
2. Invoke `flow-chavruta` with focus on partial-completion concerns
3. HITL preference-articulator: confirm metastable ship is intentional, note which SRs are deferred
4. Update `flow-state.yaml`: track which SRs are deferred to future generations
5. Suggest `/flow-ship --metastable` as next step

### Step 4c: Iterate path

If iterating:

1. Determine if reheat is warranted (temperature controller may have already fired)
2. Update `flow-state.yaml.dispatch.generators-per-gen-current` based on temperature
3. Suggest `/flow-generate` as next step

### Step 5: Update state

Write to `flow-state.yaml`:
- `convergence-score` (just computed)
- `status` field: still `in-flight` if iterating; transitions to `converged` only at ship
- `phase-log` (append decision rationale)

### Step 6: Report

Return:
- Convergence-score (with breakdown of components)
- Recommendation (ship / metastable-ship / iterate)
- If shipping: recommended variant + chavruta result summary
- If iterating: temperature, projected next-generation dispatch
- Next-step skill suggestion

## Force flags

`--force-ship` — promote a variant even if convergence criteria aren't met. **Requires HITL preference-articulator explicit approval.** Logged with full rationale.

`--force-iterate` — refuse to ship even if convergence criteria ARE met. Used when the user has external information (a pending requirement, a market signal) that demands more exploration.

Both flags are honored but recorded as constitution-deviation events.

## What this skill does NOT do

- **It does not modify the working tree.** That's `/flow-ship`.
- **It does not write code.** Read-only.
- **It does not change the eval suite.** That's `/flow-eval`.
- **It does not raise dissents.** It invokes `/flow-chavruta` which does.

## Outputs

| Path | Action |
|------|--------|
| `flow-state.yaml` | convergence-score + status updated |
| `generations/gen-{N}/convergence-decision.md` | Decision record (rationale, recommendation) |

## HITL surface

- Ship recommended but blocking dissents from chavruta: prompt for resolution
- Metastable ship: explicit approval with deferred SRs disclosed
- `--force-ship` or `--force-iterate`: explicit approval required
- Convergence-score above ship threshold but spec_proximity < 1.0: surface deferred SRs, confirm acceptable
- Auto-failure signal (`generations-since-progress >= 5`): halt and surface; suggest constitution review or spec restructure

## Failure modes

- All variants on Pareto front fail invariants: halt; suggest invariant grader review or spec amendment
- Convergence has been stalled for 5+ generations with no progress: halt with auto-failure HITL
- Chavruta produces 3+ new dissents at checkpoint: defer ship; surface dissents for resolution first

## Idempotency

Idempotent. Re-running produces the same decision unless underlying state has changed (new generation, dissent resolved, etc.).

## Examples

### Standard convergence check after cull

```
/flow-converge
```

Convergence-score is 0.62 — below ship threshold. Recommends iteration. Suggests `/flow-generate` next.

### Convergence reached

```
/flow-converge
```

Convergence-score is 0.87. Invokes chavruta. Chavruta returns 1 non-blocking dissent. Recommends ship. Suggests `/flow-ship var-2`.

### Metastable candidate available

```
/flow-converge
```

Convergence-score is 0.74 (below threshold) but a metastable candidate is present with stability 0.91. Recommends metastable ship for the subset of SRs covered, deferral of the rest. HITL approval gate.

### Force ship (with explicit approval)

```
/flow-converge --force-ship
```

HITL gate: yes/no. On approval, proceeds despite low convergence. Logged as deviation.
