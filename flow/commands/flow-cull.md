---
description: Score the current generation against multi-objective evals with a noise floor; identify Pareto-front survivors; flag gated-ship (metastable) candidates; detect Goodhart signals; cull dominated variants. The cull's close is the checkpoint — chavruta and the ship decision follow immediately.
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
  requires-context: [flow-state-model, flow-eval-protocol, flow-philosophy, flow-operating-doctrine, flow-operator-voice, vault-access]
  upstream-skills: [flow-generate]
  downstream-skills: [flow-chavruta, flow-ship]
  compatible-agents: [flow-orchestrator, flow-evaluator, flow-context-curator]
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
- `~/.claude/commands/context/flow-operating-doctrine.md`
- `~/.claude/commands/context/flow-operator-voice.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

After a generation, score all variants and identify survivors. Operates on the **Pareto front**: variants that dominate (better on at least one dimension, no worse on any) survive; dominated variants are archived. Invariant failures are hard-culled regardless of position. Scoring respects a **noise floor** — deltas within characterized grader variance (or ≤0.01 absent characterization) are ties, and saturated dimensions do not rank; the field trial showed tournaments over saturated suites ranked on instrument noise.

The cull's close is the effort's checkpoint (doctrine step 5): after the first cull, chavruta and the ship decision follow immediately — there is no separate convergence check.

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
3. **Apply the noise floor before domination is computed**:
   - A per-dimension delta within the grader's characterized variance is a **tie**. Absent characterization, deltas ≤ 0.01 are ties.
   - A **saturated dimension** (every remaining variant at or within the noise floor of the ceiling or its threshold) **does not rank** — exclude it from domination comparisons and say so in the summary.
   - A variant "dominates" only via differences that clear the floor on non-saturated dimensions.
4. For remaining variants, compute Pareto fronts:
   - **First front**: variants not dominated by any other
   - **Second front**: variants only dominated by first-front members
5. Survivor policy (per harness):
   - All first-front variants survive
   - If first-front count < 2, second-front variants also survive (avoid premature narrowing)
   - All others go to `superseded/`

### Step 5: Identify gated-ship (metastable) candidates

Per `context/flow-eval-protocol.md`:
- Stability ≥ 0.85
- Spec proximity ≥ 0.60
- On Pareto front for ≥ 2 dimensions

Surface these in `flow-state.yaml.metastable-candidates` — they qualify for a **gated ship** (partial coverage behind flags with watches armed).

### Step 6: Detect Goodhart signals and audit decision ledgers

Compare this generation's scores against any prior generation:
- Did any dimension's best score climb >30%? → Goodhart signal (bump next eval depth on that dimension to adversarial)

Harvest the population's **decision ledgers and forks** — the primary output of a probe generation. Ledger entries where variants diverged and the eval suite cannot discriminate the readings are **suite-gap findings**, routed to `/flow-eval` backlog exactly as score findings are.

### Step 7: Move dominated variants

`mv generations/gen-{N}/population/var-{i}/ generations/gen-{N}/superseded/var-{i}/` for all dominated variants. Survivors stay in `population/`.

### Step 8: Close the checkpoint

The cull's close is where the effort's decision point lives (doctrine step 5):

1. **First cull of the effort**: invoke `/flow-chavruta` on the leading survivor(s) now — paired adversarial review is the checkpoint, and it was the best value per token in the field trial. Then surface the ship decision: proceed to `/flow-ship` on named qualitative grounds, or (with named evidence only) redispatch narrow.
2. **Later culls** (evidence-driven refinement generations): chavruta again if the refinement touched a dissent's scope or security-bearing SRs; otherwise proceed to the ship decision.

Never advance to another generation as the default next step.

### Step 9: Write cull summary

Write `generations/gen-{N}/summary.md`:

```markdown
# Generation {N} cull summary

**Date**: {ISO8601}
**Variants spawned**: {count}
**Variants surviving**: {count}
**Pareto-front size**: {count}
**Invariant culls**: {count} ({variants})
**Gated-ship (metastable) candidates**: {count} ({variants})
**Saturated dimensions (excluded from ranking)**: {list or none}
**Ties under the noise floor**: {pairs, with the delta and the floor applied}

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
- Suite-gap findings from decision ledgers: 1 (SR-019 fork invisible to correctness graders — routed to /flow-eval)

