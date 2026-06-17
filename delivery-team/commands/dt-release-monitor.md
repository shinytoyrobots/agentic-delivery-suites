---
description: Post-deploy health brief — synthesize monitoring data into structured assessment with PROCEED/INVESTIGATE/ROLLBACK recommendation
argument-hint: "[tier 1|2|3] or 'all'"
model: sonnet
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
capability-class: synthesis-analysis
tier: III
domain: [dt]
works-with:
  requires-context: [dt-release-patterns, dt-artifact-schemas, dt-pipeline-stages]
  upstream-skills: [dt-release]
  downstream-skills: [dt-release, dt-release-comms]
  compatible-agents: []
readiness:
  state: green
  idempotent: false
  warm-start: true
cost:
  model-class: low
  agent-count: 0
  web-calls: none
  context-budget: small
---

# Release Monitor

Read context files:
- `~/.claude/commands/context/dt-release-patterns.md`
- `~/.claude/commands/context/dt-artifact-schemas.md`
- `~/.claude/commands/context/dt-pipeline-stages.md`

## Purpose

Generate a structured post-deploy health brief at each monitoring tier. This skill synthesizes user-provided monitoring data into a clear PROCEED / INVESTIGATE / ROLLBACK recommendation. It does not directly access monitoring systems — it structures what the user observes.

## Input

`$ARGUMENTS` = monitoring tier ("1", "2", "3") or "all" for sequential assessment. Default: "1".

See `dt-artifact-schemas.md` § Effort Resolution.

## Prerequisites

- `release-plan.md` — pre-defined SLIs and V1 threshold
- `deployment-status.md` — current rollout state (if exists)

Read all prerequisites. If `release-plan.md` is missing, ask the user for the 5 SLIs and V1 threshold before proceeding.

## Process

### Step 1: Load Release Context

Read `release-plan.md` for:
- Pre-defined SLIs (5 metrics to monitor)
- V1 threshold definition
- Current rollout ring stage
- Rollback strategy

Read `deployment-status.md` for:
- Current ring stage
- V1 status (BELOW / ABOVE)
- Prior monitoring results (if Tier 2 or 3)

### Step 2: Gather Monitoring Data

Use `AskUserQuestion` to collect current metric values. Adapt questions to the monitoring tier:

**Tier 1 (0-15 min — Immediate)**
- "What are the current error rates for the deployed service? (e.g., HTTP 5xx rate, exception rate)"
- "What is the current P95/P99 latency vs baseline?"
- "Are all health checks passing?"
- "Any alerts fired since deployment?"

**Tier 2 (30-60 min — Canary Bake)**
- "Error rate for canary population vs control population?"
- "SLO burn rate — is it above normal? (2× normal for 1hr = investigate)"
- "Any user reports or support tickets since release?"
- "Canary bake time elapsed?"

**Tier 3 (24-72 hr — Business Metrics)**
- "Key business metrics vs pre-release baseline? (conversions, signups, engagement)"
- "Support ticket volume trend — increasing, stable, or decreasing?"
- "Any customer feedback signals (positive or negative)?"
- "Feature adoption rate if measurable?"

### Step 3: Assess Health

Apply the monitoring framework from `context/dt-release-patterns.md`:

1. **Compare against baseline** — use error differentials (new vs stable), not absolute thresholds
2. **Apply V1 status**:
   - BELOW V1 + anomaly detected → recommend **ROLLBACK**
   - ABOVE V1 + anomaly detected → recommend **INVESTIGATE** (forward-fix approach)
   - No anomaly → recommend **PROCEED**
3. **Rate confidence**: HIGH (clear signal), MEDIUM (ambiguous), LOW (insufficient data)

### Step 4: Generate Health Brief

Write `release-health-brief.md`:

```markdown
# Release Health Brief: {Feature}
**Generated**: {YYYY-MM-DD HH:MM}
**Skill**: /dt-release-monitor
**Monitoring Tier**: {1 / 2 / 3}
---

## Recommendation: {PROCEED / INVESTIGATE / ROLLBACK}
## V1 Status: {BELOW V1 / ABOVE V1}
## Confidence: {HIGH / MEDIUM / LOW}

### SLI Dashboard
| Metric | Baseline | Current | Delta | Status |
|--------|----------|---------|-------|--------|
| {SLI 1} | {value} | {value} | {+/-} | {OK / WARNING / CRITICAL} |
| ... |

### Anomalies Detected
{List with severity and affected population, or "None detected"}

### Recommendation Rationale
{Why PROCEED/INVESTIGATE/ROLLBACK — cite specific metrics and V1 status}

### Next Steps
{What should happen next — advance ring, hold, investigate specific metric, or execute rollback plan}
```

## HITL Behavior

- **PROCEED recommendation**: Advisory — present brief, auto-advance (HITL level permitting)
- **INVESTIGATE recommendation**: Always escalate regardless of HITL level — use `AskUserQuestion` to present findings and ask for human judgment
- **ROLLBACK recommendation**: Always escalate — present evidence and rollback plan, require explicit human approval

## Persistence

Write `release-health-brief.md` to `sprints/{effort}/sprint-{N}/`. Overwrite with each new tier assessment (latest brief is current state).

## Chaining

After monitoring:
- **PROCEED**: "Health check passed. Advance to next ring stage with `/dt-release`."
- **INVESTIGATE**: "Anomaly detected. Investigate before proceeding. Run `/dt-release-monitor {tier}` again after investigation."
- **ROLLBACK**: "Rollback recommended. Run `/dt-release-comms rollback` to generate rollback communications, then execute rollback plan from `release-plan.md`."
