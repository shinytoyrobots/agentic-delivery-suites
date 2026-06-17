---
description: Discovery + Planning phases — consume specs, invoke enabling agents, shard stories, create sprint plan and Linear cycle
argument-hint: <spec/PRD path or "continue" to resume from project-kickoff>
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
  - mcp__claude_ai_Linear__save_issue
  - mcp__claude_ai_Linear__list_cycles
  - mcp__claude_ai_Linear__list_teams
  - mcp__claude_ai_Linear__list_issues
  - mcp__claude_ai_Linear__list_issue_labels
  - mcp__claude_ai_Linear__list_issue_statuses
capability-class: planning-design
tier: I
domain: [dt]
works-with:
  requires-context: [dt-pipeline-stages, dt-artifact-schemas, dt-schemas-planning, dt-hitl-protocol, dt-definition-of-done, dt-integration-map, vault-access]
  upstream-skills: []
  downstream-skills: [dt-story-review, dt-gate-review, dt-run]
  compatible-agents: [dt-user-researcher, dt-product-designer, dt-codebase-indexer, dt-aggressive-pm, dt-scrum-master]
readiness:
  state: green
  idempotent: false
  warm-start: true
cost:
  model-class: high
  agent-count: 5
  web-calls: none
  context-budget: xlarge
---

# Sprint Start

Read context files:
- `~/.claude/commands/context/dt-pipeline-stages.md`
- `~/.claude/commands/context/dt-artifact-schemas.md`
- `~/.claude/commands/context/dt-schemas-planning.md`
- `~/.claude/commands/context/dt-hitl-protocol.md`
- `~/.claude/commands/context/dt-definition-of-done.md`
- `~/.claude/commands/context/dt-integration-map.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Run Discovery (Stage 1) and Planning (Stage 3) phases for a sprint. This is the multi-phase skill that takes a spec/PRD from raw input to a fully sharded sprint plan with stories, dependencies, and a Linear cycle.

## Input

`$ARGUMENTS` = path to spec/PRD, a URL, or "continue" to pick up from an existing `project-kickoff.md`.

If `$ARGUMENTS` is empty, check for `project-kickoff.md` in the current directory. If found, use its spec/PRD reference. If not found, ask the user.

## Prerequisites

- `project-kickoff.md` must exist (run `/project-kickoff` first)
- `.codebase-index/` should be populated (run `/codebase-index` if stale)

Read `project-kickoff.md` to load: HITL level, stack, conventions, launch tier, agent activation plan, and **effort name**.

### Effort Resolution

See `dt-artifact-schemas.md` § Effort Resolution.

## Working Memory

Like deep-research, this skill uses disk as external memory across phases.

**Working directory**: `sprints/{effort}/sprint-{N}/` within the project working directory. Create this directory if it does not exist before writing any artifact.

**Files** (all written to `sprints/{effort}/sprint-{N}/`):
- `sprint-notes.md` — Running notes updated after each phase
- `sprint-plan.md` — Final sprint plan (produced in Phase 3)
- `sprint-status.yaml` — Sprint state file (produced in Phase 3)
- `dependency-map.md` — Story dependency graph (produced in Phase 3)
- `story-{id}.md` — Individual story files (produced in Phase 3)

Write after each phase. Read back at the start of the next phase.

## Phase 1: Discovery (Stage 1 — Problem Brief)

**Goal**: Understand the problem space, gather evidence, assess feasibility.

### Step 1: Consume Spec/PRD

Read the spec/PRD from the provided path. The path may be a single `.md` file (legacy) OR a directory containing a three-file `/pm-spec` bundle — see "Three-File Spec Consumption" below for the bundle case. Extract:
- Problem statement and user needs
- Proposed solution and scope
- Success metrics
- Constraints and dependencies
- Open questions

#### Three-File Spec Consumption

IF the path is a directory containing `requirements.md` AND `design.md` AND `tasks.md`, detect the three-file bundle format and read all three files rather than treating the path as a single spec. IF the directory contains only 1 or 2 of those files (partial bundle), emit an ADVISORY "Spec directory is missing one or more bundle files; falling through to single-file behavior" and treat the path as a single spec using whichever single file is present.

WHEN the three-file format is detected:
- Extract the Falsification Criteria block (Section 2 of `requirements.md`) verbatim and write it into `sprint-notes.md` (Step 4) under a heading `## Falsification Criteria (from spec)`. If that heading already exists in `sprint-notes.md`, skip re-insertion (warm-start guard).
- WHERE `requirements.md` Section 6 (Protection Patterns) is non-empty, carry its bullets into `sprint-notes.md` under a heading `## Protection Patterns (from spec)` so downstream dev agents inherit them.
- When sharding stories (Phase 3), preserve all `FR-n` and `AC-n` identifiers from `requirements.md` Section 4 verbatim — the skill SHALL NOT renumber, paraphrase, or rewrite the EARS statements or the falsification scenarios. Copy identifiers and text exactly.

