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
  requires-context: [flow-state-model, flow-philosophy, flow-operator-voice, vault-access]
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
- `~/.claude/commands/context/flow-operator-voice.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Read-only state report. The single skill for "what's going on?" — and the flagship operator surface of the suite. The default output is a **plain-English dashboard** written per `flow-operator-voice.md`: it answers *where this stands, what's blocking ship, and what needs you*, in that order, one screen, jargon glossed on every use, no naked metrics. The dense per-dimension view lives behind `--verbose`.

## Modes

### Default

One-screen plain-English dashboard: where this stands / what's blocking ship / what needs you. Every suite term carries its plain-phrase gloss; every metric carries its correct reading.

### `--verbose`

Full detail in suite vocabulary. All Pareto front per-dimension scores, all active dissents with full positions, full phase-log tail, all metastable candidates with rationale. This is the operator opting into the dense register.

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

Default format — plain-English dashboard per `flow-operator-voice.md`. Structure and register shown here; content derives from state:

```
flow pulse — {effort-slug} · generation {N} · spec v{spec-version}

WHERE THIS STANDS
  Four generations in, and the population is settling: how settled it
  is (convergence-score) reads 0.62 against a ship line of 0.85, and it
  has risen every generation. 14 of the spec's 19 requirements now have
  a passing variant among the ones still worth keeping (the Pareto
  front). One variant — var-2 — is stable and shippable but doesn't
  cover the full spec yet (a metastable candidate): it could go out
  early behind a feature flag.

WHAT'S BLOCKING SHIP
  1. A recorded disagreement's trigger condition fired (dissent
     reactivation): the inline-retry-vs-middleware dispute from gen-1
     re-armed because inline retry callsites hit 4 (its threshold was
     3). It needs acknowledging, mitigating, or resolving.
  2. Cost is the one dimension moving the wrong way (0.55, down 0.04) —
     the best variants are getting more expensive to run.

WHAT NEEDS YOU  (one decision each — answer in any order)
  1. The reactivated disagreement above → /flow-dissent
  2. var-2 flagged a judgment call the spec left open (decision ledger,
     SR-019) → one interpretation ships; say which.

NEXT
  /flow-dissent first — the disagreement gates the convergence
  checkpoint; generation can continue after (/flow-generate).

Detail: --verbose for scores per dimension · gen summary at
generations/gen-4/summary.md
```

Rules applied above, mandatory in every rendering:
- Suite terms carry their plain-phrase gloss on **every** use, not the first
- No naked metrics — every number carries its correct reading
- "WHAT NEEDS YOU" lists one decision per item, each pointing at its own prompt/command
- Deep narrative pointer goes to `summary.md`, never to the phase-log (audit register)

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
