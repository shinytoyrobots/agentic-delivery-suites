---
description: QA shift-left story review — flag untestable ACs, ambiguous specs, and missing edge cases before dev starts
argument-hint: <story-id or "all" for full sprint review>
model: sonnet
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - Agent
capability-class: content-review
tier: II
domain: [dt]
works-with:
  requires-context: [dt-artifact-schemas, dt-schemas-planning, dt-definition-of-done, dt-pipeline-stages, spec-writing-guide]
  upstream-skills: [dt-start]
  downstream-skills: [dt-run]
  compatible-agents: [dt-qa-tester]
readiness:
  state: green
  idempotent: true
  warm-start: false
cost:
  model-class: medium
  agent-count: 1
  web-calls: none
  context-budget: medium
---

# Story Review

Read context files:
- `~/.claude/commands/context/dt-artifact-schemas.md`
- `~/.claude/commands/context/dt-schemas-planning.md`
- `~/.claude/commands/context/dt-definition-of-done.md`
- `~/.claude/commands/context/dt-pipeline-stages.md`
- `~/.claude/commands/context/spec-writing-guide.md` (EARS patterns + HDD structure reference)

## Purpose

Invoke the QA Tester in shift-left mode to review story files before development begins. This catches untestable acceptance criteria, ambiguous specifications, missing edge cases, and gaps in the definition of done — all before a single line of code is written. This skill runs at Stage 3 (Technical Spec), before `/sprint-run`.

## Input

`$ARGUMENTS` = a specific story ID (e.g., `story-042`) or `all` to review every story in the current sprint.

If `$ARGUMENTS` is empty, default to `all`.

## Process

### Step 1: Gather Stories

See `dt-artifact-schemas.md` § Effort Resolution.

If reviewing a single story:
- Read `story-{id}.md` from `sprints/{effort}/sprint-{N}/`

If reviewing all stories:
- Read `sprint-status.yaml` to get the story list
- Read each `story-{id}.md` file

Also read supporting artifacts if they exist:
- `design-spec.md` — design specifications
- `api-contract.yaml` — API contract definitions
- `project-kickoff.md` — project context and conventions

### Step 2: Invoke QA Tester (Shift-Left Mode)

For each story (or batch if reviewing all), launch `~/.claude/commands/agents/dt-qa-tester.md` subagent (model: sonnet) to perform a pre-implementation review of the story file(s).

The QA agent should evaluate each story for:
1. **Acceptance criteria testability** — Can each AC be verified with a concrete test? Flag vague ACs ("should be fast", "user-friendly", "secure").
2. **Edge cases** — Are error states, boundary conditions, empty states, and concurrent access scenarios covered?
3. **Accessibility** — Are WCAG 2.2 AA requirements addressed in the ACs? Are keyboard navigation and screen reader expectations specified?
4. **API contract alignment** — If the story touches APIs, do the ACs match the api-contract.yaml?
5. **Design spec alignment** — If a design spec exists, do the ACs cover all interaction states in the spec?
6. **Definition of Done gaps** — Does the story account for all items in the project's DoD?
7. **Dependencies** — Are blocked-by relationships complete? Are there implicit dependencies not captured?
8. **EARS grammar** — Does each AC match one of the 5 EARS patterns from `spec-writing-guide.md` (Ubiquitous, Event-driven, State-driven, Optional, Unwanted-behavior)? Record the matched pattern in the Testability table's `EARS pattern` column, or `NONE` if the AC reads as prose.
9. **HDD structure** — Does the story's problem statement or dev notes follow the Hypothesis-Driven Development frame ("We Believe / Will Result In / We Will Know")? This applies when the story references a hypothesis or bet — purely deterministic stories (bug fixes, refactors) are exempt.

### EARS pattern detection

Apply a simple keyword heuristic against each AC's leading clause:
- `THE {entity} SHALL` (no trigger) → **Ubiquitous**
- `WHEN {event}, THE {entity} SHALL` → **Event-driven**
- `WHILE {state}, THE {entity} SHALL` → **State-driven**
- `WHERE {feature-included}, THE {entity} SHALL` → **Optional**
- `IF {unwanted-condition}, THEN THE {entity} SHALL NOT / MUST NOT` → **Unwanted-behavior**

