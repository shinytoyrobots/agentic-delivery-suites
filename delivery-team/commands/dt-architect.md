---
description: Propose architectural approaches with tradeoffs, recommendation, component view, vertical slices, fitness functions, and walking-skeleton first iteration — before story sharding
argument-hint: <PRD path, spec bundle dir, or "current-sprint">
model: sonnet
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
capability-class: planning-design
tier: II
domain: [dt]
works-with:
  requires-context: [dt-pipeline-stages, dt-artifact-schemas, dt-schemas-planning, dt-definition-of-done, vault-access]
  upstream-skills: [pm-spec, dt-project-kickoff]
  downstream-skills: [dt-start, dt-architect-review]
  compatible-agents: [dt-architect, dt-codebase-indexer]
readiness:
  state: green
  idempotent: true
  warm-start: false
cost:
  model-class: medium
  agent-count: 1
  web-calls: none
  context-budget: medium
---

# Architecture Proposal

Read context files:
- `~/.claude/commands/context/dt-pipeline-stages.md`
- `~/.claude/commands/context/dt-artifact-schemas.md`
- `~/.claude/commands/context/dt-schemas-planning.md`
- `~/.claude/commands/context/dt-definition-of-done.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Sit between PRD/spec authoring and story sharding. Produce an `architecture-proposal.md` that:

- Proposes 2–3 distinct architectural approaches plus Option 0 (don't build yet)
- Recommends one with explicit reasoning, named dissent, and consultation list
- Outlines component boundaries (C4 levels 1–3), team topology, and Conway's Law implications
- Specifies fitness functions tied to quality attributes
- Decomposes the architecture into vertical slices that pre-stage INVEST stories
- Names a walking-skeleton first iteration that exercises every component end-to-end

This skill consumes a PRD or three-file spec bundle and produces the architecture artifact `dt-start` will consume during sprint planning. It is opinionated: every section in the schema is required.

The agent operates in **advisory mode** (Harmel-Law's Advice Process). It produces options and named dissent, never decisions. The human reviewer is the decider.

## Input

`$ARGUMENTS` = one of:
- Path to a PRD or spec file
- Path to a three-file spec bundle directory (containing `requirements.md`, `design.md`, `tasks.md`)
- `current-sprint` — use the spec bundle in the current sprint's `sprints/{effort}/sprint-{N}/`
- Empty — prompt the user via `AskUserQuestion` for the spec source

## Process

### Step 1: Resolve inputs

Determine the spec source from `$ARGUMENTS`. If a three-file spec bundle, read all three files. If a single PRD file, read it.

Also gather:
- **Codebase index** (if existing repo): `.codebase-index/architecture.md`, `components.md`, `data-model.md`. If `.codebase-index/` does not exist, note "greenfield project — no prior architecture context."
- **Project context** (if exists): `project-kickoff.md` for team shape, conventions, HITL level
- **Prior ADRs** (if any): all files in `doc/adr/*.md` — treat as existing constraints unless PRD explicitly requires superseding
- **Behavioral knobs**: parse from `$ARGUMENTS` if user appended flags like `--verbosity=concise` or `--style=force-monolith`. Default: verbosity=detailed, inverse-conway=flag-only, style-override=none.

If the PRD is missing or inaccessible, halt with HITL escalation per `dt-hitl-protocol`.

### Step 2: Invoke dt-architect subagent

Launch `~/.claude/commands/agents/dt-architect.md` subagent (model: sonnet) with the gathered inputs.

Provide it explicitly:
- The PRD/spec content (or three-file bundle paths)
- The codebase index files (if any)
- Project context (if any)
- Prior ADRs (if any)
- The chosen behavioral knobs

The agent runs its 4 mandatory passes (Descriptor → Transposition → Irreversibility → Option 0) and produces the full 14-section `architecture-proposal.md` content via stdout.

### Step 3: Capture and persist output

Determine output destination:
- If `$ARGUMENTS` was `current-sprint` or a sprint bundle: write to `sprints/{effort}/sprint-{N}/architecture-proposal.md`
- If `$ARGUMENTS` was a standalone PRD: write to `<PRD-dir>/architecture-proposal.md` alongside the PRD
- If neither path resolution works: ask the user via `AskUserQuestion` where to write

Capture the agent's stdout as the file content. Do not edit it — the agent's schema discipline depends on the output being preserved as-emitted.

Also extract per-decision ADRs from §9 of the proposal and write them as separate files at `doc/adr/{NNNN}-{slug}.md` (sequential numbering, immutable). If `doc/adr/` doesn't exist, create it.

### Step 4: Emit verdict summary

Print a summary to the conversation:

```
Architecture proposal: <path>
Approaches proposed: <count> + Option 0
Recommended: Option <N> — <one-line summary>
Strongest objection: <one line>
ADRs created: <count> — at doc/adr/
Walking skeleton slice: <name>
Estimated time-to-walking: <days>

Next: review with /dt-architect-review <path>, or proceed to /dt-start
```

### Step 5: Suggest next step

If the proposal was created in a sprint context:
- Recommend `/dt-architect-review <path>` to run adversarial schema check
- After review passes, recommend `/dt-start continue` to proceed to story sharding

If the proposal was standalone:
- Recommend reviewing the file with the human decider
- Suggest the consultation list from §5 ("Who to consult before deciding")

## Output

- `architecture-proposal.md` at the resolved location (always)
- `doc/adr/{NNNN}-{slug}.md` per architecturally-significant decision (one per §9 ADR)
- Conversation summary (verdict + next step)

## When to invoke this skill

**Primary callers:**
- During Stage 2 (Technical Spec) of the delivery pipeline, before `dt-start`
- During `pm-spec` §4 (Design) authoring, when delegating design.md to the agent
- During `dt-project-kickoff` for greenfield projects (auto-invoked after codebase indexing)
- For technical inventions in `inv-validate-plan` where the walking skeleton IS the validation experiment

**Secondary callers:**
- During `dt-code-audit` if drift score above threshold (compare current state to fresh-eyes recommendation)
- During `dt-readiness-gate` and `dt-gate-review` (consume as input, do not generate)
- During `cpo-strategy-eval` and `cpo-pre-mortem` if architecture-proposal.md exists (pull as evidence)

**Should NOT invoke during:**
- `dt-run` (implementation phase — too late)
- `dt-close` and `dt-release-*` (post-implementation)
- Personal/lifestyle skills (out of domain)

## Defaults applied

- **Architecture style**: modular-monolith-first. Microservices require 4+ of the 5-dimension framework justifying them. Override via `--style=force-microservices` (with justification recorded in ADR-1).
- **Inverse Conway**: `flag-only` — agent warns if architecture requires team reorg the org doesn't have, but does not refuse to propose. Override via `--inverse-conway=strict` to refuse, or `--inverse-conway=permit` to assume reorg.
- **Verbosity**: `detailed` — full 14-section schema. Override via `--verbosity=concise` (4-page floor) or `--verbosity=exhaustive` (one-way-door decisions only).
- **AI-product appendix**: not included in v1. PRDs for AI products will use the canonical schema; AI-specific concerns (eval harness, prompt versioning, model fallback, drift) are noted as open questions in §13.

## Anti-pattern note

The agent is structurally biased toward fit-for-purpose architecture, not "best" architecture. If the output reads like a generic architecture textbook, the agent has failed Pass 1 (workload signature) — re-run with verbosity=concise and explicit workload constraints in `$ARGUMENTS`.