### Step 2: Consume Upstream Planning Artifacts

Use Glob to check for recent upstream planning artifacts that inform this sprint:
- `docs/PM-Skills/**/*delivery-health*`
- `docs/PM-Skills/**/*risk-scan*`
- `docs/PM-Skills/**/*cycle-plan*`
- `docs/PM-Skills/**/*backlog-health*`

Read any found within the last 14 days. Extract velocity context, known risks, and scope guidance.

### Step 3: Invoke Enabling Agents (Parallel)

Launch enabling agents based on the project's agent activation plan from `project-kickoff.md`:

**Agent A: User Researcher** (if research needed)
Launch `~/.claude/commands/agents/dt-user-researcher.md` subagent (model: sonnet) to produce `sprints/{effort}/sprint-{N}/ux-research-brief.md` based on the spec/PRD and any existing research. Focus on: JTBD analysis, evidence quality assessment, persona identification, and research gaps.

**Agent B: Product Designer** (if design needed)
Launch `~/.claude/commands/agents/dt-product-designer.md` subagent (model: sonnet) to produce `sprints/{effort}/sprint-{N}/design-spec.md` and `sprints/{effort}/sprint-{N}/user-flow.md` based on the spec/PRD and codebase index (`.codebase-index/components.md`). The designer should check the design system for existing components before specifying new ones.

**Agent C: Codebase Index Staleness Check**
Launch `~/.claude/commands/agents/dt-codebase-indexer.md` subagent (model: haiku) to check `.codebase-index/.last-indexed` against `git rev-parse HEAD`. If stale, re-index.

### Step 4: Write Phase 1 Notes

Write findings to `sprints/{effort}/sprint-{N}/sprint-notes.md`: problem assessment, research brief summary, design direction, feasibility assessment, open questions.

### HITL Checkpoint — Phase 1

Check HITL level from `project-kickoff.md`:
- **Level 1**: Use `AskUserQuestion` — present the spec assessment, research brief, and design direction. Ask: "Approve this assessment to proceed to planning, or provide corrections."
- **Level 2-4**: Auto-advance to Phase 2.

## Phase 2: Design Intent (Stage 2)

**Goal**: Finalize design direction, confirm launch tier, align stakeholders, lock architecture proposal.

### Step 1: Review Phase 1 Outputs

Read `sprint-notes.md`, `ux-research-brief.md`, and `design-spec.md` from disk.

### Step 2: Architecture Proposal

Check for `sprints/{effort}/sprint-{N}/architecture-proposal.md`.

**If present**: read it. Verify it has been reviewed (look for `dt-architect-review-*.md` in the same directory with verdict `READY` or `MINOR REVISIONS`). If unreviewed, recommend running `/dt-architect-review` before proceeding — proceed anyway if the user confirms.

**If missing**: determine greenfield vs brownfield from `project-kickoff.md` (look for `project-type` or `existing-codebase` field) AND `.codebase-index/architecture.md` content (empty or missing → greenfield; populated → brownfield).

- **Greenfield**: auto-invoke `~/.claude/commands/agents/dt-architect.md` subagent inline (model: sonnet). Provide it the spec/PRD, project-kickoff.md, and any codebase index files. Capture stdout to `architecture-proposal.md`. Then auto-invoke `/dt-architect-review` against the produced file. If the review verdict is `BLOCKING REVISIONS`, halt and escalate to HITL.

- **Brownfield**: halt with HITL escalation per `dt-hitl-protocol`. Message: "No architecture-proposal.md found and project is not greenfield. Run `/dt-architect <spec-path>` before continuing, or set `--skip-architecture` flag if architecture is already settled and documented elsewhere."

If `--skip-architecture` was passed in `$ARGUMENTS`, skip Step 2 entirely with an `ADVISORY` note in `sprint-notes.md`: "Architecture proposal skipped by user. Story sharding will proceed without explicit architectural context."

