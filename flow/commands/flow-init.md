---
description: Initialize a flow effort — spec.md, constitution.md, evals/harness.yaml, flow-state.yaml, codebase index. Replaces dt-project-kickoff.
argument-hint: <effort-slug> [--from-spec <path>] [--from-delivery-team <effort>]
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
tier: I
domain: [flow]
works-with:
  requires-context: [flow-philosophy, flow-state-model, flow-spec-protocol, flow-eval-protocol, flow-dispatch-rules, flow-dissent-protocol, vault-access]
  upstream-skills: []
  downstream-skills: [flow-spec, flow-eval, flow-generate]
  compatible-agents: [flow-orchestrator, flow-spec-writer, flow-evaluator, flow-context-curator]
readiness:
  state: green
  idempotent: false
  warm-start: true
cost:
  model-class: high
  agent-count: 3
  web-calls: none
  context-budget: large
---

# Flow Init

Read context files:
- `~/.claude/commands/context/flow-philosophy.md`
- `~/.claude/commands/context/flow-state-model.md`
- `~/.claude/commands/context/flow-spec-protocol.md`
- `~/.claude/commands/context/flow-eval-protocol.md`
- `~/.claude/commands/context/flow-dispatch-rules.md`
- `~/.claude/commands/context/flow-dissent-protocol.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Bootstrap a `flow` effort. Produce the foundational artifacts that every downstream skill assumes:

- `spec/spec.md` — initial executable spec (may be skeletal)
- `spec/constitution.md` — governance rules for this effort
- `spec/history/` — empty, ready for amendments
- `evals/harness.yaml` — eval suite configuration with at least the 6 default dimensions wired
- `evals/datasets/` — empty datasets per dimension
- `evals/graders/` — grader specifications per dimension
- `efforts/{effort-slug}/flow-state.yaml` — initial state
- `.flow-index/` — codebase index for `flow-context-curator`
- `.gitignore` updated to exclude working artifacts

## Inputs

- `effort-slug` — required, kebab-case, becomes the effort directory name
- `--from-spec <path>` — optional, ingest an existing PRD/spec doc as the seed for spec.md
- `--from-delivery-team <effort>` — optional, migrate from an existing delivery-team sprint/effort (read its project-kickoff, distill into spec.md + constitution.md)

## Procedure

### Step 1: Validate environment

1. Check `flow/` does not already exist for this effort (`efforts/{effort-slug}/`).
2. If it does, halt and ask: extend existing, or use a different slug?
3. Check `.gitignore` includes `efforts/*/flow-state.yaml` and `efforts/*/generations/`. If missing, add them.

### Step 2: Gather project context

Use `AskUserQuestion` to collect:

1. **What is this effort solving?** (free-text purpose paragraph)
2. **Stack/codebase**: existing or greenfield? If existing, working directory path.
3. **HITL mode**: preference-articulator | comprehension-auditor | reactivation-watch | autonomous (default: preference-articulator)
4. **Sponsor/customer context**: any named accounts or escalations driving this? (used by `flow-narrator`)
5. **Hard prohibitions**: things implementations must NOT do, regardless of requirements (input to constitution.md)
6. **Default temperature**: starting exploration level (default 0.5)

### Step 3: Author initial spec

Launch `~/.claude/commands/agents/flow-spec-writer.md` subagent (model: opus) with the gathered context. Tell it to author the **behavioral scenarios first, then derive requirements**:
- If `--from-spec`: ingest the provided document; extract user journeys / stories → GWT scenarios (SCN-{NNN}); extract constraints / requirements → EARS SR-{NNN}; flag any vague NL as ambiguity that needs HITL.
- If `--from-delivery-team`: read the prior effort's `project-kickoff.md`, `sprint-N-summary.md` if any. Extract user journeys / stories → scenarios (SCN-{NNN}); extract requirements / constraints → EARS (SR-{NNN}).
- If neither: from the user's purpose paragraph, author GWT scenarios (SCN-{NNN}) for the core happy-path user journeys first, then decompose their acceptance criteria into EARS SR-{NNN}, then extract any non-functional constraints (perf, security, cost) as standalone SR-{NNN}. Fewer, well-formed scenarios beats many vague ones — better to have 3 sharp scenarios than 20 fuzzy ones.

`flow-spec-writer` writes `spec/spec.md` (Behavioral scenarios section first, then Requirements) and the first history file `spec/history/spec-v0.1.0-{date}.md`.

### Step 4: Author constitution

Invoke `flow-spec-writer` again with the prohibitions, preferences, escalation triggers, dispatch overrides collected in Step 2. It produces `spec/constitution.md`.

The default constitution skeleton:

```markdown
# Constitution — {effort-slug}

## Prohibitions
{user-supplied prohibitions}

## Preferences (soft)
- Prefer composition over inheritance.
- Prefer feature flags over branch coupling.
- Prefer additive spec changes over restructures.

## Escalation triggers (HITL surface)
- Spec change requires deprecating a public API → preference-articulator mode
- Two consecutive generations fail to advance Pareto front → comprehension-auditor mode
- Dissent reactivated 3+ times across efforts → preference-articulator mode

## Dispatch overrides
{none unless user specified}

