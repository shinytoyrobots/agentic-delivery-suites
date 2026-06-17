---
description: Score the current generation against multi-objective evals; identify Pareto-front survivors; flag metastable candidates; detect Goodhart signals; cull dominated variants.
argument-hint: "[--depth quick|standard|deep|adversarial]"
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
capability-class: review
tier: II
domain: [flow]
works-with:
  requires-context: [flow-state-model, flow-eval-protocol, flow-philosophy, vault-access]
  upstream-skills: [flow-generate]
  downstream-skills: [flow-converge, flow-chavruta]
  compatible-agents: [flow-orchestrator, flow-evaluator, flow-temperature-controller]
readiness:
  state: green
  idempotent: true
  warm-start: true
cost:
  model-class: high
  agent-count: variable
  web-calls: none
  context-budget: large
---

# Flow Cull

Read context files:
- `~/.claude/commands/context/flow-state-model.md`
- `~/.claude/commands/context/flow-eval-protocol.md`
- `~/.claude/commands/context/flow-philosophy.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

After a generation, score all variants and identify survivors. Replaces `dt-qa-tester`'s pass/fail gate. Operates on the **Pareto front**: variants that dominate (better on at least one dimension, no worse on any) survive; dominated variants are archived. Invariant failures are hard-culled regardless of position.

## Procedure

### Step 1: Read state

- `flow-state.yaml` (current generation)
- `generations/gen-{N}/population/var-*/` — all variants
- `evals/harness.yaml` (suite configuration)
- `spec/spec.md` (current spec for variant evaluation context)

### Step 2: Determine eval depth

Per `--depth` flag or `flow-state.yaml.dispatch.evaluator-depth`. Orchestrator may bump depth if Goodhart signal was detected in prior generation.

### Step 3: Run evaluator per variant (in parallel)

For each `var-{i}` in the generation:

Launch `~/.claude/commands/agents/flow-evaluator.md` subagent (model: opus, one per variant in parallel) with:
- Variant path
- Spec version
- Depth
- Eval suite version

Evaluator returns:
- `eval-result.yaml` written to `population/var-{i}/`
- Per-dimension scores
- Invariant pass/fail
- Goodhart signal (if any)
- Metastable assessment

These run in parallel — one Agent call per variant.

### Step 4: Compute Pareto fronts

After all evaluations complete:

1. Read all `eval-result.yaml` files
2. **Invariant cull**: any variant failing any INV-* is removed from Pareto consideration entirely. Tag in cull summary.
3. For remaining variants, compute Pareto fronts:
   - **First front**: variants not dominated by any other
   - **Second front**: variants only dominated by first-front members
4. Survivor policy (per harness):
   - All first-front variants survive
   - If first-front count < 2, second-front variants also survive (avoid premature convergence)
   - All others go to `superseded/`

### Step 5: Identify metastable candidates

Per `context/flow-eval-protocol.md`:
- Stability ≥ 0.85
- Spec proximity ≥ 0.60
- On Pareto front for ≥ 2 dimensions

Surface these in `flow-state.yaml.metastable-candidates`.

### Step 6: Detect Goodhart and trend signals

Compare this generation's Pareto front against prior generation's:
- Did any dimension's best score climb >30%? → Goodhart signal
- Did the Pareto front advance (any dimension improved without others regressing)? → progress signal
- Did the front stagnate? → plateau signal

These signals feed `flow-temperature-controller` (invoked next).

### Step 7: Move dominated variants

`mv generations/gen-{N}/population/var-{i}/ generations/gen-{N}/superseded/var-{i}/` for all dominated variants. Survivors stay in `population/`.

### Step 8: Update temperature

Launch `~/.claude/commands/agents/flow-temperature-controller.md` subagent (model: sonnet). It reads:
- Trend signals from this cull
- `generations-since-progress` counter
- Constitution reheat triggers

It returns:
- New temperature
- Reheat events triggered (if any)

### Step 9: Write cull summary

Write `generations/gen-{N}/summary.md`:

```markdown
# Generation {N} cull summary

