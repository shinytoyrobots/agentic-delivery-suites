---
description: Adversarial PM gate review — launch independent Conservative and/or Aggressive PM subagents, synthesize divergence, produce gate resolution
argument-hint: <gate number 1-7 or gate name>
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
capability-class: synthesis-analysis
tier: II
domain: [dt]
works-with:
  requires-context: [dt-pipeline-stages, dt-artifact-schemas, dt-schemas-review, dt-hitl-protocol, vault-access]
  upstream-skills: [dt-start, dt-run]
  downstream-skills: [dt-run, dt-release, dt-start]
  compatible-agents: [dt-conservative-pm, dt-aggressive-pm, dt-scrum-master]
readiness:
  state: green
  idempotent: true
  warm-start: false
cost:
  model-class: high
  agent-count: 2
  web-calls: none
  context-budget: medium
---

# Gate Review

Read context files:
- `~/.claude/commands/context/dt-pipeline-stages.md`
- `~/.claude/commands/context/dt-artifact-schemas.md`
- `~/.claude/commands/context/dt-schemas-review.md`
- `~/.claude/commands/context/dt-hitl-protocol.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Invoke the adversarial PM pair for a pipeline gate transition. This skill launches Conservative and/or Aggressive PMs as independent parallel subagents — neither sees the other's output. The Scrum Master synthesizes their assessments and produces a gate resolution.

## Input

`$ARGUMENTS` = gate number (1-7) or gate name.

| Argument | Gate Transition | PMs Invoked |
|----------|----------------|-------------|
| 1 | Problem Brief → Design Intent | Aggressive only |
| 2 | Design Intent → Technical Spec | Both |
| 3 | Technical Spec → Build | Both |
| 4 | Build → Cross-Functional Readiness | Conservative only |
| 5 | Cross-Functional Readiness → Comms + Release | Both |
| 6 | Comms + Release → T+2 Fast-Follow | Neither (automated) |
| 7 | T+2 Fast-Follow | Aggressive only |

If `$ARGUMENTS` is empty or invalid, display the gate table and ask: "Which gate transition do you want to review?"

## Prerequisites

See `dt-artifact-schemas.md` § Effort Resolution. Read the appropriate artifacts for the requested gate from the resolved effort's current sprint (see Gate Artifact Requirements below).

## Gate Artifact Requirements

### Gate 1 (Problem Brief → Design Intent)
- `ux-research-brief.md` — evidence for the problem
- `project-kickoff.md` — project context
- Spec/PRD — original problem statement

### Gate 2 (Design Intent → Technical Spec)
- `design-spec.md` — complete design with interaction states
- `ux-research-brief.md` — research consumed by designer
- `architecture-proposal.md` — if present; PMs evaluate fit-for-purpose and recommend whether to ship the recommended option or push back
- `dt-architect-review-*.md` — schema-enforcement verdict on the architecture proposal
- `project-kickoff.md` — project context

### Gate 3 (Technical Spec → Build)
- All `story-{id}.md` files — EARS ACs, task-to-AC mapping
- `api-contract.yaml` — API contracts
- `dependency-map.md` — dependency graph
- `sprint-plan.md` — execution plan
- `architecture-proposal.md` — if present; PMs verify the sprint plan honors §11 vertical slices and starts with §12 walking skeleton
- `project-kickoff.md` — project context

### Gate 4 (Build → Cross-Functional Readiness)
- All `qa-gate.md` files — QA verdicts
- `sprint-status.yaml` — all stories done
- `design-veto.md` — no active vetoes

### Gate 5 (Cross-Functional Readiness → Comms + Release)
- `cross-functional-readiness.md` — aggregated readiness
- `gtm-readiness.md`, `marketing-readiness.md`, `support-readiness.md` — individual assessments
- `launch-tier.md` — tier-appropriate content requirements

### Gate 6 (Automated — no PM review)
- Deployment status, comms publication status

### Gate 7 (T+2 Fast-Follow)
- `sprint-{N}-summary.md` — sprint results
- Fast-follow candidate list
- QA regression check results

## Phase 1: Independent PM Evaluation

Launch each PM as a separate subagent. Do not include one PM's output in the other's context — this prevents convergence bias.

### Conservative PM ("Morgan") — when invoked

Launch `~/.claude/commands/agents/dt-conservative-pm.md` subagent (model: sonnet) to evaluate the gate artifacts.

Instruct the Conservative PM to assess across 5 dimensions:
1. **Risk Exposure** — What could go wrong? Regression risk? Security implications? Customer trust impact?
2. **Readiness Evidence** — Is there sufficient evidence that this is ready to advance? Test coverage? Accessibility audit?
3. **Technical Debt** — What debt is being created? Is it tracked and bounded?
4. **Rollback Plan** — If this goes wrong, can we undo it safely? Is the blast radius contained?
5. **Customer Impact** — What is the worst case for a customer who encounters a bug in this feature?

Each dimension gets a verdict: CLEAR / CAUTION / BLOCKER.

The Conservative PM returns a structured brief — not a freeform essay. Instruct the PM to write its full assessment to a temp file in the sprint directory and return only a 3-5 line summary to the caller.

### Aggressive PM ("Alex") — when invoked

Launch `~/.claude/commands/agents/dt-aggressive-pm.md` subagent (model: sonnet) to evaluate the gate artifacts.

Instruct the Aggressive PM to assess across 5 dimensions:
1. **Time Cost** — What is the cost of NOT shipping this now? Competitive risk? Customer pain continuing?
2. **Scope Integrity** — Is the scope tight enough for an MVP? What can be deferred?
3. **Value Delivery** — Does this deliver meaningful value to users as-is? Or is it half a feature?
4. **Momentum** — What happens to team velocity and morale if we hold?
5. **Learning Opportunity** — Will shipping this teach us something we can't learn otherwise?

Each dimension gets a verdict: SHIP / HOLD / DEFER.

The Aggressive PM returns a structured brief — not a freeform essay. Instruct the PM to write its full assessment to a temp file in the sprint directory and return only a 3-5 line summary to the caller.

## Phase 2: Divergence Analysis

After both PMs return (or the single PM returns for gates with only one):

### Single-PM Gates (1, 4, 7)

Summarize the PM's assessment. No divergence analysis needed.

For Gate 4 (Conservative only): If any dimension is BLOCKER, this is a mandatory HITL escalation.

### Dual-PM Gates (2, 3, 5)

Compare assessments across all 5 dimensions:

**Full alignment** (all dimensions agree in direction):
- Summarize consensus
- SM recommends gate outcome

**Tactical divergence** (1-2 dimensions disagree, no BLOCKER):
- Document the trade-off explicitly
- SM synthesizes with documented rationale for which perspective to weight
- SM recommends gate outcome

**Strategic divergence** (3+ dimensions disagree, OR any BLOCKER from Conservative):
- Document all disagreements
- Classify each: factual (resolvable with evidence) vs. values-based (requires human judgment)
- Mandatory HITL escalation — SM does not resolve strategic divergence autonomously

### Divergence Classification

For each disagreement:
- **Factual**: "Conservative says test coverage is 72%; Aggressive says it's adequate." → Resolvable by checking actual coverage.
- **Values-based**: "Conservative says 80% coverage is the minimum; Aggressive says 72% is fine for an MVP." → Requires human judgment on risk tolerance.

## Phase 3: Gate Resolution

### SM Arbiter Synthesis

Produce `gate-review-{stage}.md`:

```markdown
# Gate Review: Stage {N} → Stage {N+1}
**Generated**: {YYYY-MM-DD HH:MM}
**Skill**: /gate-review
**Gate**: {gate name}
---

