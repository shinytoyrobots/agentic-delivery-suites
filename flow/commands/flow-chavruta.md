---
description: Adversarial paired review at convergence checkpoints. Two opposing-bias reviewers produce structured dissent with reactivation conditions; exits at documented disagreement, not consensus.
argument-hint: '[variant-id | "spec-change" | "metastable"]'
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
  requires-context: [flow-dissent-protocol, flow-state-model, flow-philosophy, vault-access]
  upstream-skills: [flow-converge, flow-spec]
  downstream-skills: [flow-ship, flow-dissent]
  compatible-agents: [flow-chavruta-pair, flow-orchestrator]
readiness:
  state: green
  idempotent: false
  warm-start: true
cost:
  model-class: high
  agent-count: 2
  web-calls: none
  context-budget: large
---

# Flow Chavruta

Read context files:
- `~/.claude/commands/context/flow-dissent-protocol.md`
- `~/.claude/commands/context/flow-state-model.md`
- `~/.claude/commands/context/flow-philosophy.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Invoke a structured adversarial paired review. Two reviewers (stability-bias + velocity-bias) study the same artifact and produce structured dissent objects with explicit reactivation conditions. Replaces `dt-gate-review`'s consensus-seeking adversarial PM pair with a memory-preserving alternative.

This is NOT a routine per-variant review. It is invoked at **consequential decision points**: convergence checkpoints, major spec changes, metastable-candidate ship decisions, security/performance-critical ship paths.

## When invoked

By skill chain:
- `/flow-converge` — at ship recommendation
- `/flow-spec` — on major version increment (constitution-configurable)
- `/flow-ship --metastable` — to surface partial-completion concerns

By human:
- `/flow-chavruta var-3` — review a specific variant
- `/flow-chavruta spec-change` — review the latest spec amendment
- `/flow-chavruta metastable` — review the current metastable candidate

## Procedure

### Step 1: Identify the artifact

Based on argument or invoking context:
- A variant (read `population/var-{id}/implementation/` + `constraint-bias.md`)
- A spec change (read `spec/history/spec-v{N}.md` + diff vs prior)
- A metastable candidate (read its eval-result + constraint-bias + position in Pareto)

### Step 2: Read context

- `spec/spec.md` at the relevant version
- `spec/constitution.md`
- `dissents-active.yaml` (prior dissents — may inform new ones)
- Per `agents/flow-chavruta-pair.md`: also read this generation's eval results

### Step 3: Invoke chavruta-pair

Pass:
- Artifact under review
- Spec context
- Constitution
- Prior dissents (digest, not full)

Per `agents/flow-chavruta-pair.md`, it runs:
- Stability-bias reviewer (pass 1)
- Velocity-bias reviewer (pass 2, sees pass 1)
- Identifies true disagreements (not all surface-level friction)
- Writes provisional resolutions
- Authors dissent objects with reactivation conditions

Quota: max 2 dissents per checkpoint by default. Constitution override may raise.

### Step 4: Validate dissents

For each dissent:

- Position and counterposition are internally consistent
- Reactivation conditions are precise enough to be evaluated automatically
- Conditions are testable (not "if things change") — must specify regex, shell, metric, or time

If a dissent fails validation, return it to chavruta-pair for revision.

### Step 5: Persist dissents

Append validated dissents to `efforts/{effort}/dissents-active.yaml`. Each gets:
- ID: `dissent-{YYYY-MM-DD}-{NNNN}`
- Status: `active`
- Raised-at, raised-by, generation, context
- Position, counterposition, provisional-resolution
- Reactivation conditions

Also write per-generation summary to `generations/gen-{N}/dissents/summary.md` (human-readable, for ship review).

### Step 6: Update state

Write to `flow-state.yaml`:
- `active-dissents` (incremented)
- `phase-log` (append: "chavruta completed for {artifact}, {N} new dissents")

### Step 7: Determine blocking vs non-blocking

A dissent is **blocking** if:
- The position references an invariant or constitution prohibition
- The reactivation condition is already met (the dissent fires on creation)
- HITL escalation trigger in constitution names this dissent type as blocking

Otherwise, the dissent is **non-blocking** — recorded but does not halt ship.

### Step 8: Report

Return:
- Dissents raised (count, IDs)
- Blocking vs non-blocking breakdown
- One-paragraph summary of each disagreement
- Recommendation: proceed with ship; or resolve blockers first

## What this skill does NOT do

- **It does not modify code.** Reviewers read only.
- **It does not seek consensus.** The exit condition is documented disagreement.
- **It does not invoke per-variant.** Convergence checkpoints only.
- **It does not resolve dissents.** That's `/flow-dissent`.

## Outputs

| Path | Action |
|------|--------|
| `efforts/{effort}/dissents-active.yaml` | Append new dissents |
| `efforts/{effort}/generations/gen-{N}/dissents/summary.md` | Per-generation human-readable digest |
| `efforts/{effort}/flow-state.yaml` | active-dissents incremented; phase-log appended |

## HITL surface

- Blocking dissent: prompt user to acknowledge, mitigate, or override-with-rationale
- Constitution requires HITL on this checkpoint: full dissent review before proceeding
- Quota exceeded (>2 dissents): chavruta-pair flagged; surface for review of reviewer calibration

## Failure modes

- Chavruta-pair fails to produce any dissents (both reviewers agree on everything): suspicious; rerun with deeper context; if still no dissents, log and proceed (this can be legitimate)
- Reactivation conditions can't be validated automatically (e.g., reference to undefined metric): return to pair for revision
- Cross-effort dissent reactivation triggered: surface to constitution review

## Idempotency

Not idempotent in the sense that re-running creates a new chavruta session and potentially new dissents on the same artifact. Use deliberately.

## Examples

### Convergence checkpoint

`/flow-converge` invoked `/flow-chavruta` automatically. Two reviewers studied var-2 (the ship candidate). One dissent raised: stability reviewer argues inline retry pattern is brittle if rate-limit handling is added; velocity reviewer argues middleware is premature abstraction. Provisional resolution: ship inline form. Reactivation: spec adds rate-limit requirement OR grep -rc 'withRetry' > 3.

### Major spec change

`/flow-spec --restructure` triggered chavruta. Stability reviewer concerns about migration cost; velocity reviewer concerns about staying with awkward structure. One dissent raised about migration path.

### Manual review of a specific variant

```
/flow-chavruta var-5
```

Explicit invocation. Reviews var-5 specifically (perhaps a candidate the user is considering despite being on second Pareto front).