**Date**: {ISO8601}
**Variants spawned**: {count}
**Variants surviving**: {count}
**Pareto-front size**: {count}
**Invariant culls**: {count} ({variants})
**Metastable candidates**: {count} ({variants})

## Survivors and Pareto positions

| Variant | Bias | Front | Dimensions where best |
|---------|------|-------|----------------------|
| var-2 | simplicity | 1st | correctness, accessibility, security |
| var-5 | performance | 1st | performance |
| var-1 | maintainability | 2nd | maintainability |

## Pareto front shifts vs gen-{N-1}

| Dimension | Prior best | Current best | Delta |
|-----------|------------|--------------|-------|
| correctness | 0.91 | 0.94 | +0.03 |
| performance | 0.78 | 0.81 | +0.03 |
| ...

## Signals

- Goodhart signal: none
- Progress signal: rising (Pareto front advanced)
- Plateau signal: none
- Temperature change: 0.45 → 0.40 (default cooling)
- Reheat events: none

## Metastable candidates

- var-2: stability 0.91, spec-proximity 0.62 — could ship as feature-flagged early access for SR-019 through SR-024
```

### Step 10: Update state

Write to `flow-state.yaml`:
- `pareto-front` (with sources)
- `metastable-candidates`
- `temperature` (from controller)
- `convergence-score` (computed from Pareto-front stability vs prior gen)
- `generations-since-progress` (incremented or reset)
- `phase-log` (append)

### Step 11: Update context curator

Launch `~/.claude/commands/agents/flow-context-curator.md` subagent (model: sonnet) to write the compressed `generations/gen-{N}/summary.md` for future generators to read instead of raw artifacts.

### Step 12: Report

Return:
- Generation number
- Survivors (count + variants + biases)
- Pareto-front shifts
- Temperature change
- Metastable candidate count
- Next-step suggestion: `/flow-converge` if convergence-score is approaching threshold; `/flow-generate` if more iteration is warranted

## What this skill does NOT do

- **It does not modify the variants.** Read-only with respect to implementation.
- **It does not promote any variant to working tree.** That's `/flow-converge` + `/flow-ship`.
- **It does not invoke chavruta.** That's `/flow-chavruta`, called at convergence checkpoints.
- **It does not change the eval suite.** That's `/flow-eval`.

## Outputs

| Path | Action |
|------|--------|
| `generations/gen-{N}/population/var-{i}/eval-result.yaml` | Created (by evaluator per variant) |
| `generations/gen-{N}/superseded/var-{j}/` | Moved (dominated variants) |
| `generations/gen-{N}/summary.md` | Cull summary |
| `flow-state.yaml` | Pareto-front, metastable, temperature, phase-log updated |

## HITL surface

- Goodhart signal detected: surface for human inspection of evaluator at next cull
- Invariant cull rate > 30% of generation: likely spec/evaluator issue, surface for review
- All variants culled (zero survivors): halt and surface critical failure

## Failure modes

- Evaluator returns error for one or more variants: variant marked `eval-failed`; if >50% of generation fails to eval, halt and surface
- Pareto computation fails (mathematical degeneracy): fall back to weighted-scalar ranking with explicit notice in summary

## Idempotency

`flow-cull` is **idempotent** — re-running on a generation that has already been culled produces the same result. Useful for re-eval after eval-suite refinement.

## Examples

### Standard cull after generate

```
/flow-cull
```

Default depth. Scores 5 variants, finds 2 survivors on first Pareto front, archives 3 dominated. Temperature stays at 0.4. Suggests `/flow-generate` for next iteration.

### Deep cull at convergence checkpoint

```
/flow-cull --depth deep
```

5x re-sample on stochastic graders. Extended LLM-judge passes. Use before invoking `/flow-chavruta` for convergence decision.

### Adversarial cull after Goodhart signal

```
/flow-cull --depth adversarial
```

Active adversarial generation against current variants. Catches metric-gaming that standard depth missed.
