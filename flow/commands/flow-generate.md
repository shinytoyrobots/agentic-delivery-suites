---
description: Spawn a generation of N implementation variants. Orchestrator dispatches generators in parallel with constraint biases; each variant writes only to its own directory.
argument-hint: '[scope SR-IDs or "all"] [--hotfix] [--N <count>]'
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
capability-class: build
tier: II
domain: [flow]
works-with:
  requires-context: [flow-state-model, flow-dispatch-rules, flow-spec-protocol, flow-philosophy, vault-access]
  upstream-skills: [flow-spec, flow-eval]
  downstream-skills: [flow-cull]
  compatible-agents: [flow-orchestrator, flow-generator, flow-context-curator]
readiness:
  state: green
  idempotent: false
  warm-start: true
cost:
  model-class: high
  agent-count: variable
  web-calls: none
  context-budget: xlarge
---

# Flow Generate

Read context files:
- `~/.claude/commands/context/flow-state-model.md`
- `~/.claude/commands/context/flow-dispatch-rules.md`
- `~/.claude/commands/context/flow-spec-protocol.md`
- `~/.claude/commands/context/flow-philosophy.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Produce a generation: N implementation variants of the spec, biased by different constraints, written to their own variant directories. Variants cover both the spec's GWT scenarios (SCN-{NNN}) and its EARS requirements (SR-{NNN}). This is the workhorse skill of `flow` — every implementation pass routes through here.

## Inputs

- **scope** (optional) — SR-{NNN} list to focus the generation, or `all` (default) for the full spec
- `--hotfix` — bypass population search, dispatch N=1 with security bias and adversarial eval depth
- `--N <count>` — override generator count; otherwise dispatch rules decide

## Procedure

### Step 1: Read state

- `flow-state.yaml` — current generation, temperature, wip-spread
- `spec/spec.md` and `spec/constitution.md`
- `dissents-active.yaml` — surface active dissents to generators
- `evals/harness.yaml` — verify all in-scope SRs have conformance mappings

### Step 2: Validate

- All in-scope SRs have conformance mappings? If not, halt and suggest `/flow-eval` first.
- WIP spread < 0.6? If not, halt and surface saturation HITL.
- Current generation directory exists? Increment to gen-{N+1}.

### Step 3: Dispatch decision

Launch `~/.claude/commands/agents/flow-orchestrator.md` subagent (model: opus) with:
- Mode: `generate`
- Scope: in-scope SRs
- Hotfix flag (if set)

Orchestrator returns:
- N (number of generators)
- Biases per generator
- Evaluator depth (will be used by `flow-cull`)
- Chavruta decision (deferred to convergence checkpoint by default)
- Rationale (logged to phase-log)

### Step 4: Create generation directory

```
generations/gen-{N+1}/
  population/
  eval-results/      # populated by flow-cull, not here
  dissents/          # populated by flow-chavruta if invoked
