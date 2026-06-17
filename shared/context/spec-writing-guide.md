# Spec Writing Guide

Reference for EARS grammar, RFC 2119 keywords, Given-When-Then format, protection patterns, and anti-patterns. Loaded by pm-spec, pm-spec-review, dt-story-review, and dt-start.

---

## EARS Grammar (5 Patterns)

EARS (Easy Approach to Requirements Syntax) provides structured templates that eliminate vague "system shall" statements.

| Pattern | Template | When to Use |
|---------|----------|-------------|
| **Ubiquitous** | `THE SYSTEM SHALL {action}` | Always-on behavior, no trigger needed |
| **Event-driven** | `WHEN {event} THE SYSTEM SHALL {response}` | Response to a discrete trigger |
| **State-driven** | `WHILE {state} THE SYSTEM SHALL {behavior}` | Continuous behavior in a persistent condition |
| **Optional** | `WHERE {feature is included} THE SYSTEM SHALL {behavior}` | Conditional capability |
| **Unwanted behavior** | `IF {unwanted condition} THEN THE SYSTEM SHALL {safeguard}` | Error handling, safety constraints |

### Examples

- **Ubiquitous**: THE SYSTEM SHALL log all API requests with timestamp and HTTP status.
- **Event-driven**: WHEN a user submits a form with invalid email, THE SYSTEM SHALL display an inline validation error within 200ms.
- **State-driven**: WHILE a background sync is in progress, THE SYSTEM SHALL disable the manual refresh button.
- **Optional**: WHERE multi-factor authentication is enabled, THE SYSTEM SHALL require a TOTP code on every login.
- **Unwanted behavior**: IF a payment gateway returns a 5xx error, THEN THE SYSTEM SHALL retry once after 3 seconds and surface a user-facing error message on second failure.

---

## RFC 2119 Keywords

Use these keywords to signal requirement strength. Inconsistent usage causes scope ambiguity.

| Keyword | Strength | Meaning |
|---------|----------|---------|
| **MUST** / **SHALL** | Mandatory | Non-negotiable. Violating this is a defect. |
| **MUST NOT** / **SHALL NOT** | Prohibited | Explicitly forbidden. Violations block acceptance. |
| **SHOULD** | Strongly recommended | Default behavior; deviation requires documented justification. |
| **MAY** | Optional | Permitted but not required. No justification needed to omit. |

### Guidance for Spec Authoring

- Default to SHALL in EARS patterns — it pairs with the structural template.
- Use SHOULD when platform constraints or performance trade-offs may legitimately force deviation.
- Use MAY to mark extensibility points, not to hedge mandatory behavior.
- Avoid paraphrases ("is expected to", "will", "needs to") — they introduce ambiguity about enforceability.

---

## Given-When-Then (GWT) Format

GWT translates EARS requirements into testable acceptance scenarios using Gherkin BDD structure.

```
Given {precondition — system and user state}
When  {event — the action or trigger}
Then  {outcome — observable, verifiable result}
```

### Example (derived from EARS Event-driven pattern above)

```
Given a user is on the registration form with an invalid email address
When  they submit the form
Then  an inline error message appears beneath the email field within 200ms
And   the form is not submitted to the server
```

**Rules:**
- Each scenario tests exactly one behavior.
- "Then" outcomes MUST be observable without accessing internal state.
- Map each GWT scenario back to the EARS statement it validates.

---

## Protection Patterns

Use MUST NOT to define the boundary of a skill's write scope. List every resource the skill is not permitted to modify.

### Syntax

```
The agent MUST NOT modify: {comma-separated list of files, schemas, or APIs}
```

### Example

```
The agent MUST NOT modify: production database schemas, the /api/payments endpoint contract,
shared/context/frameworks.md, or any file outside the assigned suite directory.
```

**Where to place it**: In the skill's frontmatter constraints block or in the first section of a context file loaded by that skill. This creates an explicit, scannable scope boundary reviewers can verify.

---

## Anti-Pattern Checklist

Before finalizing any spec, verify it does not contain these failure modes:

- [ ] **Vagueness** — Requirements use unmeasurable language ("fast", "easy", "robust"). Replace with specific thresholds (e.g., "under 300ms at P95").
- [ ] **Context rot** — The spec references external docs, states, or systems that may change without updating this file. Pin versions or inline the critical details.
- [ ] **Missing constraints** — The happy path is defined but error states, rate limits, and edge cases are absent. Every EARS pattern should have a paired Unwanted-behavior pattern for its failure mode.
- [ ] **No self-verification** — The spec cannot confirm its own outputs. Include at least one GWT scenario or measurable signal per requirement.
- [ ] **Scope creep risk** — Requirements use open-ended phrasing ("and any related functionality", "as needed"). Use MUST NOT protection patterns to draw hard boundaries.

---

## Context Budget Guidance

Spec and context files loaded into agent sessions consume tokens that compete with reasoning and output. Follow these ceilings:

- **60% context window ceiling** — Total loaded context (system prompt + skill files + conversation history) MUST NOT exceed 60% of the model's context window at session start. Reserve 40% for reasoning chain and output generation.
- **150-instruction cap** — A single skill file SHOULD contain no more than 150 discrete instructions. Above this, instruction-following accuracy degrades measurably.
- **Shared context files** (like this one) are loaded by multiple skills simultaneously — every line here multiplies across all consuming sessions. Prefer tables and bullet lists over prose. Remove examples once the pattern is clear to the team.
- **Audit trigger**: If a consuming skill starts producing truncated or inconsistent outputs, check total context load before debugging logic.
