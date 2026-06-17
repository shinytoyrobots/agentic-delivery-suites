# Build Schemas — delivery-team

Schema subset for implementation, QA, and handoff artifacts. See `dt-artifact-schemas.md` for effort resolution and directory conventions.

---

## qa-gate.md

Written by the QA Tester (via Bash output; QA has no Write tools). Each story gets its own gate file. The Scrum Master reads the `verdict` field and `blocking-failures` count to determine if a story can move to `done`.

```markdown
---
story-id: story-042
sprint: 2
reviewed-by: qa-tester
generated-at: 2026-03-22T14:30:00Z
verdict: FAIL   # PASS | WARN | FAIL
ci-status: pass   # pass | fail | pending
blocking-failures: 1
advisory-findings: 2
schema-version: "1.0"
---

# QA Gate Report — story-042

## Summary
Overall: **FAIL** (1 blocking failure must be resolved before story can move to `done`)

## Risk Assessment
- Risk tier: MEDIUM (auth flow change)
- Areas receiving deeper scrutiny: token expiry logic, session invalidation, rate limiting

## Acceptance Criteria Coverage
| AC | Test Level | Status | Blocking | Evidence |
|----|-----------|--------|----------|----------|
| AC-1 | Integration | pass | — | test/auth/password-reset.test.ts:L42 |
| AC-3 | Integration | fail | YES | reset-expired.spec.ts — 500 instead of 400 |

## Blocking Findings

### BLK-001: Expired token returns 500 instead of 400
- **Severity:** Blocking
- **AC:** AC-3
- **Location:** src/app/api/auth/password-reset/confirm/route.ts:47
- **Description:** Missing `.expires_at` field throws unhandled TypeError, producing 500.
- **Expected:** HTTP 400 with `{ error: "Link expired", code: "TOKEN_EXPIRED" }`
- **Actual:** HTTP 500

## Advisory Findings

### ADV-001: Statement coverage 71% on new files (target ≥ 80%)
- **Severity:** Advisory | **Blocking:** false

## Coverage Metrics
| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Statement coverage (new files) | ≥ 80% | 71% | advisory |
| E2E critical path (AC coverage) | 100% | 80% | fail — blocking |
| TypeScript strict mode | pass | pass | pass |
| API contract conformance | pass | pass | pass |
| Accessibility audit (axe-core) | 0 violations | 1 | advisory |

## Scrum Master Action Required
Story cannot transition to `done` until BLK-001 is resolved.
Re-run QA gate after fix: create `qa-gate-042-v2.md`.
```

---

## HITL-needed.md

Written by the Scrum Master when any auto-escalation condition is triggered. The user resolves by editing the file (selecting an option or writing a decision) and setting `awaiting: false`, then resuming the relevant skill.

```markdown
---
date: 2026-03-24
sprint: 2
story-id: story-042
escalation-type: ambiguity  # blocker | gate-failure | scope-change | ambiguity | external-dependency
summary: "AC-5 says 'respond identically' but rate limiting returns 429 only for valid emails"
context: "Rate limiting applied per-email means a non-existent email never triggers 429, creating a timing side-channel for user enumeration."
options:
  - option-A: "Apply rate limiting globally (per IP) — prevents enumeration, minor trade-off in abuse precision"
  - option-B: "Add artificial delay to non-existent email responses — complex but preserves per-email limiting"
  - option-C: "Accept timing side-channel as low risk — document as known limitation"
recommendation: "option-A — simplest implementation, strongest security posture"
decision: null   # user fills this in: "option-A" | "option-B" | "option-C" | custom text
awaiting: true   # user sets to false after filling decision
---
```

---

## api-contract.yaml

Authored by the Backend Dev during Stage 3. Covers only endpoints under active development in the sprint. All agents read the same file — no divergence risk. Extension fields: `x-stories` links endpoints to story IDs; `x-sprint-version` uses semver (bump minor for additive, major for breaking changes).