## Violation policy
- This constitution may be amended via `flow-spec`. Amendments are versioned.
- Skill invocations that violate this constitution halt and surface a dissent.
```

### Step 5: Author eval suite

Launch `~/.claude/commands/agents/flow-evaluator.md` subagent (model: opus, read-only mode) and `~/.claude/commands/agents/flow-spec-writer.md` subagent together. Produce:

1. `evals/harness.yaml` with default 6 dimensions wired:

```yaml
schema-version: "1.0"
suite-version: "0.1.0"
dimensions:
  - name: correctness
    graders: [correctness]
    datasets: [correctness-real-v1, correctness-adv-v1]
    threshold: 0.95
  - name: performance
    graders: [performance]
    datasets: [performance-real-v1]
    threshold: 0.80
  - name: maintainability
    graders: [maintainability]
    datasets: [maintainability-real-v1]
    threshold: 0.70
  - name: accessibility
    graders: [accessibility]
    datasets: [accessibility-real-v1]
    threshold: 1.0
  - name: security
    graders: [security]
    datasets: [security-real-v1, security-adv-v1]
    threshold: 1.0
  - name: cost
    graders: [cost]
    datasets: []
    threshold: 0.50
weights:
  correctness: 0.35
  performance: 0.15
  maintainability: 0.15
  accessibility: 0.10
  security: 0.15
  cost: 0.10
mappings:
  # SR-{NNN} → (graders, datasets, threshold)
  # Populated as SRs are added
goodhart-mitigation:
  adversarial-required-for: [correctness, security]
  rotation-period-days: 90
  score-climb-flag-threshold: 0.30
metastable:
  stability-threshold: 0.85
  spec-proximity-threshold: 0.60
  pareto-dimension-minimum: 2
```

2. `evals/graders/{dimension}.md` — placeholder grader specs for each of the 6 dimensions. Each grader spec includes: input format, scoring rules, threshold semantics, version. The evaluator agent fills in detail based on the codebase context.

3. `evals/datasets/` — empty `{dimension}-real-v1.jsonl` and `{dimension}-adv-v1.jsonl` files per dimension. Bootstrapping evals come later via `flow-eval`.

### Step 6: Codebase index

Launch `~/.claude/commands/agents/flow-context-curator.md` subagent (model: sonnet) to produce the initial `.flow-index/`:

- Walk the codebase from working-dir
- Extract modules, symbols, conventions, dependencies
- Write to `.flow-index/`

This step is skipped if the project is greenfield (no existing code yet).

### Step 7: Initialize flow-state.yaml

Write `efforts/{effort-slug}/flow-state.yaml` with the schema in `context/flow-state-model.md`:

```yaml
schema-version: "1.0"
effort: {effort-slug}
created: "{today}"
current-generation: 0
status: in-flight
convergence-score: 0.0
convergence-trend: flat
generations-since-progress: 0
temperature: {user-supplied default, or 0.5}
temperature-floor: 0.1
last-reheat: null
reheat-triggers-armed:
  - eval-plateau-detected
  - architectural-blocker
  - debt-signal-spike
  - dissent-reactivation-cluster
wip-spread: 0.0
wip-in-flight:
  generators: 0
  evaluators: 0
  chavruta-pairs: 0
pareto-front: {}
pareto-front-source: {}
metastable-candidates: []
active-dissents: 0
dissents-reactivated: 0
last-dissent-check: null
hitl-mode: {user-supplied, default preference-articulator}
hitl-pending: 0
dispatch:
  orchestrator-policy: complexity-adaptive
  generators-per-gen-default: 5
  generators-per-gen-current: 5
  evaluator-depth: standard
  chavruta-on-convergence: true
  chavruta-on-major-spec-change: true
last-update: "{ISO8601 now}"
updated-by: flow-init
phase-log:
  - "{ISO8601} flow-init: effort {effort-slug} created from {seed-source}"
```

### Step 8: Validate

Read everything back and verify:
- `spec/spec.md` has at least one SR-{NNN}
- `spec/constitution.md` exists with non-empty prohibitions
- `evals/harness.yaml` validates
- `flow-state.yaml` validates
- `.gitignore` excludes working artifacts

### Step 9: Initial dissent check

Launch `~/.claude/commands/agents/flow-dissent-monitor.md` subagent (model: sonnet) — no-op for empty registry but confirms it can read state.

### Step 10: Report

Return summary:
- Effort slug
- Files created (with paths)
- SRs in spec (count + IDs)
- Eval dimensions configured
- HITL mode
- Next-step suggestion: `/flow-eval` to populate datasets, or `/flow-generate` to start gen-1

## Outputs

| Path | Purpose | Versioned? |
|------|---------|------------|
| `spec/spec.md` | Source of truth | Yes |
| `spec/constitution.md` | Governance | Yes |
| `spec/history/spec-v0.1.0-{date}.md` | First version record | Yes |
| `evals/harness.yaml` | Eval configuration | Yes |
| `evals/graders/{dimension}.md` | Per-dimension grader specs | Yes |
| `evals/datasets/{dimension}-{real|adv}-v1.jsonl` | Empty datasets | Yes |
| `.flow-index/` | Codebase index | No (gitignored) |
| `efforts/{slug}/flow-state.yaml` | Effort state | No (gitignored) |
| `.gitignore` | Updated to exclude working artifacts | Yes |

## HITL surface

Always preference-articulator mode for `flow-init`. The user is explicitly defining the effort's identity. Specific HITL prompts:

- Vague NL that can't be EARS-ified: counter-prompt
- Missing prohibitions: confirm "no explicit prohibitions" or solicit
- Customization of dispatch defaults: confirm or accept
- Existing flow-state would conflict: explicit choice to extend or rename

## Failure modes

- `--from-spec` document cannot be EARS-ified: halt; report which sections need clarification; suggest the user run `flow-spec` interactively
- `--from-delivery-team` source has no recoverable requirements: halt; suggest manual seed
- Working directory has uncommitted changes that conflict with `.gitignore` additions: halt; surface conflict

## Idempotency

`flow-init` is **not** idempotent. Re-running on an existing effort will halt at Step 1. To re-bootstrap, the user must delete or rename the existing effort directory first.
