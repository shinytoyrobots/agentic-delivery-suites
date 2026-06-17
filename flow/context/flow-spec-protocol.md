# Flow Spec Protocol

How specs are written, evolved, and enforced. The spec is the source of truth (P3).

The spec is **two layers**, authored top-down:

1. **Behavioral scenarios (`SCN-{NNN}`)** — the primary, product-facing layer. Given/When/Then descriptions of observable user behavior. This is what a human reviews and what `flow-narrator` derives comms from. Each scenario is a graded example — its acceptance criteria seed the eval datasets (P4).
2. **EARS requirements (`SR-{NNN}`)** — the normative, derived layer. System-centric, parseable requirements that either (a) decompose a scenario's acceptance criteria into testable constraints, or (b) capture non-functional / ambient requirements (performance, security, cost) that have no user-observable trigger.

Scenarios come first because the unit of work is *user value*, not *system behavior*. EARS stays load-bearing — it just sits downstream of behavior.

Traceability is mandatory: `SCN-{NNN}` → `SR-{NNN}` → grader + dataset.

---

## GWT behavioral scenarios (primary layer)

Every user-observable behavior is captured as a scenario with a stable ID `SCN-{NNN}` in Given/When/Then form:

```markdown
### SCN-001: User logs in with email and password
**Given** a user is unauthenticated and has valid credentials on file
**When** they submit the login form
**Then** the system shall establish an authenticated session and redirect to the dashboard

**Acceptance criteria:**
- Session persists across a page reload
- An invalid password returns HTTP 401 and creates no session
- More than 10 attempts per IP in 5 minutes returns HTTP 429 with a Retry-After header

**Derived requirements:** SR-001, SR-002, SR-005
**Covered by:** `evals/datasets/correctness-real-v1.jsonl` (tasks 1–3)
```

A scenario is **complete** only when every acceptance criterion is measurable (it can become a test case). Vague criteria ("logs in quickly") are refused the same way vague EARS is — the spec writer counter-prompts for a target.

**Not everything is a scenario.** Non-functional and ambient requirements — throughput, encryption-at-rest, cost ceilings, accessibility floors — rarely have a `When` trigger from a user. Those are written directly as EARS `SR-{NNN}` with no `SCN` parent. Use a *quality-attribute scenario* only when a non-functional concern genuinely has an observable trigger.

---

## EARS notation (derived / normative layer)

EARS (Easy Approach to Requirements Syntax) is mandatory for every `SR-{NNN}`. There are five permitted forms:

1. **Ubiquitous**: `The {system} shall {action}.`
2. **Event-driven**: `When {trigger}, the {system} shall {action}.`
3. **State-driven**: `While {state}, the {system} shall {action}.`
4. **Unwanted-behavior**: `If {condition}, then the {system} shall {action}.`
5. **Optional-feature**: `Where {feature included}, the {system} shall {action}.`

Each requirement carries a unique stable ID: `SR-{NNN}`. A scenario-derived SR names its parent; a non-functional SR has none.

```markdown
- SR-001: When a user submits valid credentials, the system shall establish an authenticated session.   # ← SCN-001
- SR-002: If a login attempt uses an invalid password, then the system shall respond with HTTP 401.      # ← SCN-001
- SR-100: The system shall encrypt all customer records at rest using AES-256.                            # ← non-functional, no SCN
```

**Why EARS is still mandatory**: it is parseable, every requirement maps to a grader and a dataset, and it carries the non-functional requirements GWT can't express. Prose stories drift; EARS requirements don't.

---

## Spec document structure

`spec/spec.md`:

```markdown
---
version: "1.4.0"
status: active                # draft | active | superseded
last-amended: "2026-05-13"
amendments-pending: 0
---

# Specification — {Effort Name}

## Purpose
{One-paragraph statement of what this effort is and why. NOT requirements.}

## Scope
**In scope**: {bullet list}
**Out of scope**: {bullet list — explicit non-goals}

## Behavioral scenarios (primary)

### SCN-001: {short user-journey title}
**Given** {precondition — state and context}
**When** {trigger — user action or system event}
**Then** {outcome — system response and resulting state}

**Acceptance criteria:**
- {measurable criterion}
- {error / edge handling}

**Derived requirements:** SR-001, SR-002
**Covered by:** `evals/datasets/correctness-real-v1.jsonl` (tasks 1–3)

### SCN-002: ...

## Requirements (derived)

### Functional requirements
- SR-001: {EARS — derived from SCN-001}
- SR-002: {EARS — derived from SCN-001}
- ...

### Non-functional requirements
- SR-100: {EARS — performance, security, accessibility, cost. No SCN parent.}
- ...

## Traceability: scenario → requirement

| Scenario | Derived SR | Notes |
|----------|-----------|-------|
| SCN-001 | SR-001, SR-002, SR-005 | SR-005 is the rate-limit constraint |
| SCN-002 | SR-003 | |
| — | SR-100, SR-101 | Non-functional; no scenario parent |

## Invariants
{Statements that must remain true across all valid implementations.}
- INV-1: User identity is established before any data write.
- INV-2: No requirement may degrade accessibility below WCAG 2.2 AA.

## Conformance tests
{Reference to evals/datasets/ and evals/graders/ that verify the spec.}
- `evals/datasets/correctness-real-v3.jsonl` covers SR-001 through SR-042
- `evals/graders/accessibility.md` enforces INV-2

## Glossary
{Terms used in EARS requirements with precise definitions.}
- "user" = an authenticated identity in the `users` table with `status: active`
- "form submission" = a POST to /api/submit with content-type application/json

## Architectural context
{Non-binding but informative: stack, key components, integration points.}
{This section describes the world the spec lives in. It does not constrain
implementation more than the requirements do.}
```

---

## Evolution

Specs are append-only at the version level. Every change writes a new history file.

### Workflow

1. User invokes `/flow-spec` with a proposed change — a behavioral intent, a partial Given/When/Then, or (with `--requirement`) a direct non-functional requirement.
2. `flow-spec-writer`:
   - For user-observable behavior: forms a `SCN-{NNN}` scenario (counter-prompting until Given/When/Then and acceptance criteria are precise), then **derives** the `SR-{NNN}` requirements its criteria imply.
   - For non-functional intent: normalizes directly to EARS `SR-{NNN}` with no SCN parent.
   - Computes diff against current `spec.md`.
   - Classifies: `major | minor | patch | restructure`.
   - Drafts the new `spec.md` (scenarios + requirements + traceability) and history file.
   - If `major` or `restructure`: pauses for HITL preference-articulator (P3 + constitution).
3. On approval, writes the new `spec.md` and `spec/history/spec-v{N}.md`.
4. Triggers downstream:
   - `flow-eval` if any requirement is new or modified (eval suite may need new datasets/graders)
   - `flow-dissent` to check for dissent reactivation against the changed spec
   - `flow-narrator` to generate change-log artifacts from the diff

### Version semantics

| Change type | Versioning | Triggers |
|-------------|-----------|----------|
| Patch | `1.4.0 → 1.4.1` | Clarification, glossary edit, typo. No new SCN/SR IDs. No scenario or requirement semantics change. |
| Minor | `1.4.1 → 1.5.0` | New `SCN-{NNN}` or `SR-{NNN}` IDs added. No existing scenario or requirement modified or removed. |
| Major | `1.5.0 → 2.0.0` | Existing scenario or requirement modified, removed, or breaking glossary change. **HITL required.** |
| Restructure | `2.0.0 → 2.1.0-r1` | Reorganization of sections, scope, or invariants without semantic change. Track with `-r{N}` suffix. **HITL required.** |

---

## Code regeneration policy

When a spec change is published, generated code stays current via these rules.

| Change type | Policy |
|-------------|--------|
| Patch | No regeneration. |
| Minor (additive only) | New variants generated for new scenarios/requirements; existing code unchanged. `flow-generate` reads only the new SCN/SR-IDs. |
| Major (semantic change) | All variants regenerated for affected modules. Old variants archived to `generations/gen-{N}/superseded/`. |
| Restructure | No code change; only spec reorganization. |

The `flow-generator` is **forbidden** from inferring requirements not in the spec. If the spec is ambiguous, the agent raises a dissent rather than guessing.

