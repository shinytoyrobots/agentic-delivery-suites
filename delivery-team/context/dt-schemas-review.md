# Review Schemas — delivery-team

Schema subset for gate reviews, readiness, retrospectives, and sprint closure. See `dt-artifact-schemas.md` for effort resolution and directory conventions.

---

## gate-review-{stage}.md

Written by the Scrum Master after invoking adversarial PMs as independent subagents. PMs never see each other's output before the SM synthesizes.

```markdown
---
gate: "3→4"
date: "2026-03-21"
pms-invoked: [conservative-pm, aggressive-pm]
outcome: GO   # GO | HOLD | RECYCLE | KILL
schema-version: "1.0"
---

# Gate Review — Stage 3→4

## Conservative PM Assessment (Morgan)
[Summary of risk flags, with severity: BLOCKER | HIGH | MEDIUM | LOW]

## Aggressive PM Assessment (Alex)
[Summary of cost-of-delay analysis, MVP scope recommendations]

## Divergence Classification
- **Type:** Tactical | Strategic | Values-based
- **Dimensions diverging:** [list]
- **Requires human review:** true | false

## Conservative PM Flags — Disposition Log
| Flag | Severity | Disposition |
|------|----------|-------------|
| Token security implementation unspecified | MEDIUM | Mitigated — Dev Notes in story-042 specify bcrypt requirement |

## Scrum Master Synthesis
[Reconciliation argument for each divergent dimension]

## Gate Recommendation
**Outcome: GO**
[Rationale; any conditions or watch items]
```

---

## cross-functional-readiness.md

Aggregated by the Scrum Master from the three stakeholder agent outputs. Stage 5 always requires human sign-off regardless of HITL level.

```markdown
---
sprint: 2
date: "2026-03-28"
overall-status: CONDITIONAL_GO   # GO | CONDITIONAL_GO | NO_GO
schema-version: "1.0"
---

# Cross-Functional Readiness — Sprint 2

## Summary
| Domain | Status | Condition (if CONDITIONAL) |
|--------|--------|---------------------------|
| GTM/Sales | GO | — |
| Marketing | CONDITIONAL_GO | Blog post draft pending final review |
| CX/Support | GO | — |

## Domain Assessments

### GTM/Sales
[Key points from gtm-readiness.md — deal impact, sales material status, competitive positioning]

### Marketing
[Key points from marketing-readiness.md — content status by tier requirement]

### CX/Support
[Key points from support-readiness.md — documentation status, support briefing status]

## Conditions for CONDITIONAL GO
1. Marketing blog post draft approved by a maintainer before release
   - **Owner:** Marketing Agent
   - **Hard deadline:** 2026-03-29 EOD

## Human Sign-Off Required
[ ] A maintainer has reviewed and approved this readiness assessment.
```

---

## sprint-{N}-retro.md

Written by `/dt-close` as part of the integrated sprint close + retrospective. Consumed by the Scrum Master at next sprint start (via `sprint-memory.md` retro-actions). Persisted to vault at `docs/Delivery-Team/{date}/`. Maximum 3 actionable recommendations per retro (Keep items are unlimited but do not count toward the cap).

```markdown
---
sprint: 2
date: "2026-03-31"
prior-actions-reviewed: 2
prior-actions-completion-rate: 50
new-actions: 2
schema-version: "1.0"
---

# Sprint 2 Retrospective

## Prior Action Review

| ID | Sprint | Type | Description | Status | Outcome |
|----|--------|------|-------------|--------|---------|
| RETRO-S1-01 | 1 | improve | Add architecture context to story files | implemented | improved |
| RETRO-S1-02 | 1 | add | Gate check for API contract conformance | open (carried) | — |

**Action completion rate**: 50% (rolling 3-sprint: 50%)

## Five-Dimension Analysis

### 1. Prompt Quality
**Signal**: {per-agent QA pass rate, gate rejection rate}
[Contributing factor chains for failures. Trace backward: gate failure → dev agent prompt gap → story spec ambiguity → sharding issue. Use MAPRO-style blame attribution.]

### 2. Story Quality
**Signal**: {self-containment score, external reference count}
[Were stories self-contained? Did dev agents reference files not in story context?]

### 3. Gate Effectiveness
**Signal**: {true positive rate, false positive rate, avg gate overhead}
[Did gates catch real problems? Any false positives that delayed sprint?]

### 4. Velocity Calibration
**Signal**: {estimated vs actual points, per-agent cycle time}
[Estimation accuracy by complexity tier. Comparison to rolling 3-sprint average.]

### 5. Action Follow-Through
**Signal**: {completion rate, outcome distribution}
[Stale action escalations, meta-metric trends.]

## Recommendations

### DROP: {title}
- **ID**: RETRO-S2-01
- **Category**: prompt | story-quality | gate | velocity | process
- **Target**: {artifact path — e.g. agents/dt-backend-dev.md#error-handling}
- **Evidence**: {what happened this sprint}
- **Confidence**: High | Medium | Low

### IMPROVE: {title}
- **ID**: RETRO-S2-02
- **Category**: prompt | story-quality | gate | velocity | process
- **Target**: {artifact path}
- **Hypothesis**: "If we {change}, then {metric} will {improve by threshold}"
- **Success criteria**: "{measurable threshold for next retro to evaluate}"
- **Confidence**: High | Medium | Low

### KEEP: {title}
- **Evidence**: {metrics confirming effectiveness over N sprints}
```

---

## sprint-memory.md retro-actions section

`sprint-memory.md` lives at the **effort level** (`sprints/{effort}/sprint-memory.md`), not inside individual sprint directories. This allows cross-sprint learning to persist across the effort. Append-only section written by `/dt-close`. The Scrum Master reads this at sprint start. `/dt-close` owns all writes to this section.

```yaml
retro-actions:
  - id: RETRO-S2-01
    sprint-originated: 2
    type: drop         # drop | add | keep | improve
    category: prompt   # prompt | story-quality | gate | velocity | process
    description: "Remove redundant error-handling instructions from backend-dev methodology"
    target-artifact: "agents/dt-backend-dev.md#error-handling"
    hypothesis: null   # only for 'improve' type
    success-criteria: null
    status: open       # open | implemented | dropped
    implemented-sprint: null
    outcome: null      # improved | no-change | worsened | inconclusive
    evidence: null     # free text referencing metrics after evaluation
  - id: RETRO-S2-02
    sprint-originated: 2
    type: improve
    category: story-quality
    description: "Add API contract excerpts to story Architecture Context sections"
    target-artifact: "dt-scrum-master agent, story-sharding section"
    hypothesis: "Stories with API contract excerpts will reduce BE agent QA failures by 20%"
    success-criteria: "BE agent QA pass rate >= 90% (current: 75%)"
    status: open
    implemented-sprint: null
    outcome: null
    evidence: null
```