```

### Step 5: Spawn generators

For each (bias, index) pair from the orchestrator's dispatch:

1. Create `generations/gen-{N+1}/population/var-{index}/`
2. Write `constraint-bias.md` declaring the bias and any orchestrator notes
3. Launch `~/.claude/commands/agents/flow-generator.md` subagent (model: opus, one per variant in parallel, with `isolation: "worktree"`) with:
   - Spec version to target
   - All in-scope SCN-{NNN} (scenarios) and SR-{NNN} (requirements)
   - Constraint bias
   - Active dissents to address
   - Variant directory path — **MUST be relative** (e.g. `efforts/{effort}/generations/gen-{N+1}/population/var-{index}/`). Never pass an absolute path that contains `<project-root>` — it will resolve to the main tree regardless of the agent's worktree cwd and is the primary mechanism behind the gen-3/var-3 + gen-5/var-2 isolation leaks.
   - **Explicit isolation contract** (copy verbatim into each generator's prompt):
     > Before any other action, run `TOPLEVEL=$(git rev-parse --show-toplevel)` and verify it starts with `*/.claude/worktrees/agent-`. If not, ABORT and return `isolation-violation` HITL flag. Re-verify before every git mutation (`git switch`, `git checkout`, `git branch`, `git add`, `git commit`). All your work happens inside this worktree. If a pre-commit hook fails because `node_modules` is missing, run `pnpm install` in the worktree — do NOT fall back to the main tree.
   - **Explicit instruction**: write ONLY to variant directory metadata + your worktree's project tree; do not touch `<project-root>` at any absolute path.
4. Generators run in parallel (multiple Agent calls in one message).

### Step 6: Wait for completion

Each generator returns:
- Variant path
- Completed SRs
- HITL flags raised (ambiguity, isolation-violation, isolation-drift, etc.)
- Self-check status
- Reported commit SHA (if any) and worktree branch

### Step 6a: Worktree-isolation post-run verification (BLOCKING)

Before proceeding to Step 7, run the orchestrator's post-run check (`flow-orchestrator.md` Step 7a) against every variant's commit. The check verifies:

1. The main repo's HEAD is still on `main` (no branch drift).
2. Each variant's commit SHA is NOT reachable from `main` (the work landed on its own branch, not on main).

If any variant fails the check, halt and surface a HITL prompt with the recovery procedure documented in `flow-orchestrator.md` Step 7a. Do not record success in `flow-state.yaml.phase-log` until resolved.

### Step 7: Handle HITL flags

If any generator raised ambiguity:
- Collect all ambiguity flags
- Surface to user via AskUserQuestion if HITL mode is preference-articulator
- For autonomous mode: orchestrator records the ambiguity in `flow-state.yaml.phase-log` and proceeds; the variant noted with `ambiguity-pending: true`

### Step 8: Update state

Write to `flow-state.yaml`:
- `current-generation`: N+1
- `wip-spread`: recalculated based on completed work
- `dispatch.generators-per-gen-current`: actual N
- `phase-log`: gen-{N+1} spawn record + completion record

### Step 9: Report

Return:
- Generation number
- Variants produced (count + paths)
- Biases used
- HITL flags pending
- Next-step suggestion: `/flow-cull` to score the generation

## Hotfix mode

Bypasses population search:

- N=1, bias=security
- Evaluator depth=adversarial (orchestrator sets in cull)
- No chavruta
- Spec version increment is patch only
- HITL preference-articulator (constitution may require)

Used for critical security or production-down issues where the cost of the population search exceeds the value.

## What this skill does NOT do

- **It does not evaluate variants.** That's `/flow-cull`.
- **It does not promote a variant to the working tree.** That's `/flow-converge` + `/flow-ship`.
- **It does not modify the spec.** That's `/flow-spec`.
- **It does not invoke chavruta.** That happens at convergence checkpoints, not per-generation.

## Outputs

| Path | Action |
|------|--------|
| `efforts/{effort}/generations/gen-{N+1}/population/var-{i}/implementation/` | Variant code (by generator) |
| `efforts/{effort}/generations/gen-{N+1}/population/var-{i}/constraint-bias.md` | Bias declaration |
| `efforts/{effort}/generations/gen-{N+1}/population/var-{i}/notes.md` | Generator notes (if any) |
| `efforts/{effort}/generations/gen-{N+1}/population/var-{i}/ambiguity.md` | If ambiguity flagged |
| `efforts/{effort}/flow-state.yaml` | Updated state + phase-log |

## HITL surface

- WIP spread exceeded: prompt to defer or override
- Ambiguity flags from generators: prompt for resolution if preference-articulator mode
- Constitution-required HITL on hotfix: explicit approval

## Failure modes

- Generator fails to produce a variant (error, timeout): variant marked `failed`, included in cull anyway (will score 0 on correctness)
- All N generators fail: halt, surface as critical incident
- Spec has no mappable SRs in scope: halt, suggest `/flow-eval` first

## Idempotency

Each invocation produces a new generation (gen-{N+1}). Not idempotent in the sense that re-running creates a NEW generation rather than re-producing the prior one.

## Examples

### Standard generation after spec amendment

```
/flow-generate
```

Orchestrator decides: gen-3 spawning 5 generators with biases [simplicity, performance, maintainability, security, convention]. Each writes to `var-1/` through `var-5/`. Returns after all complete.

### Focused generation on specific SRs

```
/flow-generate SR-019,SR-020
```

Same as above but generators only implement SR-019 and SR-020. Prior SRs' implementation is assumed already present in prior generation's survivors.

### Hotfix path

```
/flow-generate --hotfix SR-099
```

N=1; security bias; HITL approval required; targets only SR-099 (a critical-path requirement).