### Step 3: Gate Review 1→2 (if applicable)

If the project warrants it (non-trivial scope), invoke gate review:
Launch `~/.claude/commands/agents/dt-aggressive-pm.md` subagent to evaluate whether the problem is worth solving. Provide the spec assessment, research brief, AND architecture proposal as context. The Aggressive PM should produce a Time Cost + Scope Integrity assessment, including assessment of architectural fit-for-purpose if a proposal exists.

### Step 4: Write Phase 2 Notes

Append to `sprints/{effort}/sprint-{N}/sprint-notes.md`: design decisions, architecture proposal summary (recommended option + walking-skeleton slice), gate review outcome, launch tier confirmation.

### HITL Checkpoint — Phase 2

- **Level 1-2**: Present design spec summary and gate review outcome. Ask: "Approve design direction to proceed to story sharding?"
- **Level 3-4**: Auto-advance to Phase 3.

## Phase 3: Planning (Stage 3 — Technical Spec)

**Goal**: Shard work into stories, build dependency map, create sprint plan, set up Linear cycle.

### Step 1: Story Sharding

Read `sprint-notes.md`, `architecture-proposal.md` (if present), and all Phase 1-2 outputs. Launch `~/.claude/commands/agents/dt-scrum-master.md` subagent to shard the work into stories.

If `architecture-proposal.md` is present, the scrum-master should consume:
- §11 (Vertical Slices) — each slice maps to ~1 story or a small cluster; preserve splitting hints (SPIDR / Humanizing Work) per slice
- §12 (Walking Skeleton) — the named slice becomes Story 1 and validates the architecture before breadth is added
- §10 (Fitness Functions) — these become acceptance criteria seeds for stories that touch the relevant components

Each story file (`story-{id}.md`) must include:
- YAML frontmatter: id, title, status (drafted), assigned-agent, priority, estimated-points, blocked-by, linear-id (null until created)
- Acceptance criteria in EARS format (Event-Action-Response-State)
- Task-to-AC mapping
- Architecture references (from `.codebase-index/` AND `architecture-proposal.md` §6/§9 if present)
- Agent assignment rationale

### Step 2: Dependency Mapping

Produce `dependency-map.md` showing which stories block which, optimal execution order, and parallelization opportunities. Identify the critical path.

### Step 3: Sprint Plan

Write `sprint-plan.md`:
```markdown
# Sprint {N} Plan
**Goal**: {sprint goal}
**Duration**: {start} — {end} ({N} days)
**Stories**: {count} ({total points} points)
**Critical path**: {story IDs}

## Story Sequence
| Order | Story | Agent | Points | Blocked By | Parallel? |
|-------|-------|-------|--------|------------|-----------|
| 1 | story-001 | backend-dev | 3 | — | Yes (with story-002) |
| ... |

## Risk Assessment
- {risk + mitigation}

## Agent Activation Timeline
- Day 1: {agents} start on {stories}
- Day 2: {agents} start on {stories} (after dependencies met)
- ...
```

### Step 4: Create sprint-status.yaml

Write `sprint-status.yaml` following the schema from context/dt-artifact-schemas.md. Set all stories to status `drafted`.

### Step 5: Create Linear Cycle + Issues

- Create a Linear cycle for this sprint
- Create Linear issues for each story with title, description, priority, and labels
- Update each `story-{id}.md` with the assigned `linear-id`
- Update `sprint-status.yaml` with Linear IDs

### HITL Checkpoint — Phase 3

- **Level 1-2**: Present the sprint plan. Ask: "Approve this sprint plan to begin implementation?"
- **Level 3-4**: Auto-advance. Notify: "Sprint plan created. Run `/sprint-run` to begin implementation."

## Gate Review 2→3 and 3→4

If the project warrants adversarial review before build, advise the user: "Run `/gate-review 3` for adversarial PM review before starting `/sprint-run`."

## Persistence

- All working artifacts written to `sprints/{effort}/sprint-{N}/` within the project working directory
- Sprint summaries (after completion, via `/sprint-close`) persist to `docs/Delivery-Team/{date}/`

## Chaining

After sprint-start completes:
> Sprint {N} planned with {count} stories. Next steps:
> - `/story-review` — QA shift-left review of stories before dev (recommended)
> - `/gate-review 3` — adversarial PM review of technical spec
> - `/sprint-run` — begin implementation