## PM Assessments

### Conservative PM ("Morgan")
| Dimension | Verdict | Key Concern |
|-----------|---------|-------------|
| Risk Exposure | {CLEAR/CAUTION/BLOCKER} | {one-line} |
| Readiness Evidence | ... | ... |
| Technical Debt | ... | ... |
| Rollback Plan | ... | ... |
| Customer Impact | ... | ... |

### Aggressive PM ("Alex")
| Dimension | Verdict | Key Concern |
|-----------|---------|-------------|
| Time Cost | {SHIP/HOLD/DEFER} | {one-line} |
| Scope Integrity | ... | ... |
| Value Delivery | ... | ... |
| Momentum | ... | ... |
| Learning Opportunity | ... | ... |

## Divergence Analysis
**Classification**: {Full alignment / Tactical divergence / Strategic divergence}

{For each disagreement: dimension, both positions, factual vs. values-based classification}

## Conservative PM Flags Log
| Flag | Severity | Disposition |
|------|----------|-------------|
| {flag} | {CAUTION/BLOCKER} | {Mitigated: how / Accepted: rationale / Escalated / Blocks gate} |

## Gate Recommendation
**Outcome**: {Go / Hold with conditions / Recycle / Kill}
**Rationale**: {2-3 sentences}
**Conditions** (if Hold): {specific conditions that must be met}

## HITL Required
{Yes/No — with reason if yes}
```

## HITL Checkpoints

Mandatory HITL escalation when:
- Strategic divergence (3+ dimensions disagree)
- Any BLOCKER flag from Conservative PM
- Values-based disagreement (not resolvable with data)
- ONE-WAY DOOR risk rated SIGNIFICANT or higher by Conservative PM

For mandatory HITL:
Use `AskUserQuestion` to present the gate review summary and ask: "This gate requires your decision. Review the PM assessments above. Approve to advance, hold for rework, or provide guidance."

## Persistence

Write `gate-review-{stage}.md` to `sprints/{effort}/sprint-{N}/`.

Write to vault per `context/vault-access.md`: `docs/Delivery-Team/{date}/gate-review-{stage}.md`

## Chaining

After gate review:
- **Go**: Advise the next skill (e.g., "/sprint-run" after Gate 3)
- **Hold**: Advise which artifacts need rework
- **Recycle**: Advise returning to the previous stage
- **Kill**: Advise archiving the project artifacts
