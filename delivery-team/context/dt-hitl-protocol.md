# HITL Protocol — delivery-team

Human-in-the-loop (HITL) calibration controls how much autonomous decision-making the agent suite exercises. The calibration level is set once in `project-kickoff.md` and stored in `sprint-status.yaml` (`hitl-level` field). It can be changed between sprints.

HITL is file-based: the Scrum Master writes `HITL-needed.md` to the repository root and pauses execution. The user reviews, fills in a decision, sets `awaiting: false`, and the next skill invocation resumes work.

---

## Four Calibration Levels

### Level 1 — Full Oversight
The user approves every significant decision point before the suite proceeds.

| Stage | What Requires Approval |
|-------|------------------------|
| 1. Problem Brief | Research brief assessment; user confirms direction before design begins |
| 2. Design Intent | Design spec reviewed; user signs off before Technical Spec phase |
| 3. Technical Spec | Sprint plan reviewed; each story reviewed individually before development |
| 4. Build | Each story approved before dev agent starts |
| 5. Cross-Functional Readiness | Readiness gate reviewed (always required at all levels) |
| 6. Comms + Release | Release explicitly approved |
| 7. T+2 Fast-Follow | Sprint summary reviewed |

### Level 2 — Phase Gates

| Stage | What Requires Approval |
|-------|------------------------|
| 1-2 | Design spec — approve before Technical Spec starts |
| 3 | Sprint plan — approve before Build starts |
| 4 | Autonomous (auto-escalation conditions still apply) |
| 5 | Readiness gate (always required) |
| 6-7 | Autonomous |

### Level 3 — QA Gate Only

| Stage | What Requires Approval |
|-------|------------------------|
| 1-4 | Autonomous |
| 5 | Readiness gate; QA gate result review |
| 6-7 | Autonomous |

### Level 4 — Autonomous

| Stage | What Requires Approval |
|-------|------------------------|
| 1-4 | Autonomous |
| 5 | Auto-advance unless auto-escalation triggers |
| 6-7 | Autonomous |

---

## Auto-Escalation Conditions (Always Active — All Levels)

The following conditions override the calibration level and always produce a `HITL-needed.md`:

| Condition | Escalation Type |
|-----------|-----------------|
| `qa-gate.md` has one or more blocking failures | `gate-failure` |
| `design-veto.md` is active in the sprint | `gate-failure` |
| Mid-sprint scope addition proposed | `scope-change` |
| Spec ambiguity producing two or more valid interpretations | `ambiguity` |
| Unresolved external dependency blocking a story | `external-dependency` |
| Conservative PM raises a BLOCKER flag at any gate | `gate-failure` |
| Strategic PM divergence (3+ scoring dimensions disagree) | `gate-failure` |
| Values-based disagreement between adversarial PMs | `gate-failure` |
| ONE-WAY DOOR decision identified with SIGNIFICANT risk | `gate-failure` |

Escalation is event-based. Staleness alone does not trigger; long-running stories surface through the human's chosen HITL posture (level 1–4), not through a time threshold.

---

## HITL-needed.md Schema

When the Scrum Master writes this file, it pauses execution. The Scrum Master is the only agent that writes HITL-needed.md. The file is written to the repository root or `docs/` depending on project conventions set in `project-kickoff.md`.

```yaml
---
date: 2026-03-24
sprint: 2
story-id: story-042          # null if sprint-level escalation
escalation-type: ambiguity   # blocker | gate-failure | scope-change | ambiguity | external-dependency
summary: "One-line description of what the human needs to decide"
context: |
  Detailed explanation of the situation, what was attempted, and why
  human judgment is needed. Include relevant artifact refs.
options:
  - option-A: "Description of option A and its trade-offs"
  - option-B: "Description of option B and its trade-offs"
  - option-C: "Description of option C, if applicable"
recommendation: "option-A — rationale in one sentence"
decision: null   # User fills in: "option-A" | "option-B" | free text
awaiting: true   # User sets to false after filling decision field
---
```

Multiple HITL-needed files can be active simultaneously (e.g., `HITL-needed-story-042.md`, `HITL-needed-gate-3.md`). Each is independent.

---

## Resolution Workflow

### How the User Responds to an Escalation

1. Run `/sprint-status` to see all open `HITL-needed.md` files (the Scrum Master surfaces these in the status report).
2. Read the file. Fill in the `decision` field with the chosen option or a custom decision.
3. Set `awaiting: false`.
4. Resume with the appropriate skill (e.g., `/sprint-run` to continue a blocked story, `/gate-review` to re-evaluate a gate).

### What the Scrum Master Does After Resolution

1. Reads the resolved `HITL-needed.md` (now `awaiting: false`).
2. Applies the decision: updates the story file, sprint-status.yaml, or gate artifact as appropriate.
3. Archives the resolved file by moving it to `docs/hitl-archive/` (or deletes it if project conventions prefer).
4. Resumes the paused workflow.

### Escalations That Cannot Be Auto-Resolved

If `escalation-type: gate-failure` and the Conservative PM's flag is marked `BLOCKER`, the suite cannot auto-resolve regardless of the user's text response. The blocking issue must be remediated in the relevant artifact before the gate can advance. The SM surfaces this in the HITL file's `context` field.

---

## HITL Level in sprint-status.yaml

The active HITL level is always readable from the sprint state file:

```yaml
sprint:
  hitl-level: 2   # 1 | 2 | 3 | 4
```

To change the level mid-project, the user edits this field directly and restates their preference to the Scrum Master at the next skill invocation. The SM acknowledges the change in its next `phase-log` entry.

---

## HITL and Deployment

Production deployments are **always** a human action regardless of HITL level. The suite never deploys automatically. The Scrum Master coordinates release activities and surfaces the deployment-ready state, but the user initiates the actual deployment. This is a non-negotiable constraint encoded in `project-kickoff.md`.
