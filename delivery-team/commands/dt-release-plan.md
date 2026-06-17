---
description: Pre-release planning — risk assessment, V1 threshold, rollback strategy, feature flag config, stakeholder communication plan
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
capability-class: planning-design
tier: II
domain: [dt]
works-with:
  requires-context: [dt-release-patterns, dt-artifact-schemas, dt-hitl-protocol, vault-access]
  upstream-skills: [dt-close, dt-gate-review]
  downstream-skills: [dt-readiness-gate, dt-release-comms]
  compatible-agents: [dt-release-scorer]
readiness:
  state: green
  idempotent: false
  warm-start: false
cost:
  model-class: high
  agent-count: 1
  web-calls: none
  context-budget: medium
---

# Release Plan

Read context files:
- `~/.claude/commands/context/dt-release-patterns.md`
- `~/.claude/commands/context/dt-artifact-schemas.md`
- `~/.claude/commands/context/dt-hitl-protocol.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Produce a structured release plan before cross-functional readiness (Stage 5). This skill ensures all release decisions — risk assessment, rollback thresholds, flag configuration, and communication strategy — are pre-committed before deployment, not improvised under pressure. The V1 threshold concept (from aviation) is central: define the point beyond which rollback is more dangerous than forward-fixing.

## Input

`$ARGUMENTS` = effort name or "current". Default: current effort.

See `dt-artifact-schemas.md` § Effort Resolution.

## Prerequisites

- `sprint-status.yaml` — all stories in `done` status (build complete)
- `qa-gate.md` files — QA verification results
- `project-kickoff.md` — project context (stack, conventions)
- `api-contract.yaml` — if API changes are involved
- `launch-tier.md` — if already determined (from Marketing Agent at Stage 2)

Read all available prerequisites. If stories are not all `done`, warn: "Build phase incomplete. Release planning is most accurate after all stories pass QA. Proceed anyway?"

## Phase 1: Risk Assessment

### Step 1: Launch Release Scorer

Launch `~/.claude/commands/agents/dt-release-scorer.md` subagent (model: sonnet) to assess release risk. Provide:
- `sprint-status.yaml`
- All `qa-gate.md` files
- `api-contract.yaml` (if exists)
- All `story-{id}.md` files
- `project-kickoff.md`

The scorer returns a risk verdict (LOW/MEDIUM/HIGH) with top 3 contributing factors and a recommended rollout pattern.

### Step 2: Review Risk Assessment

Read the scorer's output. If risk is HIGH, flag for special attention in subsequent phases.

## Phase 2: Release Plan Synthesis

### Step 1: Define V1 Threshold

Apply the V1 threshold framework from `context/dt-release-patterns.md` (V1 Threshold section). Scale the threshold duration based on risk score and rollback mechanism. For database-aware rollback, map the specific expand-contract phase that constitutes V1.

Present the proposed V1 threshold to the user for confirmation.

### Step 2: Define Rollback Strategy

Based on risk assessment and available mechanisms:

1. **Classify mechanism**: Flag-based / blue-green / rolling / manual / DB-aware
2. **Document rollback steps**: Specific, executable steps — not abstract guidance
3. **Database migration handling**: If DDL present, map expand-contract phases and point-of-no-return
4. **Apply heuristic**: Additive changes → fix forward. Destructive changes → pre-defined rollback.

### Step 3: Define Feature Flag Configuration

For each feature being released:
1. **Flag name**: Following naming convention (e.g., `release_feature_name`)
2. **Flag type**: Release toggle (temporary) or permissioning toggle (permanent)
3. **Targeting rules**: Ring-based (Ring 0 → internal, Ring 1 → sponsors, etc.)
4. **Kill switch**: Confirm kill switch is configured for immediate disable
5. **Expiration date**: Specific calendar date for flag removal
6. **Cleanup PR**: Confirm removal PR exists or is planned

### Step 4: Define Rollout Strategy

Based on risk score and traffic context:

- **LOW risk**: Ring 0 (internal, 30 min) → Ring 3 (GA)
- **MEDIUM risk**: Ring 0 (1 hr) → Ring 1 (sponsors, 4 hr) → Ring 3 (GA)
- **HIGH risk**: Ring 0 (1 hr) → Ring 1 (4 hr) → Ring 2 (24 hr) → Ring 3 (GA)

Use `AskUserQuestion` to confirm: "Based on {RISK} risk, recommended rollout is {pattern}. Adjust?"

## Phase 3: Communication Plan

### Step 1: Generate Tier × Phase Matrix

For each of the 5 stakeholder tiers (from `context/dt-release-patterns.md`), define communication at 3 phases:

| Tier | Pre-Release | Release | Post-Release |
|------|------------|---------|-------------|
| Engineering | Deploy briefing, on-call assignment | Real-time status in Slack | Monitoring alerts, RCA if needed |
| CS/Support | Feature briefing, FAQ prep | Feature available notification | Support ticket monitoring |
| Sales | Feature brief, demo prep | Feature available for prospects | Adoption metrics |
| Executives | Risk summary, timeline | Launch confirmation | Impact summary |
| End Users / Sponsors | Beta invite (Ring 1) | GA announcement | Follow-up, feedback request |

### Step 2: Determine Launch Tier Content Requirements

Read `launch-tier.md` if available. Reference tier content requirements from `context/dt-release-patterns.md`:
- **Tier 1**: Changelog + blog + social + email + landing page + internal announcement
- **Tier 2**: Changelog + blog + social + internal announcement
- **Tier 3**: Changelog + internal announcement

## Phase 4: Produce Release Plan

Write `release-plan.md`:

```markdown
# Release Plan: {Feature/Effort}
**Generated**: {YYYY-MM-DD HH:MM}
**Skill**: /dt-release-plan
**Launch Tier**: {1/2/3}
---

