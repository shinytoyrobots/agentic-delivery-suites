---
description: Query, acknowledge, mitigate, or resolve dissents. Triggers manual reactivation check. Surfaces reactivated dissents.
argument-hint: --list-active | --list-reactivated | --check | acknowledge <id> | mitigate <id> --commit <sha> | resolve <id> --reason <text>
model: sonnet
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
capability-class: review
tier: III
domain: [flow]
works-with:
  requires-context: [flow-dissent-protocol, flow-state-model, vault-access]
  upstream-skills: [flow-chavruta]
  downstream-skills: [flow-spec, flow-ship]
  compatible-agents: [flow-dissent-monitor]
readiness:
  state: green
  idempotent: true
  warm-start: true
cost:
  model-class: medium
  agent-count: 1
  web-calls: none
  context-budget: small
---

# Flow Dissent

Read context files:
- `~/.claude/commands/context/flow-dissent-protocol.md`
- `~/.claude/commands/context/flow-state-model.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Human / orchestrator interface to the dissent registry. List, query, and transition the status of dissents. Trigger manual reactivation checks. This is where dissents move through the lifecycle: active → reactivated → acknowledged | mitigated | resolved.

## Operations

### `--list-active`

List all dissents with status `active` in the current effort.

Output: table with id, raised-at, generation, one-line summary, reactivation-count.

### `--list-reactivated`

List all dissents currently in `reactivated` state — i.e., they have triggered and are awaiting acknowledgment, mitigation, or resolution.

Output: same as `--list-active` plus the trigger that fired and when.

### `--check`

Force a fresh reactivation scan across all active dissents. Useful after a manual code or spec change you suspect may have triggered conditions.

Launches `~/.claude/commands/agents/flow-dissent-monitor.md` subagent (model: sonnet). Returns: dissents checked, dissents newly reactivated.

### `acknowledge <id>`

Set the dissent's status to `acknowledged`. Indicates: the trade-off remains valid, no code change required, the reactivation was reviewed and intentionally not mitigated.

Requires HITL: confirmation with the dissent's full text and the matching trigger.

Records the acknowledgment with timestamp and (if HITL non-autonomous) the actor.

### `mitigate <id> --commit <sha>`

Set the dissent's status to `mitigated`. Indicates: code was changed to address the dissent.

The commit sha is recorded. Re-run reactivation check against this dissent to verify conditions are no longer met. If they still match, halt and surface (the mitigation didn't actually mitigate).

### `resolve <id> --reason <text>`

Set the dissent's status to `resolved`. Indicates: the dissent is formally retired — either the underlying concern is no longer relevant (spec changed, code area deleted) or the dissent was wrong on reflection.

Requires HITL: confirmation. Records the rationale.

A resolved dissent stays in the registry (append-only) but is no longer evaluated for reactivation.

## Procedure

### Step 1: Read state

- `efforts/{effort}/dissents-active.yaml`
- `flow-state.yaml` (current generation, last-dissent-check)

### Step 2: Execute operation

Per the requested operation:

- **List**: filter and format output
- **Check**: invoke `flow-dissent-monitor` for a manual sweep
- **Acknowledge / mitigate / resolve**: validate the operation (does dissent exist? is current status compatible?), HITL confirm, update yaml

### Step 3: Write

For status transitions: update the dissent in-place in `dissents-active.yaml`. Append to its `history`:

```yaml
history:
  - "2026-05-13T11:30:00Z raised by chavruta-pair gen-4 convergence checkpoint"
  - "2026-05-13T14:22:00Z reactivated by code-change matching 'grep -rc withRetry' > 3"
  - "2026-05-13T16:00:00Z mitigated; commit a1b2c3d4 introduced retry middleware"
```

### Step 4: Report

Return the affected dissent(s) and their new status.

## Status transition rules

Status is **monotonic-forward**. Valid transitions:

| From | To | Trigger |
|------|----|---------| 
| `active` | `reactivated` | Reactivation condition matched (by `flow-dissent-monitor`) |
| `active` | `resolved` | Explicit resolve (e.g., spec amendment retired the concern) |
| `reactivated` | `acknowledged` | Human / orchestrator acknowledge action |
| `reactivated` | `mitigated` | Code mitigation + commit |
| `reactivated` | `resolved` | Explicit resolve |
| `acknowledged` | `reactivated` | New condition match (e.g., the trigger fires again under new conditions) |
| `mitigated` | `reactivated` | Conditions matched again (mitigation incomplete) |
| any | `acknowledged-noisy` | Reactivation-count > 5 without mitigation/resolve (set by monitor) |

`resolved` is terminal. Resolved dissents are not evaluated further. A new concern that resembles a resolved dissent is **a new dissent**, not a re-opening.

## What this skill does NOT do

- **It does not author dissents.** That's `flow-chavruta-pair`.
- **It does not modify code.** Mitigation is recorded here; the code change happens via `flow-generate` (or direct edit, recorded).
- **It does not modify dissent positions, counterpositions, or reactivation conditions.** Append-only on those fields.

## Outputs

| Path | Action |
|------|--------|
| `efforts/{effort}/dissents-active.yaml` | Status + history updated |
| `efforts/{effort}/flow-state.yaml` | `active-dissents`, `dissents-reactivated` recounted; phase-log appended |

## HITL surface

- Acknowledge: confirm with full dissent display
- Resolve: confirm with rationale capture
- Mitigation didn't actually mitigate (conditions still match after commit): halt and surface

## Failure modes

- Dissent ID not found: halt with helpful list of active IDs
- Operation incompatible with current status: explain and abort
- Mitigation commit doesn't exist in repo: halt and verify

## Idempotency

`--list-active`, `--list-reactivated`, `--check` are idempotent.

Status-transition operations are not idempotent in the sense that re-running an `acknowledge` on an already-acknowledged dissent is a no-op (returns the existing status). Re-running with different parameters (e.g., re-acknowledging with new rationale) appends to history.

## Examples

### Daily reactivation check

```
/flow-dissent --check
```

Monitor sweeps all active dissents. Reports: "12 dissents checked, 1 newly reactivated (dissent-2026-05-13-0001 — code-change condition matched after PR #123)."

### Acknowledge a reactivated dissent

```
/flow-dissent acknowledge dissent-2026-05-13-0001
```

HITL: full text of dissent + matching condition. Confirms intent. Records acknowledgment.

### Mitigate via commit

```
/flow-dissent mitigate dissent-2026-05-13-0001 --commit a1b2c3d4
```

Records the mitigation. Re-checks the condition against the post-commit state. If still matching, halts.

### Resolve a stale dissent

```
/flow-dissent resolve dissent-2026-01-10-0007 --reason "Spec v3.0 removed the retry pattern entirely; this dissent is no longer relevant."
```

HITL confirmation. Records resolution. Dissent will no longer be evaluated.
