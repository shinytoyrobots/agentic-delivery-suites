---
description: Author or evolve the executable spec — GWT scenarios (SCN) first, derived EARS requirements (SR) second. Converts NL intent to scenarios and requirements; versions spec.md; updates conformance mappings; triggers dissent reactivation check.
argument-hint: <natural-language scenario or intent> | --requirement <non-functional EARS> | amend SCN-NNN/SR-NNN ... | --restructure | --constitution
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
capability-class: planning-design
tier: II
domain: [flow]
works-with:
  requires-context: [flow-spec-protocol, flow-state-model, flow-philosophy, flow-dissent-protocol, vault-access]
  upstream-skills: [flow-init]
  downstream-skills: [flow-eval, flow-generate, flow-dissent]
  compatible-agents: [flow-spec-writer, flow-dissent-monitor, flow-narrator]
readiness:
  state: green
  idempotent: false
  warm-start: true
cost:
  model-class: high
  agent-count: 2
  web-calls: none
  context-budget: medium
---

# Flow Spec

Read context files:
- `~/.claude/commands/context/flow-spec-protocol.md`
- `~/.claude/commands/context/flow-state-model.md`
- `~/.claude/commands/context/flow-philosophy.md`
- `~/.claude/commands/context/flow-dissent-protocol.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Author or evolve the executable spec. The spec is two layers: **GWT scenarios (`SCN-{NNN}`)** — product-facing behavioral examples, the primary unit of work — and **EARS requirements (`SR-{NNN}`)** — system-centric constraints, derived from scenarios or (for non-functional concerns) standalone. All spec evolution flows through this skill. `flow-generate` always reads the current `spec/spec.md`; this is the only legitimate way to change what it sees.

## Modes

### Mode 1: Add scenario (default)

User supplies NL or partial Given/When/Then describing a user-observable behavior. `flow-spec-writer` forms the scenario, pins acceptance criteria, assigns `SCN-{NNN}`, and derives the EARS requirements its criteria imply.

```
/flow-spec "When a tenant exceeds their rate limit, the system should tell them how long to wait."
```

### Mode 1b: Add non-functional requirement (direct SR)

For constraints with no user trigger (performance, security, cost budgets), bypass the scenario layer and write `SR-{NNN}` directly:

```
/flow-spec --requirement "System shall sustain 10,000 concurrent users at p95 latency under 200ms."
```

### Mode 2: Amend existing scenario or requirement

User specifies a `SCN`/`SR` ID and the change:

```
/flow-spec amend SCN-019 "add acceptance criterion: Retry-After must be ≤ 3600 seconds"
/flow-spec amend SR-019 "increase rate limit from 100 to 200"
```

A **major** version increment (existing scenario/requirement modified). HITL required. Amending a scenario may require adjusting its derived SRs.

### Mode 3: Remove scenario or requirement

```
/flow-spec remove SCN-019 "deprecated; split into SCN-045 and SCN-046"
/flow-spec remove SR-019 "deprecated; replaced by SR-042"
```

Major version increment. HITL required. The scenario/SR is moved to `spec/history/` and removed from current spec.md, not deleted.

### Mode 4: Restructure

```
/flow-spec --restructure
```

Section reorganization, no semantic change. Major-with-restructure version (`X.Y.Z-rN`). HITL required.

### Mode 5: Constitution amendment

```
/flow-spec --constitution "add prohibition: no synchronous external HTTP calls in request handlers"
```

Always a major version increment of constitution. HITL required.

## Procedure

### Step 1: Read state

- `spec/spec.md` (current)
- `spec/constitution.md`
- `spec/history/` (recent versions for diff context)
- `flow-state.yaml` (current effort context)
- `dissents-active.yaml` (existing dissents — may be affected by this change)
- `evals/harness.yaml` (current mappings)

### Step 2: Classify

Determine version bump:
- **Patch**: typo, clarification, glossary edit, no semantic change
- **Minor**: new `SCN-{NNN}` or `SR-{NNN}`, no existing scenario/requirement modified
- **Major**: existing SCN/SR modified/removed, breaking glossary change, constitution change
- **Restructure**: reorganization without semantic change

Major and restructure require HITL preference-articulator mode.

### Step 3: Invoke flow-spec-writer

Pass the NL intent + classification + current spec. Per `agents/flow-spec-writer.md`:

- For user-observable behavior: forms a `SCN-{NNN}` scenario (Given/When/Then + acceptance criteria), counter-prompting on vagueness, then **derives** the `SR-{NNN}` its criteria imply
- For non-functional intent (`--requirement`): normalizes directly to EARS `SR-{NNN}`, no SCN parent
- It refuses vague NL (returns a counter-prompt)
- It computes the new spec.md draft (scenarios + requirements + traceability)
- It writes the proposed change to a staging path: `spec/.staging/spec-proposed.md`

### Step 4: HITL gate (if major/restructure)

Display the diff. Use AskUserQuestion to confirm:

- New `SCN`: full scenario block (Given/When/Then + acceptance criteria + derived SRs)
- New `SR`: the EARS requirement (and its SCN parent, if any)
- Modified SCN/SR: before/after side-by-side
- Removed: what is archived to `spec/history/`
- Restructure: section outline

Options: approve as drafted · approve with modifications (collect them) · reject (halt, no changes written). If `--constitution`, always require explicit approval with full diff displayed.

### Step 5: Scenario→eval binding and conformance mapping

For each new or modified `SCN`:
- Identify which acceptance criteria become test cases (typically 2–4)
- Register a `scenario:` mapping in `evals/harness.yaml.mappings` (correctness dimension) with `tasks:` and `derived-requirements:`

For each new or modified `SR`:
- Check `evals/harness.yaml.mappings` for a corresponding entry
- If missing: prompt user to either (a) add a mapping now (collect grader/dataset references), or (b) accept `mapping-pending: true` with a TODO

A spec change with unmapped scenarios or requirements writes `mapping-pending: true` in front matter — `flow-eval` must address before `flow-generate` can proceed against the new SCN/SR.

### Step 6: Write

Order:

1. Write `spec/history/spec-v{N}-{date}.md` with the change record
2. Write the new `spec/spec.md`
3. Update `evals/harness.yaml` with new/changed mappings
4. Append entry to `flow-state.yaml.phase-log`

### Step 7: Trigger downstream

Invoke (in parallel where appropriate):

- `flow-dissent-monitor` — check for spec-change reactivation conditions
- `flow-narrator` — project the spec delta into changelog/sales/support/marketing artifacts at `efforts/{effort}/shipped/comms/{spec-version}/`

### Step 8: Report

Return:
- New spec version
- SCN changes (added / modified / removed)
- SR changes (added / modified / removed)
- Traceability: which `SR-{NNN}` were derived from which `SCN-{NNN}`
- Conformance mapping status (complete / pending)
- Dissent reactivations triggered (count + IDs)
- Comms artifacts generated (paths)

## Outputs

| Path | Action | Versioned? |
|------|--------|------------|
| `spec/spec.md` | Updated | Yes |
| `spec/history/spec-v{N}-{date}.md` | Created | Yes |
| `evals/harness.yaml` | Updated (mappings) | Yes |
| `efforts/{effort}/flow-state.yaml` | Updated (phase-log) | No (gitignored) |
| `efforts/{effort}/shipped/comms/{version}/` | Created (by narrator) | Yes |

## HITL surface

- Vague NL: counter-prompt requesting precision
- Major version increment: full diff display + approval
- Restructure: outline display + approval
- Constitution amendment: full diff + explicit approval
- Conformance mapping missing: choose between adding now or accepting mapping-pending

## Failure modes

- NL cannot be EARS-ified after counter-prompting twice: halt; return the dialogue for the user to resolve in a separate session
- Spec change conflicts with active dissent reactivation conditions in a way that requires resolving the dissent first: halt; surface the dissent; suggest `/flow-dissent resolve` first
- Conformance mapping references a non-existent grader/dataset: halt; suggest `/flow-eval` to create

## Idempotency

Re-running with identical input produces a no-op if the spec already reflects the proposed change. Otherwise writes a new version.

## Examples

### Add a new scenario (behavioral)

```
/flow-spec "When a tenant exceeds their burst tolerance, the system should tell them how long to wait."
```

Result: counter-prompt clarifies recovery behavior; `SCN-019` added (Given over-limit · When another request · Then 429 + retry hint), with acceptance criteria; derives `SR-019` (429 response), `SR-020` (Retry-After format), `SR-021` (rate-limit enforcement); spec bumped to v1.5.0 (minor); scenario tasks registered to `correctness-real-v1`; changelog v1.5.0 generated.

### Add a non-functional requirement (no scenario)

```
/flow-spec --requirement "System shall sustain 10,000 concurrent users at p95 latency under 200ms."
```

Result: `SR-100` added (no SCN parent); spec bumped to v1.5.1 (minor); mapping added to harness.yaml (performance dimension).

### Amend a scenario

```
/flow-spec amend SCN-019 "add acceptance criterion: Retry-After must be ≤ 3600 seconds"
```

Result: HITL prompt with before/after; on approval, `SCN-019` modified and derived `SR-020` adjusted; spec bumped to v2.0.0 (major); comms regenerated.

### Constitution change

```
/flow-spec --constitution "add escalation trigger: any spec change touching authentication invokes chavruta on convergence"
```

Result: HITL prompt with full constitution diff; on approval, constitution amended; major spec version bumped.
