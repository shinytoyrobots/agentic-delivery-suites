---
description: Release retrospective — compare planned vs actual, audit feature flags, surface recurring release process issues
argument-hint: "[effort name or 'current']"
model: sonnet
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
capability-class: retrospective-learning
tier: II
domain: [dt]
works-with:
  requires-context: [dt-release-patterns, dt-artifact-schemas, dt-pipeline-stages]
  upstream-skills: [dt-release, dt-release-monitor]
  downstream-skills: [dt-close, dt-start]
  compatible-agents: []
readiness:
  state: green
  idempotent: false
  warm-start: true
cost:
  model-class: medium
  agent-count: 0
  web-calls: none
  context-budget: medium
---

# Release Retrospective

Read context files:
- `~/.claude/commands/context/dt-release-patterns.md`
- `~/.claude/commands/context/dt-artifact-schemas.md`
- `~/.claude/commands/context/dt-pipeline-stages.md`

## Purpose

Synthesize release-specific learnings after a release cycle completes. Compares planned vs actual release execution, audits feature flag cleanup, and pattern-matches against prior release retros to surface recurring issues. This is a release-focused complement to the sprint retrospective (now part of `/dt-close`).

## Input

`$ARGUMENTS` = effort name or "current". Default: current effort.

See `dt-artifact-schemas.md` § Effort Resolution.

## Prerequisites

- `release-plan.md` — original release plan with risk score and V1 threshold
- `deployment-status.md` — actual deployment execution record
- `release-health-brief.md` — monitoring results (if generated)
- `sprint-{N}-summary.md` — sprint completion data

Read all available prerequisites. If some are missing (e.g., no monitoring was done), note the gap and proceed with available data.

## Process

### Step 1: Planned vs Actual Comparison

Read `release-plan.md` and `deployment-status.md`. Compare:

| Dimension | Planned | Actual | Assessment |
|-----------|---------|--------|------------|
| Risk score | {from release-plan} | {actual incidents/issues} | {Accurate / Underestimated / Overestimated} |
| Rollout timeline | {planned rings + timing} | {actual progression} | {On schedule / Delayed / Accelerated} |
| Incident count | 0 (target) | {actual} | {Clean / Issues encountered} |
| V1 threshold | {defined threshold} | {was it reached? was it useful?} | {Appropriate / Too early / Too late / Not applicable} |
| Communication plan | {planned tier × phase} | {what was actually sent} | {Complete / Gaps / Over-communicated} |

### Step 2: Feature Flag Audit

Scan the codebase and flag management context for:

1. **Flags at 100% for >30 days**: Should be cleaned up. List each with creation date and current state.
2. **Stale flag percentage**: Total flags in codebase vs flags actively varying. Target: <20% stale.
3. **Flags missing from definition of done**: Any completed stories where the flag removal was not included in story completion criteria.
4. **Orphaned flags**: Flags without clear ownership (no linked Linear issue, no recent changes).

Use `AskUserQuestion` if needed: "Are there feature flags from this release that should be cleaned up? List any flag names you're aware of."

### Step 3: Cross-Release Pattern Matching

Search vault for prior release retros:
- Glob: `docs/Delivery-Team/**/*release-retro*`

If prior retros exist, compare:
- Are the same issues recurring? (e.g., "communication gaps" appearing in multiple retros)
- Are prior action items being addressed?
- Is risk scoring accuracy improving over time?

### Step 4: Generate Release Retrospective

Write `release-retro.md`:

```markdown
# Release Retrospective: {Feature/Effort}
**Generated**: {YYYY-MM-DD HH:MM}
**Skill**: /dt-release-retro
**Release date**: {date}
---

## Planned vs Actual
| Dimension | Planned | Actual | Assessment |
|-----------|---------|--------|------------|
| ... |

## What Went Well
{Bullets — specific to the release process, not the sprint}

## What To Improve
{Bullets — actionable, specific}

## Feature Flag Audit
### Flags Needing Cleanup
| Flag | Created | Status | Action |
|------|---------|--------|--------|
| ... |

### Flag Health
- Total flags: {N}
- Stale (>30 days at 100%): {N} ({%})
- Orphaned: {N}

## Recurring Patterns
{Comparison with prior release retros — what keeps coming up?}

## Action Items
1. {Action} — Owner: {name} — Due: {date}
2. ...

## Process Improvement Recommendations
{Specific changes to the release process for next time}
```

## HITL Behavior

Advisory at all levels. Present the retrospective for review but do not require approval.

Use `AskUserQuestion` at the end: "Any additional observations about this release that should be captured?"

## Persistence

Write `release-retro.md` to `sprints/{effort}/sprint-{N}/`.

Write to vault: `docs/Delivery-Team/{date}/release-retro.md`

## Chaining

After release retro:
- `/dt-close` — sprint close now includes the full retrospective (release retro feeds into it)
- `/dt-start` — begin next sprint with release learnings in context
