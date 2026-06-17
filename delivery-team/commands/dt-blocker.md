---
description: Register a blocker against a story — updates sprint state and creates HITL escalation
argument-hint: <story-id> <blocker description>
model: sonnet
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - mcp__claude_ai_Linear__get_issue
  - mcp__claude_ai_Linear__save_issue
  - mcp__claude_ai_Linear__save_comment
capability-class: planning-design
tier: IV
domain: [dt]
works-with:
  requires-context: [dt-artifact-schemas, dt-schemas-planning, dt-schemas-build, dt-hitl-protocol]
  upstream-skills: [dt-run, dt-status]
  downstream-skills: [dt-run]
  compatible-agents: []
readiness:
  state: green
  idempotent: false
  warm-start: false
cost:
  model-class: low
  agent-count: 0
  web-calls: none
  context-budget: small
---

# Sprint Blocker

Read context files:
- `~/.claude/commands/context/dt-artifact-schemas.md`
- `~/.claude/commands/context/dt-schemas-planning.md`
- `~/.claude/commands/context/dt-schemas-build.md`
- `~/.claude/commands/context/dt-hitl-protocol.md`

## Purpose

Register a blocker against a specific story. This updates `sprint-status.yaml`, creates a `blocker.md` file, produces `HITL-needed.md` for human intervention, and syncs the blocker to Linear.

## Input

`$ARGUMENTS` = `<story-id> <blocker description>`

Parse `$ARGUMENTS` to extract the story ID (e.g., `story-042`) and the blocker description (everything after the story ID).

If story ID is missing or cannot be parsed, list stories from `sprint-status.yaml` and ask the user to specify.

## Process

### Step 1: Validate Story

See `dt-artifact-schemas.md` § Effort Resolution. Read `sprint-status.yaml` from the resolved effort's current sprint and confirm the story ID exists. If not found, report available stories and exit.

### Step 2: Classify Blocker

Determine the blocker type from the description:
- **technical** — code dependency, infrastructure issue, environment problem
- **external** — waiting on third-party API, vendor response, external team
- **design** — design spec incomplete, accessibility concern, UX ambiguity
- **scope** — requirement ambiguity, conflicting specs, missing acceptance criteria
- **resource** — agent failure, tool unavailability

### Step 3: Update sprint-status.yaml

Edit the story entry to:
- Set status to the appropriate blocked state
- Add the blocker to `blocked-by` list
- Set `hitl-checkpoint: true`

### Step 4: Write blocker.md

Write `blocker.md` to `sprints/{effort}/sprint-{N}/`:

```markdown
# Blocker: {story-id}
**Date**: {YYYY-MM-DD}
**Type**: {blocker type}
**Story**: {story title}
**Description**: {blocker description}
**Impact**: {what is blocked and what cannot proceed}
**Suggested resolution**: {if apparent from context}
**Status**: open
```

### Step 5: Write HITL-needed.md

Write `HITL-needed.md` following the schema from context/dt-artifact-schemas.md:

```yaml
---
date: {YYYY-MM-DD}
sprint: {N}
story-id: {story-id}
escalation-type: blocker
summary: "{blocker description}"
context: "{impact context}"
options:
  - option-A: "{resolution option if known}"
recommendation: "{recommendation if clear}"
awaiting: true
---
```

### Step 6: Sync to Linear

If the story has a `linear-id` in sprint-status.yaml:
- Add a comment to the Linear issue describing the blocker
- Update the issue status to Blocked if Linear supports it

### Step 7: Report

Display the blocker registration confirmation:
```
Blocker registered for {story-id}: {description}
Type: {type}
HITL escalation created — awaiting human resolution.
Sprint status updated.

Resolve with: edit HITL-needed.md and set awaiting: false, then run /sprint-run to continue.
```

## HITL Checkpoints

This skill always produces a HITL escalation — that is its purpose. The blocker requires human intervention to resolve.

## Persistence

All sprint artifacts are written to `sprints/{effort}/sprint-{N}/`:
- `blocker.md`
- `HITL-needed.md`
- `sprint-status.yaml` — updated in place
