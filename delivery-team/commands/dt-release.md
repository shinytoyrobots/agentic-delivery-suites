---
description: Release execution orchestration — deployment verification, progressive rollout through rings, monitoring coordination, communication publication
argument-hint: "[effort name or 'current']"
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
  - mcp__claude_ai_Linear__list_issues
  - mcp__claude_ai_Linear__get_issue
  - mcp__claude_ai_Linear__save_issue
  - mcp__claude_ai_Linear__save_comment
  - mcp__claude_ai_Slack__slack_send_message_draft
  - mcp__claude_ai_Slack__slack_read_channel
  - mcp__claude_ai_Slack__slack_search_channels
capability-class: release-operations
tier: I
domain: [dt]
works-with:
  requires-context: [dt-release-patterns, dt-artifact-schemas, dt-hitl-protocol, vault-access]
  upstream-skills: [dt-release-plan, dt-readiness-gate]
  downstream-skills: [dt-release-monitor, dt-close, dt-release-retro]
  compatible-agents: [dt-release-communicator]
readiness:
  state: green
  idempotent: false
  warm-start: true
cost:
  model-class: high
  agent-count: 1
  web-calls: none
  context-budget: medium
---

# Release Execution

Read context files:
- `~/.claude/commands/context/dt-release-patterns.md`
- `~/.claude/commands/context/dt-artifact-schemas.md`
- `~/.claude/commands/context/dt-hitl-protocol.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Orchestrate Stage 6 (Communication + Release) of the delivery pipeline. Coordinates deployment verification, progressive rollout through ring stages, health monitoring, and audience-tiered communication publication.

All user decisions throughout this skill use `AskUserQuestion`. Subsequent steps specify question content only.

## Input

`$ARGUMENTS` = effort name, "current", or a specific ring to resume from (e.g., "ring-2"). Default: current effort, starting from Ring 0.

See `dt-artifact-schemas.md` § Effort Resolution.

## Prerequisites

- `release-plan.md` — approved release plan with risk score, V1 threshold, rollout strategy, feature flags, communication plan (**required** — run `/dt-release-plan` first)
- `cross-functional-readiness.md` — cross-functional readiness verdict (**required** — run `/dt-readiness-gate` first)
- `sprint-status.yaml` — all stories `done`
- `project-kickoff.md` — project context

Read all prerequisites. If `release-plan.md` or `cross-functional-readiness.md` is missing, exit: "Release plan and cross-functional readiness are required. Run `/dt-release-plan` then `/dt-readiness-gate` first."

Verify cross-functional readiness verdict is GO or CONDITIONAL GO. If NO-GO, exit: "Cross-functional readiness is NO-GO. Address gaps before proceeding."

## Phase 1: Pre-Deployment Verification

### Step 1: Verify Release Readiness

Verify deployment prerequisites from the release plan's pre-release checklist:
- Monitoring configured with alerts for the 5 SLIs?
- Feature flags configured with targeting rules?
- Kill switch tested?
- On-call coverage confirmed?
- Code deployed to release environment?

### Step 2: Initialize Deployment Status

Write `deployment-status.md`:

```markdown
# Deployment Status: {Feature/Effort}
**Generated**: {YYYY-MM-DD HH:MM}
**Skill**: /dt-release
**Release Plan**: release-plan.md
---

## Current Stage: Pre-deployment
## Deployment Health: PENDING
## V1 Status: BELOW V1

### Rollout Progress
| Ring | Audience | Target Duration | Status | Started | Completed |
|------|----------|----------------|--------|---------|-----------|
| Ring 0 | Internal | {from plan} | PENDING | — | — |
| Ring 1 | Sponsors | {from plan} | PENDING | — | — |
| Ring 2 | Early Adopters | {from plan} | PENDING | — | — |
| Ring 3 | GA | {from plan} | PENDING | — | — |

### Monitoring Summary
{Updated at each ring stage}

### Comms Status
| Tier | Pre-Release | Release | Post-Release |
|------|------------|---------|-------------|
| Engineering | PENDING | — | — |
| CS/Support | PENDING | — | — |
| Sales | PENDING | — | — |
| Executives | PENDING | — | — |
| End Users | — | — | — |

