---
description: Read-only state report and resume aid. Pareto front, ship-gate status, post-ship watches, WIP, active dissents, generation history. Replaces dt-status. No sprint velocity, no convergence score.
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
  requires-context: [flow-state-model, flow-philosophy, flow-operating-doctrine, flow-operator-voice, vault-access]
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
- `~/.claude/commands/context/flow-operating-doctrine.md`
- `~/.claude/commands/context/flow-operator-voice.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Read-only state report — a cheap convenience and resume aid, not a decision instrument. The single skill for "what's going on?". The default output is a **plain-English dashboard** written per `flow-operator-voice.md`: it answers *where this stands, what's blocking ship, and what needs you*, in that order, one screen, jargon glossed on every use, no naked metrics. The dense per-dimension view lives behind `--verbose`. It reports no convergence score and no temperature — both instruments are retired (doctrine §Field verdict); ship readiness is the `flow-ship` gate checklist, and this report shows which gate items are outstanding.

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

- `flow-state.yaml` — the `checkpoint` block first; it is the forward-looking gate the
  rest of the report hangs from
- `efforts/{effort}/dissents-active.yaml`
- `generations/gen-{N}/summary.md` (current generation)
- Last 10 entries of `flow-state.yaml.phase-log`
- If `--comms`: `efforts/{effort}/shipped/comms/` directory

**Stale-schema flag**: if the state file carries retired fields (a temperature block,
convergence-score, reheat-triggers-armed — schema 1.0), say so at the top of the report
and name the fix: the retired fields are dead instruments, some of them armed, and the
next state-writing skill will migrate the file (state model §State schema). This skill
is read-only and never migrates; it only refuses to report from retired fields.

### Step 2: Compute derived views

- **Checkpoint**: the recorded gate as of the last cull close — redispatch blocked or
  evidence named, evaluator-fleet open or blocked (with the blocker), and the recorded
  `next` list. The NEXT section of the dashboard derives from `checkpoint.next`, never
  from re-reasoning over history; if no checkpoint block exists (pre-first-cull or
  pre-migration state), derive NEXT from the doctrine spine and say which source was used
- **Ship-gate status**: which of `flow-ship`'s gate items are already satisfied (chavruta run since last cull? deep pass done? ledger audit? watches drafted?) and which are outstanding
- **Pareto view**: current front with ties and saturated dimensions named as such
- **Dissent health**: noisy count, stale count, high-signal count
- **Watches**: post-ship watches armed / fired (from the latest ship record, if any)
- **WIP**: current admission cost; agents in-flight; last generation's spend estimate vs observed

### Step 3: Format output

Default format — plain-English dashboard per `flow-operator-voice.md`. Structure and register shown here; content derives from state:

```
flow pulse — {effort-slug} · generation {N} · spec v{spec-version}

WHERE THIS STANDS
  The probe generation has been scored and archived down to survivors
  (culled): two variants remain that nothing else beats (the Pareto
  front). 14 of the spec's 19 requirements have a passing variant among
  them. var-2 is stable and shippable but doesn't cover the full spec
  (a metastable candidate): it qualifies for a gated ship — out early,
  behind a feature flag, with watches armed on the deferred scope.

WHAT'S BLOCKING SHIP  (the /flow-ship gate items still open)
  1. Paired adversarial review (chavruta) has not run since the cull.
  2. A recorded disagreement's trigger condition fired (dissent
     reactivation): the inline-retry-vs-middleware dispute re-armed
     because inline retry callsites hit 4 (its threshold was 3). It
     needs acknowledging, mitigating, or resolving.
  3. The rollback path hasn't been demonstrated yet (no fired revert
     probe).

WHAT NEEDS YOU  (one decision each — answer in any order)
  1. The reactivated disagreement above → /flow-dissent
  2. var-2 flagged a judgment call the spec left open (decision ledger,
     SR-019) → one interpretation ships; say which.

NEXT  (from the recorded checkpoint — the cull close wrote this list)
  /flow-dissent first — the disagreement blocks the ship gate; then
  /flow-chavruta, then the ship decision (/flow-ship). Another
  generation is blocked until evidence is named (checkpoint gate).

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