---

## Authoring helpers

`flow-spec-writer` accepts natural language and converts it through the layered pipeline. User-observable behavior becomes a scenario first, then derives EARS; non-functional intent goes straight to EARS.

| NL input | Scenario (`SCN`) | Derived / direct EARS (`SR`) |
|----------|------------------|------------------------------|
| "Users should be able to log in." | Given valid credentials on file · When they submit the login form · Then a session is established and they reach the dashboard | SR: When a user submits valid credentials, the system shall establish an authenticated session. |
| "Rate-limited users should be told to wait." | Given a user has exceeded the request limit · When they make another request · Then they receive a 429 with a retry hint | SR: If the request rate exceeds the limit, then the system shall respond with HTTP 429 and a `Retry-After` header (integer seconds, ≤ 3600). |
| "Don't let people upload viruses." | *(no scenario — ambient safety constraint)* | SR: If an uploaded file matches a known malware signature, then the system shall reject the upload with HTTP 422. |
| "Fast response times." | *(rejected — too vague; counter-prompt for target)* | SR: The system shall respond to read requests within 200ms at p95 over a 24-hour window. |

The agent **refuses vague language** rather than fabricate precision — for both scenario acceptance criteria and EARS. Vagueness produces a HITL prompt asking for measurable criteria.

---

## Conformance test mapping

Each `SCN-{NNN}` seeds the **correctness** dataset directly: its acceptance criteria become graded tasks (typically 2–4 per scenario). Each `SR-{NNN}` maps to at least one grader + dataset combination. Both bindings live in `evals/harness.yaml`:

```yaml
mappings:
  - scenario: SCN-001
    graders: ["correctness"]
    datasets: ["correctness-real-v1"]
    tasks: [1, 2, 3]
    derived-requirements: ["SR-001", "SR-002", "SR-005"]
  - requirement: SR-001
    graders: ["correctness"]
    datasets: ["correctness-real-v3", "correctness-adv-v1"]
    threshold: 0.95
  - requirement: SR-100        # non-functional, no SCN parent
    graders: ["security"]
    datasets: ["security-real-v1"]
    threshold: 1.0
```

A spec that introduces a scenario or requirement with no conformance mapping is **incomplete**. `flow-spec-writer` will not finalize until either:
- A mapping is added to `evals/harness.yaml`, OR
- The requirement is marked `mapping-pending: true` with a TODO entry for `flow-eval` to address

---

## Spec invariants and conformance

INV-* statements differ from SR-* in that they must hold across **all valid implementations and all generations**. They are typically:

- Privacy / security boundaries
- Accessibility floors
- Data integrity rules
- Backwards compatibility guarantees

Invariants get a dedicated grader that runs against **every variant**, regardless of which SRs the variant emphasizes. Invariant grader failure is a hard cull condition (P4) — the variant is removed from the Pareto front entirely, not just dominated.

---

## Spec as executable

When the spec evolves to **spec-as-source** maturity (Fowler level 3, future state), the flow:

1. Human edits only the spec.
2. `flow-generate` regenerates all affected code from scratch.
3. Conformance tests verify the regenerated code matches the spec.
4. The repo's code is, in a meaningful sense, **derived state** — like compiled output.

Until then (`flow` v1 defaults to spec-anchored, level 2):
- Humans may edit code directly when the change is narrowly scoped.
- Code edits that touch the area governed by an SR-{NNN} require a spec amendment OR a documented "preserved divergence" note in `spec/constitution.md`.
- Conformance tests catch undocumented divergence.

---

## Constitution

`spec/constitution.md` is the meta-spec. It governs:

- **Prohibitions**: things no implementation may do, regardless of requirements
- **Preferences**: soft guidance for generators on style and approach
- **Escalation triggers**: conditions under which HITL surfaces
- **Dispatch overrides**: per-effort overrides to default orchestrator behavior

The constitution is authored by `flow-init` from project-kickoff input, amended via `flow-spec`, and read by **every** agent at startup. It is the closest analog to `delivery-team`'s `project-kickoff.md`.

A constitution change is **always** a major spec version increment, regardless of how small the textual diff.
