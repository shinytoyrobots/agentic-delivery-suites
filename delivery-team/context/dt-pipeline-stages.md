# Pipeline Stages — delivery-team

The delivery-team operates a 7-stage pipeline mapped to a Notion process template. Every stage has explicit entry criteria, exit criteria, and a gate before the next stage opens.

---

## Stage Definitions

### Stage 1: Problem Brief
**Purpose**: Validate that the problem is real and worth solving.
**Entry criteria**: A feature request, support theme, or strategic directive exists.
**Exit criteria**: `ux-research-brief.md` complete; "So what?" answerable; target users identified with evidence; GTM deal context surfaced.
**Key artifacts**: `ux-research-brief.md`, `problem-brief.md`

### Stage 2: Design Intent
**Purpose**: Define what success looks like and produce a testable hypothesis of value.
**Entry criteria**: Gate 1→2 passed (problem validated); research brief consumed.
**Exit criteria**: `design-spec.md` complete with all interaction states; accessibility reviewed; design system adherence confirmed; launch tier proposed.
**Key artifacts**: `design-spec.md`, `user-flow.md`, `launch-tier.md`

### Stage 3: Technical Specification
**Purpose**: Translate design intent into buildable stories and a shared API contract.
**Entry criteria**: Gate 2→3 passed (design intent aligned); design spec stable.
**Exit criteria**: All stories have EARS acceptance criteria, task-to-AC mapping, and Linear IDs; `api-contract.yaml` authored; `sprint-status.yaml` created; `dependency-map.md` complete; QA shift-left story review done.
**Key artifacts**: `story-{id}.md`, `api-contract.yaml`, `sprint-status.yaml`, `sprint-plan.md`, `dependency-map.md`

### Stage 4: Build
**Purpose**: Execute implementation story by story with quality gates per story.
**Entry criteria**: Gate 3→4 passed (spec approved); all stories in `ready-for-dev` state.
**Exit criteria**: All stories `done` in sprint-status.yaml; `qa-gate.md` zero blocking failures; no active `design-veto.md`.
**Key artifacts**: Implementation code, `qa-gate-{id}.md`, `ready-for-review.md`

### Stage 4.5: Release Planning (Pre-Stage 5)
**Purpose**: Pre-commit all release decisions — risk assessment, V1 threshold, rollback strategy, feature flags, and communication plan — before cross-functional readiness.
**Entry criteria**: Gate 4→5 approaching (all stories `done`, QA gates passed).
**Exit criteria**: `release-plan.md` approved with risk score, V1 threshold, rollback strategy, flag configuration, and communication plan.
**Key artifacts**: `release-plan.md`
**Skill**: `/dt-release-plan` — invokes `dt-release-scorer` agent for risk assessment.

### Stage 5: Cross-Functional Readiness
**Purpose**: Verify everything beyond code is ready — docs, sales material, support briefing, launch content. Now also verifies release plan prerequisites (monitoring, flags, rollback).
**Entry criteria**: Gate 4→5 passed (staging verified); Conservative PM technical readiness assessment done; `release-plan.md` approved.
**Exit criteria**: GTM, Marketing, and CX/Support each report READY or CONDITIONAL; human sign-off obtained; release plan prerequisites verified.
**Key artifacts**: `cross-functional-readiness.md`, `gtm-readiness.md`, `marketing-readiness.md`, `support-readiness.md`, `release-plan.md`

### Stage 6: Communication + Release
**Purpose**: Ship the feature and communicate it to all audiences via progressive rollout through ring stages.
**Entry criteria**: Gate 5→6 passed (all functions ready); human release approval given; `release-plan.md` and `cross-functional-readiness.md` approved.
**Exit criteria**: All ring stages complete; deployment health GREEN; comms published per launch tier and stakeholder tier requirements.
**Key artifacts**: `deployment-status.md`, `release-comms.md`, `release-health-brief.md`
**Skills**: `/dt-release` orchestrates the rollout. At each ring stage, invokes `/dt-release-comms` (via `dt-release-communicator` agent) and `/dt-release-monitor` for health assessment.

**Ring progression** (adapted per risk level):
- Ring 0: Internal / dogfood → Tier 1 monitoring (0-15 min)
- Ring 1: Beta / sponsor customers (UAT) → Tier 2 monitoring (30-60 min)
- Ring 2: Early adopters → Tier 2 monitoring
- Ring 3: General availability (SIT/GA) → Tier 3 monitoring (24-72 hr)

Each ring transition requires human go/no-go approval. V1 threshold (from release-plan.md) determines whether rollback or forward-fix is recommended on anomaly.

### Stage 7: T+2 Week Fast-Follow
**Purpose**: Capture early learnings, prioritize fast-follow work, close the sprint, and run release retrospective.
**Entry criteria**: Gate 6→7 passed (deployed; critical comms published).
**Exit criteria**: Sprint summary written; regression check passed; fast-follow items sequenced; release retrospective complete; feature flag cleanup audited.
**Key artifacts**: `sprint-N-summary.md`, fast-follow issue list, `release-retro.md`
**Skills**: `/dt-close` for sprint review, `/pm-fast-follow` for post-launch review, `/dt-release-retro` for release-specific retrospective and flag audit.

---

## Gate Transition Rules

| Gate | Criteria | Blocking Conditions |
|------|----------|---------------------|
| 1→2 | Problem validated with evidence | No evidence; "So what?" unanswerable; user segment undefined |
| 2→3 | Design spec complete; accessibility reviewed | `design-veto.md` active; missing accessibility review |
| 3→4 | All stories have EARS ACs + task mapping + Linear IDs; `api-contract.yaml` present | Stories without ACs; API contract missing for API-dependent stories |
| 4→5 | All stories `done`; qa-gate zero blocking failures; no active design veto | Any blocking QA failure; active design veto; stories still in-progress |
| 4→4.5 | All stories `done`; QA gates passed | Any blocking QA failure; stories in-progress |
| 4.5→5 | `release-plan.md` approved with risk score and V1 threshold | Release plan missing or not approved |
| 5→6 | All function domains READY or CONDITIONAL; release plan prerequisites verified | Any domain BLOCKED; Conservative PM BLOCKER on ONE-WAY DOOR risk; monitoring not configured |
| 6→7 | All ring stages complete; deployment health GREEN; tier-appropriate comms published | Ring not complete; deployment health RED/YELLOW; critical comms missing for Tier 1/2 |
| T+2 close | Sprint summary produced; regression clean; release retro complete; flag cleanup audited | Unresolved production incidents; regression detected; stale flags not addressed |

---

---

## HITL Calibration Effect

See `context/dt-hitl-protocol.md` for the full HITL calibration table per stage.

---

## Auto-Escalation Conditions

See `context/dt-hitl-protocol.md` for the canonical auto-escalation condition list. These conditions apply at all HITL levels.