### Next Action
Proceed to Ring 0 deployment.
```

## Phase 2: Progressive Rollout (Loop)

For each ring stage defined in the release plan:

### Step 1: Activate Ring

Update `deployment-status.md`:
- Set current ring status to IN PROGRESS
- Set ring start time
- Update deployment health to GREEN (initial)

Announce to user: "Entering Ring {N} ({audience}). Duration: {target}."

### Step 2: Generate Ring Communications

Launch `~/.claude/commands/agents/dt-release-communicator.md` subagent (model: sonnet) in release mode. Provide:
- `release-plan.md`
- `deployment-status.md`
- All `story-{id}.md` files
- `cross-functional-readiness.md`
- Current ring stage

The communicator generates tier-appropriate content for the current ring (see ring-to-tier mapping in `context/dt-release-patterns.md`). Write communications to `release-comms.md`.

### Step 3: Monitoring Pause

After ring activation, pause for the target duration defined in the release plan. Collect monitoring data:
- **Ring 0-1**: "Report monitoring observations: error rates, latency, any issues?"
- **Ring 2-3**: Run `/dt-release-monitor {tier}` inline or prompt for health data

### Step 4: Health Assessment

If monitoring data indicates issues:
- **GREEN** (no anomalies): Recommend advancing to next ring
- **YELLOW** (ambiguous signal): Recommend extending bake time at current ring
- **RED** (clear anomaly): Check V1 status and recommend accordingly

Update `deployment-status.md` with monitoring summary and health status.

### Step 5: Ring Transition — Go/No-Go (Always HITL)

Use `AskUserQuestion`:

"Ring {N} complete. Health: {GREEN/YELLOW/RED}.

Monitoring summary: {key metrics}
V1 status: {BELOW/ABOVE}

**Decision:**
- **ADVANCE** — proceed to Ring {N+1}
- **HOLD** — extend bake time at Ring {N}
- **ROLLBACK** — execute rollback plan (only if BELOW V1)"

If ROLLBACK:
1. Launch communicator agent in rollback mode (pharma 3-phase)
2. Present rollback communications for approval
3. Update deployment status to ROLLED BACK
4. Exit with: "Rollback communications prepared. Execute rollback steps from `release-plan.md`. Run `/dt-release-comms rollback` if additional communication is needed."

If HOLD:
1. Update deployment status
2. Loop back to Step 3 (monitoring pause) with extended duration

If ADVANCE:
1. Update ring status to COMPLETE
2. Check if V1 threshold is now crossed — update V1 status if so
3. Proceed to next ring (loop back to Step 1)

### Step 6: V1 Threshold Tracking

After each ring completion, evaluate V1:
- If V1 conditions are now met (e.g., time at Ring 3 exceeded threshold), update `deployment-status.md` V1 status to ABOVE V1
- Announce to user: "V1 threshold crossed. From this point, forward-fix is preferred over rollback."

## Phase 3: Release Complete

When the final ring completes successfully:

### Step 1: Update Deployment Status

Set all rings to COMPLETE. Set deployment health to GREEN. Set overall status to RELEASED.

### Step 2: Final Communications

Ensure all tier communications have been sent/drafted:
- Verify comms status matrix in `deployment-status.md`
- Flag any missing communications

### Step 3: Update Linear

Update Linear issues to reflect release status. Add release date comment.

### Step 4: Final Report

Display release summary:
```
## Release Complete: {Feature}
Released: {date/time}
Total rollout time: {duration}
Rings completed: {N}/{total}
Incidents during rollout: {N}
V1 status: {BELOW/ABOVE}
```

## HITL Summary

| Action | HITL Required |
|--------|---------------|
| Pre-deployment verification | Always |
| Ring transition go/no-go | Always |
| Rollback decision | Always |
| External communications send | Always |
| Internal communications | Advisory |

## Persistence

Write `deployment-status.md` to `sprints/{effort}/sprint-{N}/` — updated continuously throughout execution.

Write `release-comms.md` to `sprints/{effort}/sprint-{N}/`.

Write to vault: `docs/Delivery-Team/{date}/deployment-status.md`

## Chaining

After release:
> Release complete. {Feature} at Ring {N} (GA). Next steps:
> - `/dt-release-monitor 3` — 24-72 hr business metrics check
> - `/dt-close` — close sprint and produce summary
> - `/dt-release-retro` — release-specific retrospective
