# Planning Schemas — delivery-team

Schema subset for story sharding, sprint planning, and project setup. See `dt-artifact-schemas.md` for effort resolution and directory conventions.

---

## story-{id}.md

Written by the Scrum Master during Stage 3. Consumed by dev agents (Stage 4) and QA Tester (Stage 4-5). Target size: 2-8 KB (~600-2,400 tokens). Acceptance criteria use EARS format (not Gherkin — QA converts to Gherkin in qa-gate.md).

```markdown
---
id: story-042
title: "User can reset password via email link"
epic: epic-03-auth
linear-id: ENG-242
sprint: 2
status: drafted   # backlog | drafted | ready-for-dev | in-progress | review | validating | validated | done
assigned-agent: backend-dev   # frontend-dev | backend-dev | middleware-dev | product-designer | user-researcher
priority: high   # high | medium | low
estimated-points: 3
depends-on:
  - story-039
  - story-041
hitl-checkpoint: false
schema-version: "1.0"
---

## Story

As an authenticated user who has forgotten their password,
I want to receive a one-time reset link via email,
So that I can regain access to my account without contacting support.

## Acceptance Criteria

AC-1: WHEN a user submits a valid email on the password reset form,
      THE SYSTEM SHALL send a password reset email within 30 seconds.

AC-2: WHEN the reset link is clicked within 1 hour of generation,
      THE SYSTEM SHALL display the new password form.

AC-3: WHEN the reset link is clicked after 1 hour or has already been used,
      THE SYSTEM SHALL display an "expired link" error and offer to resend.

AC-4: WHEN the user submits a new password meeting complexity requirements,
      THE SYSTEM SHALL update the password and invalidate all existing sessions.

AC-5: WHEN a non-existent email is submitted,
      THE SYSTEM SHALL respond identically to the valid case (no user enumeration).

## Technical Context
[DB schema excerpt, API endpoints, environment notes — relevant excerpts only]

## Architecture References
[Reference paths only — do not embed full sections]

## Design References
[Only if design-spec.md exists for this story]

## Implementation Tasks

- [ ] Task 1: Create password_reset_tokens table migration (AC: #1, #3, #4)
- [ ] Task 2: Implement POST /api/auth/password-reset/request handler (AC: #1, #5)
- [ ] Task 3: Implement Resend email dispatch with token (AC: #1)
- [ ] Task 4: Implement POST /api/auth/password-reset/confirm handler (AC: #2, #3, #4)
[Each task MUST list which AC(s) it satisfies in (AC: #N) format.]

## Dev Notes
> SM context injection — agent reads this but does not modify it.
[Implementation hints, security constraints, rate-limit requirements, idempotency expectations.]

## Definition of Done
[See context/dt-definition-of-done.md for full checklist]
```

---

## sprint-status.yaml

Written and owned by the Scrum Master. Single source of truth for sprint state.

```yaml
schema-version: "1.0"
effort: auth-overhaul        # effort namespace — matches directory name under sprints/
sprint:
  id: sprint-02
  name: "Sprint 2 — Auth & Onboarding"
  start-date: "2026-03-18"   # optional audit metadata — nothing in the suite reads this as policy
  end-date: "2026-03-31"     # optional audit metadata — nothing in the suite reads this as policy
  goal: "Complete password reset flow and user onboarding steps 1–3"
  status: implementation  # discovery | planning | implementation | review | closed
  hitl-level: 2           # 1 | 2 | 3 | 4

project-ref: "project-kickoff.md"
api-contract-ref: "docs/api-contract.yaml"
architecture-ref: "docs/architecture.md"

summary:
  total-stories: 8
  done: 2
  validated: 1
  review: 1
  in-progress: 2
  ready-for-dev: 1
  drafted: 1
  backlog: 0
  blocked: 1

current-epic: "epic-03-auth"
next-recommended-story: "story-043"

stories:
  - id: story-042
    title: "User can reset password via email link"
    epic: epic-03-auth
    linear-id: ENG-242
    status: in-progress
    assigned-agent: backend-dev
    priority: high
    estimated-points: 3
    model-tier: sonnet   # sonnet | opus
    blocked-by: []
    depends-on: ["story-039", "story-041"]
    hitl-checkpoint: false
    hitl-reason: null    # string if hitl-checkpoint: true
    gate-status: pending # pending | pass | fail
    qa-gate-ref: "docs/qa/qa-gate-042.md"
    qa-gate-status: fail
    blocker: "BLK-001 in qa-gate-042.md — token expiry 500 error"
    started: "2026-03-22"
    completed: null

phase-log:
  - timestamp: "2026-03-18T09:00:00Z"
    event: "sprint-planning-complete"
    agent: scrum-master
  - timestamp: "2026-03-20T11:00:00Z"
    event: "story-042-qa-gate-fail"
    agent: qa-tester
    detail: "BLK-001 identified — token expiry handler throws 500"
```

---

## ux-research-brief.md

Written by the User Researcher during Stage 1. Evidence is tiered: Tier 1 = behavioral observation; Tier 2 = stated preference; Tier 3 = expert opinion; Tier 4 = assumption. Every finding connects to a specific design or development decision.

```markdown
---
stage: 1
sprint: [sprint-id or "pre-sprint"]
topic: "Password Reset — User Research Brief"
schema-version: "1.0"
---

# UX Research Brief — [Topic]

## Problem Statement
[One sentence: what behavior or outcome are we researching?]

## Research Questions
1. [Specific question this research must answer]
2. [...]

## Findings

### Finding 1: [Title]
- **Evidence tier:** Tier 2 (stated preference — support ticket themes)
- **Evidence:** [Source, date, volume]
- **Finding:** [Behavioral hypothesis, not behavioral claim]
- **Decision implication:** [Which design/dev decision this informs]
- **Confidence:** High | Medium | Low

## Gaps (What We Don't Know)
- [Question we have no evidence for — valid and important to document]

## JTBD Analysis
- **Job:** When [situation], I want to [motivation], so I can [expected outcome].
- **Competing solutions:** [How users solve this today]

## Recommended Next Steps
[What would increase evidence quality if we had more time/budget]
```

---

## project-kickoff.md

Written by the Scrum Master during `/project-kickoff`. All agents load this at session start. Hard limit: ≤ 150 lines. If longer, agents fail to use it effectively.

```markdown
---
schema-version: "1.0"
project: "YourProjectName"
created: "2026-03-18"
created-by: scrum-master
stack:
  frontend: "Next.js 15 + React 19 + Tailwind CSS 4"
  backend: "Next.js API routes (App Router)"
  database: "PostgreSQL via Prisma ORM"
  auth: "NextAuth.js v5"
  testing: "Vitest (unit) + Playwright (E2E)"
  ci: "GitHub Actions"
  deployment: "Vercel"
hitl-level: 2
linear-workspace: "[slug]"
linear-team: "ENG"
---

# Project Kickoff — Agent Reference Document

> All agents load this document at session start. Keep total file under 150 lines.

## Repository Structure
[Tree of src/ and docs/ showing where agents read/write]

## Code Conventions
[TypeScript strict, naming, import style, branch naming, commit format]

## Design System
[Token source, component library, accessibility target]

## Architecture Constraints
[API routing convention, DB access pattern, auth pattern, env var rules]

## Agent Roles and Responsibilities
[Table: agent → primary output, reads, writes — abbreviated]

## HITL Policy
[Escalation trigger, pause/resume mechanism, deployment approval rule]

## Testing Standards
[Unit framework, E2E framework, coverage target, CI trigger]
```