## Risk Assessment
### Verdict: {LOW / MEDIUM / HIGH}
### Top Risk Factors
1. {factor + evidence}
2. {factor + evidence}
3. {factor + evidence}

### Database Migrations: {YES / NO}
{If YES: migration type, expand-contract phase mapping, point-of-no-return}

## V1 Threshold
**Definition**: {specific threshold}
**Rationale**: {why this threshold was chosen}
- Below V1: Rollback freely at any anomaly
- Above V1: Forward-fix only

## Rollback Strategy
**Mechanism**: {flag-based / blue-green / rolling / DB-aware}
### Rollback Steps
1. {specific step}
2. {specific step}
...

## Feature Flags
| Flag Name | Type | Targeting | Kill Switch | Expiration | Cleanup PR |
|-----------|------|-----------|-------------|------------|------------|
| ... |

## Rollout Strategy
| Ring | Audience | Duration | Success Criteria | Advance Condition |
|------|----------|----------|-----------------|-------------------|
| Ring 0 | Internal | {time} | No Tier 1 anomalies | Human go/no-go |
| ... |

## Communication Plan
| Tier | Pre-Release | Release | Post-Release |
|------|------------|---------|-------------|
| Engineering | ... | ... | ... |
| CS/Support | ... | ... | ... |
| Sales | ... | ... | ... |
| Executives | ... | ... | ... |
| End Users | ... | ... | ... |

## Pre-Release Checklist
- [ ] Monitoring configured and alerts set for 5 SLIs: {list}
- [ ] Feature flags configured with targeting rules
- [ ] Kill switch tested
- [ ] Rollback procedure documented and tested
- [ ] On-call coverage confirmed
- [ ] Internal team briefed
- [ ] {Additional items based on risk level}
```

## HITL Checkpoint — Always Required

Use `AskUserQuestion`:

"Release plan complete for {feature}. Risk: {RISK}. V1 threshold: {threshold}.

Key details:
- Rollback mechanism: {type}
- Rollout strategy: {ring summary}
- Database migrations: {YES/NO}

**Approve this release plan to proceed to cross-functional readiness (`/dt-readiness-gate`)?**"

## Persistence

Write `release-plan.md` to `sprints/{effort}/sprint-{N}/`.

Write to vault: `docs/Delivery-Team/{date}/release-plan.md`

## Chaining

After release plan:
> Release plan approved. Next steps:
> - `/dt-readiness-gate` — run cross-functional readiness check (reads release-plan.md)
> - `/dt-gate-review 5` — adversarial PM review of release readiness
