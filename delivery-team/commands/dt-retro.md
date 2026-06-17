---
description: "[DEPRECATED] Sprint retrospective — amalgamated into dt-close"
argument-hint: "[sprint number or 'current']"
model: opus
allowed-tools:
  - Read
  - AskUserQuestion
capability-class: retrospective-learning
tier: II
domain: [dt]
works-with:
  requires-context: []
  upstream-skills: [dt-close]
  downstream-skills: []
  compatible-agents: []
readiness:
  state: deprecated
  idempotent: true
  warm-start: false
cost:
  model-class: minimal
  agent-count: 0
  web-calls: none
  context-budget: minimal
---

# Sprint Retro (Deprecated)

> **This skill has been amalgamated into `/dt-close`.**
>
> As of 2026-04-22, the sprint retrospective (prior action review, five-dimension analysis, DAKI recommendations) runs as an integrated phase within `/dt-close`. There is no longer a separate retro ceremony.

## Migration

- **Before**: `/dt-close` then `/dt-retro` as two separate invocations
- **After**: `/dt-close` produces both `sprint-{N}-summary.md` and `sprint-{N}-retro.md` in a single pass

## Rationale

Sprint-5 of flywheel-dashboard revealed that running close and retro as separate ceremonies produced redundant analysis. Both skills invoked the Scrum Master on the same data, generating overlapping observations. The retro's five-dimension analysis and DAKI recommendations are now Phase 2 of `/dt-close`, eliminating the second context-load while preserving all retrospective rigor (prior action review, staleness enforcement, structural guard, prompt-improvements.md).

## If invoked

Use `AskUserQuestion` to inform the user: "The `/dt-retro` skill has been merged into `/dt-close`. Run `/dt-close` instead — it now includes the full retrospective with prior action review, five-dimension analysis, and DAKI recommendations."
