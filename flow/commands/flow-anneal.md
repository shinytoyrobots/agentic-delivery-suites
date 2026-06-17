---
description: Adjust the system temperature (exploration vs exploitation). Heat to escape local optima; cool to converge. Reheating triggers fire automatically; this is manual override.
argument-hint: heat | cool | reset | --to <0.0-1.0> | --status
model: sonnet
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
capability-class: planning-design
tier: III
domain: [flow]
works-with:
  requires-context: [flow-state-model, flow-dispatch-rules, flow-philosophy, vault-access]
  upstream-skills: []
  downstream-skills: [flow-generate]
  compatible-agents: [flow-temperature-controller]
readiness:
  state: green
  idempotent: false
  warm-start: true
cost:
  model-class: low
  agent-count: 1
  web-calls: none
  context-budget: small
---

# Flow Anneal

Read context files:
- `~/.claude/commands/context/flow-state-model.md`
- `~/.claude/commands/context/flow-dispatch-rules.md`
- `~/.claude/commands/context/flow-philosophy.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Manually adjust the system temperature parameter. Most of the time, temperature is managed automatically by `flow-temperature-controller` — default cooling schedule plus reheating triggers. This skill is the manual override when human judgment about exploration vs exploitation is needed.

Temperature affects:
- Generator dispatch count (higher temp → more generators)
- Constraint bias selection (higher temp → `radical` bias included)
- Pareto-front culling (higher temp → less aggressive cull, more variants survive)

## Modes

### `heat`
Raise temperature to a high value (0.7 by default). Use when:
- Stuck at a local optimum
- Architectural reconsideration is warranted
- Want to explore alternative paradigms

### `cool`
Lower temperature toward the floor (0.1 default). Use when:
- Approaching convergence and want strict exploitation
- A clear winner exists and you want to refine, not diverge
- Token budget is tightening

### `reset`
Reset temperature to the effort's starting value (default 0.5). Use when:
- The current temperature was set by a reheat that turned out to be premature
- You want to return to baseline behavior

### `--to <value>`
Set temperature to a specific value, clamped to [temperature-floor, 1.0]. Useful for precise control or scripted runs.

### `--status`
Show current temperature, reheat history, cooling trajectory. No state change.

## Procedure

### Step 1: Read state

- `flow-state.yaml` — current temperature, temperature-floor, last-reheat
- `spec/constitution.md` — any temperature override rules

### Step 2: Invoke flow-temperature-controller

Pass the requested change. Per `agents/flow-temperature-controller.md`:

- It applies the change clamped to [temperature-floor, 1.0]
- Logs the manual adjustment with rationale
- Records the prior temperature for audit

For `--status`: it returns the current state, no change.

### Step 3: HITL for significant changes

- Manual heat > 0.6: confirm — this widens dispatch and may surprise the user
- Manual cool below 0.2: confirm — this aggressively narrows search; may lock in
- Setting to 1.0: confirm with rationale

### Step 4: Report

Return:
- Prior temperature
- New temperature
- Rationale recorded
- Effects on next dispatch (projected generator count, biases included)

## What this skill does NOT do

- **It does not write code.**
- **It does not modify the spec, evals, or dissents.**
- **It does not directly dispatch generators.** It changes a parameter that affects future dispatch.

## Outputs

| Path | Action |
|------|--------|
| `efforts/{effort}/flow-state.yaml` | Temperature field updated; phase-log appended |

## HITL surface

- Manual heat > 0.6 or cool < 0.2: confirmation prompt
- Setting below temperature-floor: refused with explanation
- Cooling immediately after a reheat (within 1 generation): warning + confirmation (likely unintended)

## Failure modes

- Value out of range: clamped; report clamped value
- No active effort: report no-effort error
- Temperature-floor not set: use default 0.1

## Idempotency

`--status` is idempotent.

State changes are NOT idempotent — re-running `/flow-anneal heat` repeatedly does not accumulate; it sets to 0.7 each time. But each invocation appends a new phase-log entry.

## Examples

### Force exploration when stuck

```
/flow-anneal heat
```

Temperature: 0.20 → 0.70. Next dispatch will include `radical` bias and likely spawn 7-9 generators.

### Converge after exploration paid off

```
/flow-anneal cool
```

Temperature: 0.70 → 0.15. Next dispatch will use `convention + maintainability + security` bias mix and likely spawn 3 generators.

### Set precise value for a controlled experiment

```
/flow-anneal --to 0.50
```

Resets to baseline.

### Check temperature state

```
/flow-anneal --status
```

Output:
```
Current temperature: 0.40
Floor: 0.10
Last reheat: 2026-05-10T08:00 (trigger: eval-plateau-detected)
Cooling trajectory (last 5 gens): 0.70, 0.55, 0.45, 0.40, 0.40
Reheats armed: eval-plateau, architectural-blocker, debt-spike, dissent-cluster
Constitution overrides: none
```
