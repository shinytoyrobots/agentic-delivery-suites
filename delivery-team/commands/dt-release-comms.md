---
description: Audience-tiered release communications — generate changelog variants, sponsor comms, GA comms, and rollback comms for 5 stakeholder tiers
argument-hint: "[release|rollback] [effort name or 'current']"
model: sonnet
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
  - mcp__claude_ai_Linear__list_issues
  - mcp__claude_ai_Linear__get_issue
capability-class: content-production
tier: II
domain: [dt]
works-with:
  requires-context: [dt-release-patterns, dt-artifact-schemas, dt-pipeline-stages, vault-access]
  upstream-skills: [dt-readiness-gate, dt-release-plan]
  downstream-skills: [dt-release]
  compatible-agents: [dt-release-communicator]
readiness:
  state: green
  idempotent: false
  warm-start: false
cost:
  model-class: medium
  agent-count: 1
  web-calls: none
  context-budget: medium
---

# Release Communications

Read context files:
- `~/.claude/commands/context/dt-release-patterns.md`
- `~/.claude/commands/context/dt-artifact-schemas.md`
- `~/.claude/commands/context/dt-pipeline-stages.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Generate audience-tiered release communications from canonical pipeline data. Supports two modes: **release** (standard feature announcement across 5 stakeholder tiers) and **rollback** (pharma 3-phase rollback communication). Can be invoked standalone or called by `/dt-release` at each ring stage.

## Input

`$ARGUMENTS` = mode ("release" or "rollback") + optional effort name. Default: "release current".

Parse arguments:
- First word: mode (release/rollback). Default: release.
- Remaining: effort name. Default: current effort from `context/dt-artifact-schemas.md`.

## Prerequisites

### Release Mode
- `release-plan.md` — risk level, rollout strategy, communication plan
- `sprint-status.yaml` — completed stories
- `story-{id}.md` files — feature descriptions
- `launch-tier.md` — determines content scope
- `cross-functional-readiness.md` — readiness artifacts (changelog draft, support brief)

### Rollback Mode
- `release-plan.md` — rollback strategy, affected features
- `deployment-status.md` — current rollout state, affected population

Read all available prerequisites. Note any missing inputs.

## Release Mode Process

### Step 1: Gather Canonical Data

Read sprint artifacts, Linear issues (for feature descriptions), and any existing drafts from the Marketing Agent (`changelog-draft.md` from Stage 5 readiness).

### Step 2: Launch Communicator Agent

Launch `~/.claude/commands/agents/dt-release-communicator.md` subagent (model: sonnet) in release mode. Provide all gathered canonical data. The communicator generates 5-tier content.

### Step 3: Assemble Release Comms

Write `release-comms.md`:

```markdown
# Release Communications: {Feature/Effort}
**Generated**: {YYYY-MM-DD HH:MM}
**Skill**: /dt-release-comms
**Launch Tier**: {1/2/3}
**Mode**: release
---

## Engineering
### Technical Changelog
{Commit-level detail, breaking changes, new dependencies}

### Rollback Procedures
{Flag names, toggle instructions, rollback steps}

### Monitoring
{SLIs to watch, alert thresholds}

---

## CS / Support
### Impact Summary
{Which customers/segments affected, what changes}

### Customer Talking Points
{3-5 bullets for customer conversations}

### FAQ
{Anticipated questions with answers}

### Workarounds
{If feature has known limitations}

---

## Sales
### Feature Brief
{What it does, who it's for, competitive positioning}

### Demo Readiness
{Is it demo-able, setup needed}

### Prospect Impact
{Pipeline deals that should know}

---

## Executives
### Business Impact
{One paragraph — what shipped, why it matters}

---

## Customer Sponsors
**[DRAFT — REQUIRES HUMAN REVIEW]**
### Partner Notification
{Collaborative framing — "your feedback shaped X"}

---

## End Users (GA)
**[DRAFT — REQUIRES HUMAN REVIEW]**
### What's New
{User-facing feature description in benefit terms}

### Getting Started
{Brief how-to guidance}
```

### Step 4: HITL Review

Use `AskUserQuestion`:

"Release communications generated for {feature} across 5 tiers.

External-facing content (Sponsors + End Users) is marked as DRAFT and requires your review before sending.

**Review and approve the communications?** You can edit `release-comms.md` directly, or provide feedback here."

## Rollback Mode Process

### Step 1: Gather Rollback Context

Read `release-plan.md` (rollback strategy), `deployment-status.md` (current state, affected population), and any incident notes.

Use `AskUserQuestion`:
- "What is the reason for the rollback?"
- "What features/functionality are affected?"
- "What is the estimated time to restore stable service?"
- "Are any customer segments more affected than others?"

### Step 2: Launch Communicator Agent in Rollback Mode

Launch `~/.claude/commands/agents/dt-release-communicator.md` subagent (model: sonnet) in rollback mode. The communicator follows the pharma 3-phase model.

### Step 3: Assemble Rollback Comms

Write `release-comms.md` (overwrite existing):

```markdown
# Rollback Communications: {Feature/Effort}
**Generated**: {YYYY-MM-DD HH:MM}
**Skill**: /dt-release-comms rollback
**Mode**: rollback
---

## Phase 1: DECISION (Engineering Only)
{Rollback notification — what, why, ETA, incident commander}

## Phase 2: SCOPE PER TIER

### Engineering
{Commits reverted, schema rollback status, flags disabled}

### CS / Support
{Feature unavailability, affected customers, workaround, do not promise fix time}

### Sales
{Demo env impact, pipeline deal guidance}

### Executives
{Service impact summary, rollback status, no data loss confirmation}

### Enterprise Sponsors
**[DRAFT — REQUIRES HUMAN REVIEW]**
{Issue identified, reverting to stable, data intact, will notify when restored}

### End Users
**[DRAFT — REQUIRES HUMAN REVIEW]**
{Status page message — issues with feature, team working on fix}

## Phase 3: RESTART AUTHORIZATION (All-Clear)
{Tiered resolution messages — to be sent after service is restored}

### Engineering All-Clear
{Service restored, monitoring period, RCA timeline}

### CS/Support All-Clear
{Fully restored, no customer action needed, post-incident report timeline}

### Executive All-Clear
{Resolved, impact duration, RCA date}

### Sponsor/User All-Clear
**[DRAFT — REQUIRES HUMAN REVIEW]**
{Service restored, post-incident report timeline}
```

### Step 4: HITL Review (Always Required for Rollback)

Use `AskUserQuestion`:

"Rollback communications generated using the pharma 3-phase model.

Phase 1 (DECISION) — ready for immediate send to Engineering
Phase 2 (SCOPE PER TIER) — ready for distribution to all 5 tiers
Phase 3 (ALL-CLEAR) — pre-written, to be sent after service is restored

External-facing content is DRAFT. **Approve Phase 1 for immediate send?**"

## Persistence

Write `release-comms.md` to `sprints/{effort}/sprint-{N}/`.

## Chaining

After release comms:
- **Release mode**: "Communications ready. Proceed with `/dt-release` for rollout execution."
- **Rollback mode**: "Rollback communications ready. Execute rollback steps from `release-plan.md`. Send Phase 3 (all-clear) after service is restored."