## Gated-ship (metastable) candidates

- var-2: stability 0.91, spec-proximity 0.62 — could ship gated (feature-flagged early access) for SR-019 through SR-024
```

### Step 10: Update state

Write to `flow-state.yaml`:
- `pareto-front` (with sources)
- `metastable-candidates`
- `checkpoint` (see below)
- `phase-log` (append)

If the state file is at a retired schema version, migrate it first (state model
§State schema: delete retired fields, bump `schema-version`, log the migration).

**The checkpoint block is the cull close made machine-readable** — the forward-looking
gate a resuming session reads before it reads any history:

- `closed-at` / `generation`: this cull.
- `redispatch: blocked` — always, at every cull close. Evidence justifying a redispatch
  (a fired watch, an eval-blind fork, a spec delta) must be named per dispatch and is
  never carried over; `flow-generate` halts while this reads `blocked`.
- `evaluator-fleet`: `open`, or `"blocked: {blocker}"` when the cull found a structural
  instrument ceiling (a missing runner, absent harness infrastructure — anything more
  scoring cannot fix). While blocked, `flow-eval` admits only work that removes the
  blocker.
- `next`: the summary's Next section as a priority-ordered list, commands named. The
  prohibition and the priorities must live in state, not only in summary prose — a
  session that reads state and finds no gate re-derives the old machine from its own
  transcript.

### Step 11: Update context curator (heavy class only)

On heavy-class efforts, launch `~/.claude/commands/agents/flow-context-curator.md` subagent (model: sonnet) to write the compressed digest section of `generations/gen-{N}/summary.md` for future readers. Light and standard efforts skip this — under narrow flows there is little history to compress, and the trial measured ~735k tokens for one round's digests.

### Step 12: Report

Return:
- Generation number
- Survivors (count + variants + biases)
- Pareto-front shifts (with ties and saturated dimensions named as such)
- Gated-ship (metastable) candidate count
- Suite-gap findings harvested from decision ledgers
- Next-step suggestion: `/flow-chavruta` then the ship decision (`/flow-ship`) — the cull close is the checkpoint; `/flow-generate` only with named evidence

## What this skill does NOT do

- **It does not modify the variants.** Read-only with respect to implementation.
- **It does not promote any variant to working tree.** That's `/flow-ship`.
- **It does not make the ship decision.** It closes by invoking `/flow-chavruta` and surfacing the decision; `/flow-ship` owns the gate.
- **It does not change the eval suite.** That's `/flow-eval` — but suite-gap findings from ledger audits are routed there.

## Outputs

| Path | Action |
|------|--------|
| `generations/gen-{N}/population/var-{i}/eval-result.yaml` | Created (by evaluator per variant) |
| `generations/gen-{N}/superseded/var-{j}/` | Moved (dominated variants) |
| `generations/gen-{N}/summary.md` | Cull summary |
| `flow-state.yaml` | Pareto-front, metastable candidates, checkpoint block, phase-log updated |

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

### First cull of the effort

```
/flow-cull
```

Quick depth (round tier). Scores 5 variants, finds 2 survivors on first Pareto front (one pair tied under the noise floor on maintainability), archives 3 dominated. Closes by invoking `/flow-chavruta` on the leading survivor and surfacing the ship decision.

### Re-cull after suite refinement

```
/flow-cull --depth standard
```

Idempotent re-score after `/flow-eval` closed a suite gap the ledger audit found. The deep pass stays reserved for `/flow-ship`'s single pre-ship run.

### Adversarial cull after Goodhart signal

```
/flow-cull --depth adversarial
```

Active adversarial generation against current variants. Catches metric-gaming that standard depth missed.

## Operator output

Every run closes with the operator block per `context/flow-operator-voice.md` — What happened / What it means / Decisions needed / Next step, at most 150 words, suite terms glossed on every use, no naked metrics. For this skill: lead with the survivors and why, one sentence each; point the operator at generations/gen-{N}/summary.md for the narrative — never at the phase-log (audit register). 'Scored the generation and archived the beaten variants (cull)' is the framing, and the block says archived variants remain recoverable.
