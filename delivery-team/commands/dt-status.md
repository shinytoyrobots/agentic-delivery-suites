---
description: Read-only sprint status report — stories by status, blockers, velocity projection
argument-hint: "[sprint number or 'current']"
model: sonnet
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
capability-class: personal-tracking
tier: V
domain: [dt]
works-with:
  requires-context: [dt-artifact-schemas, dt-schemas-planning]
  upstream-skills: []
  downstream-skills: []
  compatible-agents: []
readiness:
  state: green
  idempotent: true
  warm-start: false
cost:
  model-class: low
  agent-count: 0
  web-calls: none
  context-budget: small
---

# Sprint Status

Read context files:
- `~/.claude/commands/context/dt-artifact-schemas.md`
- `~/.claude/commands/context/dt-schemas-planning.md`

## Purpose

Display the current sprint state. This is a read-only skill — it writes nothing. Use it to check progress, identify blockers, and project velocity at any time during a sprint.

## Input

`$ARGUMENTS` = sprint number, effort name, `{effort} {sprint-number}`, or "current" (default: current).

## Process

### Step 1: Locate Sprint State

Resolve the effort using the protocol in `context/dt-artifact-schemas.md`: check `$ARGUMENTS` for an explicit effort name, then `sprints/efforts.yaml` for the active effort, then fall back to the current branch slug. If ambiguous, list active efforts and ask the user.

Within the resolved effort directory, use Glob to find `sprint-status.yaml` in `sprints/{effort}/sprint-*/` (pick the highest-numbered sprint). If not found, report "No active sprint found for effort '{effort}'. Run `/sprint-start` to begin one."

### Step 2: Read Sprint Artifacts

Read `sprint-status.yaml` and parse:
- Sprint metadata (number, goal, status, dates, HITL level)
- All stories with their current status
- Any blocked-by dependencies

Also check for:
- `HITL-needed.md` — any open escalations
- `blocker.md` — any registered blockers
- `dependency-map.md` — dependency visualization

### Step 3: Calculate Metrics

- **Stories by status**: Count stories in each status (backlog, drafted, ready-for-dev, in-progress, review, validating, done)
- **Velocity projection**: Based on stories completed vs. elapsed sprint days, project whether the sprint goal is at risk
- **Blocker count**: Number of stories with non-empty `blocked-by` or status = blocked
- **Days remaining**: Target end date minus today

### Step 4: Display Report

```
## Sprint {N} Status — {YYYY-MM-DD}
**Goal**: {sprint goal}
**Stage**: {current pipeline stage}
**Days remaining**: {N} of {total}
**HITL level**: {level}

### Progress
{progress bar visualization}
Done: {N} | In Progress: {N} | Blocked: {N} | Remaining: {N}

### Stories
| ID | Title | Status | Agent | Blocked By | Gate |
|----|-------|--------|-------|------------|------|
| ... | ... | ... | ... | ... | ... |

### Blockers
{List any active blockers with story ID and description}

### Open Escalations
{List any HITL-needed.md items awaiting resolution}

### Velocity Projection
{On track / At risk / Behind — with reasoning}
```

## HITL Checkpoints

None — this is a read-only informational skill.

## Persistence

None — display only. No files are written.