False negatives (a valid EARS AC missed by the heuristic) are acceptable. False positives (a prose AC passed as EARS) should be minimized. When in doubt, flag as `NONE` and let the author confirm.

**Pass-through for pm-spec output**: Stories authored by `/pm-spec` use stable IDs (`FR-n`, `AC-n`) and are guaranteed EARS-formatted. When the story's frontmatter indicates pm-spec origin or the ACs use these ID patterns, mark the EARS column `YES (pm-spec)` and do not attempt rewrites — pm-spec is the reference format, not a subject of review.

### EARS reformulation

WHEN an AC is flagged as `NONE`, THE REVIEW SHALL place a scaffold rewrite in the `Suggested Revision` column. Prefer a generic but directionally correct scaffold ("WHEN {trigger condition from AC prose}, THE SYSTEM SHALL {response extracted from AC prose}") over a clever rewrite. The author refines it.

### Operator-Artifact AC classification

For each AC, classify the deliverable per `context/dt-definition-of-done.md` § Operator-Artifact ACs § Definition: (a) code/fixture/config, (b) prose/documentation, (c) operator artifact (signed-off table, named PR comment, named sign-off URL). For each category-(c) AC, verify the AC includes explicit operational sequencing language at the AC level (not buried in tasks) — required forms include "PR opened only after [artifact] is populated", "PR cannot merge until [artifact] is signed off", or equivalent. If sequencing is in tasks but not in the AC itself, flag as **MINOR REVISION** ("AC names the artifact but not the sequencing — operator may treat artifact as deferrable; recommend hoisting sequencing language from T-N up to AC-N as a SHALL clause"). If both AC and tasks lack sequencing language for an operator artifact, flag as **BLOCKING REVISION** — the dev agent has no signal that the artifact must precede PR-open.

### HDD structural check

Scan the story's `## Story` block and `## Dev Notes` for the three HDD components. WHEN HDD structure is absent AND the story language implies a hypothesis ("we think", "we believe", "should result in", "we expect"), THE REVIEW SHALL add to `### Recommendations`: "Consider restating the problem as an HDD hypothesis — see spec-writing-guide.md." Bug fixes and deterministic refactors do not need HDD framing.

### Step 3: Compile Review

Produce a review document per story:

```markdown
## Story Review: {story-id} — {story title}
**Reviewed**: {YYYY-MM-DD}
**Verdict**: READY / MINOR REVISIONS / BLOCKING REVISIONS

### Testability Assessment
| AC | Testable? | EARS pattern | Issue | Suggested Revision |
|----|-----------|--------------|-------|--------------------|
| AC-1 | Yes | Event-driven | — | — |
| AC-2 | No | NONE | Vague: "should be fast" | "WHEN the endpoint is called under 100 concurrent users, THE SYSTEM SHALL respond in under 200ms at P95" |
| AC-3 | Yes | YES (pm-spec) | — | — |

### Missing Edge Cases
- {edge case description} — suggest adding as AC-{N}

### Accessibility Gaps
- {gap description}

### Dependency Issues
- {issue description}

### Recommendations
- {numbered list of changes needed before dev starts}
```

### Verdict Calibration

| Verdict | Definition | Examples |
|---------|------------|----------|
| READY | Story is implementable as-written. No revisions required. | Stable AC, complete dependencies, clear architecture references. |
| MINOR REVISIONS | Story can be implemented with minor AC tightenings. Revisions improve clarity but are NOT required to start. | AC names wrong file path, missing diff ceiling, ambiguous wording in non-load-bearing AC. |
| BLOCKING REVISIONS | Story cannot start without revision. Implementation will fail or rework. | Missing `depends-on` link, contradictory ACs, missing architecture reference for load-bearing file. |

### Step 4: Write Output

- If reviewing a single story: write `story-review-{id}.md` to `sprints/{effort}/sprint-{N}/`
- If reviewing all stories: write `story-review-sprint-{N}.md` to `sprints/{effort}/sprint-{N}/` with all story reviews consolidated

Display the review summary in the conversation.

## HITL Checkpoints

None — this is an advisory skill. The review findings are recommendations, not gates. The Scrum Master decides whether to update story files based on the findings.

## Persistence

Review files are written to `sprints/{effort}/sprint-{N}/`. They are working artifacts — not persisted to the vault.

## Chaining

After review, suggest: "Update story files with the recommended revisions, then run `/sprint-run` to begin implementation."
