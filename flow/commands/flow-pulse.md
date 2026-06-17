---
description: Read-only state report. Convergence, Pareto front, temperature, WIP spread, active dissents, generation history. Replaces dt-status. No sprint velocity.
argument-hint: "[--comms | --verbose | --json]"
model: sonnet
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
capability-class: review
tier: III
domain: [flow]
works-with:
  requires-context: [flow-state-model, flow-philosophy, vault-access]
  upstream-skills: []
  downstream-skills: []
  compatible-agents: []
readiness:
  state: green
  idempotent: true
  warm-start: true
cost:
  model-class: low
  agent-count: 0
  web-calls: none
  context-budget: small
---

# Flow Pulse

Read context files:
- `~/.claude/commands/context/flow-state-model.md`
- `~/.claude/commands/context/flow-philosophy.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Read-only state report. Human-readable summary of the effort's current state. The single skill for "what's going on?" Replaces `dt-status` with `flow`-native vocabulary: convergence-score and Pareto front, not sprint progress and velocity.

## Modes

### Default

Single-screen summary. Convergence, Pareto front, active dissents, temperature, WIP, recent activity.

### `--verbose`

Full detail. All Pareto front per-dimension scores, all active dissents with full positions, full phase-log tail, all metastable candidates with rationale.

### `--comms`

Show comms artifacts state. Last narrator outputs (changelog version, sponsor comms generated, support doc state).

### `--json`

Emit state as JSON for programmatic consumption.

## Procedure

### Step 1: Read state

- `flow-state.yaml`
- `efforts/{effort}/dissents-active.yaml`
- `generations/gen-{N}/summary.md` (current generation)
- Last 10 entries of `flow-state.yaml.phase-log`
- If `--comms`: `efforts/{effort}/shipped/comms/` directory

### Step 2: Compute derived views

- **Convergence trajectory**: convergence-score across last 5 generations
- **Pareto trend**: which dimensions are advancing vs flat vs regressing
- **Dissent health**: noisy count, stale count, high-signal count
- **Temperature history**: last reheat event, current temperature, cooling trajectory
- **WIP**: current admission cost; agents in-flight

### Step 3: Format output

Default format:

```
═══════════════════════════════════════════════════════════
  flow pulse — effort: {effort-slug}
  generation {N} | status: {status} | spec: v{spec-version}
═══════════════════════════════════════════════════════════

CONVERGENCE
  score:        0.62  ─ rising ↗
  threshold:    0.85  (ship)
  trajectory:   gen-1: 0.31  gen-2: 0.48  gen-3: 0.55  gen-4: 0.62
  spec-prox:    14 of 19 SRs have passing variant on front

PARETO FRONT (best variant per dimension)
  correctness:    0.94  var-2 (simplicity)        ↗ +0.03 vs gen-3
  performance:    0.81  var-5 (performance)       ↗ +0.03
  maintainability:0.78  var-1 (maintainability)   →
  accessibility:  1.00  var-2                      →
  security:       0.92  var-2                      ↗ +0.02
  cost:           0.55  var-3 (convention)        ↘ -0.04

  Metastable candidates: 1
    └ var-2 — stability 0.91, spec-proximity 0.62, reversibility high

TEMPERATURE  current: 0.40
  trajectory: 0.50 → 0.45 → 0.45 → 0.40 (default cooling)
  reheats: none in this effort
  triggers armed: eval-plateau, architectural-blocker, debt-spike, dissent-cluster

WIP SPREAD  current admission cost: 0.12
  in-flight:    generators: 0   evaluators: 0   chavruta: 0
  saturation:   1/6 (healthy)

DISSENTS  active: 4   reactivated: 1   noisy: 0
  └ dissent-2026-05-13-0001 (reactivated) — inline retry vs middleware
    trigger: 'grep -rc withRetry' = 4 (threshold > 3)
    awaiting: acknowledgment | mitigation | resolution

HITL  mode: preference-articulator   pending: 1
  └ var-2 — ambiguity flag on SR-019 interpretation

RECENT ACTIVITY (last 5 phase-log entries)
  2026-05-13T14:22  dispatch: gen-4 spawn / 5 generators / depth=standard
  2026-05-13T15:30  cull: 2 survivors of 5; pareto advance on correctness, perf, sec
  2026-05-13T15:31  temperature: 0.45 → 0.40 (default cooling)
  2026-05-13T15:35  dissent reactivated: dissent-2026-05-13-0001
  2026-05-13T16:00  pulse query (this command)

SUGGESTED NEXT
  • Resolve reactivated dissent (/flow-dissent acknowledge or mitigate)
  • Continue iteration (/flow-generate) — 0.23 below ship threshold
  • Consider metastable ship for SRs 1-14 (/flow-converge --metastable)

═══════════════════════════════════════════════════════════
```

### Step 4: Return

The formatted output. No state changes.

## What this skill does NOT do

- **It does not modify any state.** Pure read.
- **It does not invoke other agents.** Reads files only.
- **It does not trigger reactivation checks.** Use `/flow-dissent --check` for that.
- **It does not regenerate comms artifacts.** Use `/flow-spec` or `/flow-ship` for that.

## Outputs

None persisted. Returns formatted text to the user.

## HITL surface

None — pure read.

## Failure modes

- No active effort: report "no active effort; use `/flow-init` to create one"
- Multiple active efforts and no argument: list candidates; suggest specifying
- `flow-state.yaml` corrupt or missing: report and suggest recovery

## Idempotency

Fully idempotent. Read-only.

## Examples

### Default pulse

```
/flow-pulse
```

Shows current state at-a-glance.

### Verbose audit

```
/flow-pulse --verbose
```

Full detail including all Pareto front scores, all dissent positions, full phase-log tail.

### Check comms state before a release announcement

```
/flow-pulse --comms
```

Shows: last spec version's comms generated, which audiences have artifacts, last update timestamps.

### Pipe state into another tool

```
/flow-pulse --json | jq '.pareto-front'
```

Machine-readable output for scripting.