```yaml
openapi: "3.1.0"
# x-sprint-version: 2.3.1
# Bump minor for additive changes; bump major for breaking changes.
# Breaking changes require api-contract-migration.md.

info:
  title: "Delivery Team App — Sprint 2 Contract"
  version: "2.3.1"
  description: |
    Sprint-scoped contract. Full API reference: docs/architecture.md#api-reference.

servers:
  - url: http://localhost:3000/api
    description: Local dev

paths:
  /auth/password-reset/request:
    post:
      operationId: requestPasswordReset
      x-stories: ["story-042"]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: "#/components/schemas/PasswordResetRequest" }
      responses:
        "200":
          description: "Always 200 — prevents user enumeration"
        "429":
          description: "Rate limit exceeded"

components:
  schemas:
    PasswordResetRequest:
      type: object
      required: [email]
      properties:
        email: { type: string, format: email }
    ErrorResponse:
      type: object
      required: [error, code]
      properties:
        error: { type: string }
        code: { type: string, description: "Machine-readable code e.g. TOKEN_EXPIRED" }
```

---

## design-spec.md

Written by the Product Designer during Stage 2-3. Structured at the component level, not page level. Every interactive component must include all interaction states. Figma node IDs are referenced (not embedded). Accessibility annotations are inline per component.

```markdown
---
sprint: 2
stories: ["story-042"]
figma-file: "abc123xyz"
figma-branch: "sprint-02"
schema-version: "1.0"
---

# Design Spec — Sprint 2

## Global Tokens
[Reference Tailwind config — do not use raw hex values.]
- Primary action: `bg-indigo-600 hover:bg-indigo-700`
- Focus ring: `ring-2 ring-indigo-500 ring-offset-2`

---

## Component: PasswordResetForm
**Figma node:** [View in Figma](https://figma.com/design/abc123xyz?node-id=12:345)
**Stories:** story-042

### Interaction States
| State | Description |
|-------|-------------|
| Default | Email input + Submit button |
| Loading | Spinner on button, input disabled |
| Success | Confirmation message replaces form |
| Error | Inline error below input |

### Responsive Breakpoints
| Breakpoint | Behavior |
|------------|----------|
| Mobile (<640px) | Full-width container, stacked layout |
| Desktop (≥640px) | `max-w-sm mx-auto` centered card |

### Design Tokens Used
- Container: `max-w-sm mx-auto px-4 py-8`
- Heading: `text-2xl font-semibold text-slate-900`

### Accessibility
- `role="form"` with `aria-label="Password reset request"`
- Error message: `role="alert"`, `aria-live="polite"`
- Submit button: `aria-busy="true"` when loading
- WCAG 2.2 AA: contrast ≥ 4.5:1 (indigo-600 on white = 4.6:1 — passes)
- Keyboard: Tab order: email input → submit. Enter submits.
```

---

## ready-for-review.md

Written by a dev agent when a story implementation is complete. Consumed by the QA Tester to begin review.

```markdown
---
story-id: story-042
agent: backend-dev
completed-at: "2026-03-22T16:00:00Z"
branch: "feat/story-042-password-reset"
pr-url: "https://github.com/org/repo/pull/87"
pr-number: 87
ci-status: "pass"
significant-lines-changed: 142
schema-version: "1.0"
---

# Ready for Review — story-042

## What Was Implemented
[Summary of implementation decisions — 3-5 sentences]

## Files Changed
- `src/app/api/auth/password-reset/request/route.ts` — new
- `src/lib/auth/reset-token.service.ts` — new
- `prisma/migrations/20260322_add_reset_tokens.sql` — new

## How to Test
[Specific test commands or test scenario setup instructions]

## Known Deviations from Spec
[Any intentional deviation from story-{id}.md or design-spec.md — none = "None"]

## Dev Notes for QA
[Any known edge cases, environment setup needed, or gotchas]

## PR Size Note
[If significant-lines-changed > 150: explain why splitting wasn't feasible. Otherwise omit.]
```
