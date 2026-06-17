---
description: Cross-functional readiness check — launch GTM, Marketing, and CX/Support agents in parallel, aggregate into readiness assessment
argument-hint: "[project name or 'current']"
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
  - mcp__claude_ai_Linear__list_issues
  - mcp__claude_ai_Linear__get_issue
  - mcp__claude_ai_Notion__search
  - mcp__claude_ai_Notion__fetch
  - mcp__claude_ai_HubSpot__search_crm_objects
  - mcp__claude_ai_HubSpot__get_crm_objects
  - mcp__claude_ai_Slack__slack_read_channel
  - mcp__claude_ai_Slack__slack_search_public_and_private
capability-class: execution-orchestration
tier: I
domain: [dt]
works-with:
  requires-context: [dt-pipeline-stages, dt-artifact-schemas, dt-schemas-review, dt-hitl-protocol, dt-readiness-schema, dt-integration-map, vault-access]
  upstream-skills: [dt-release-plan, dt-gate-review]
  downstream-skills: [dt-release-comms, dt-release]
  compatible-agents: [dt-gtm-sales, dt-marketing, dt-cx-support]
readiness:
  state: green
  idempotent: false
  warm-start: true
cost:
  model-class: high
  agent-count: 3
  web-calls: none
  context-budget: xlarge
---

# Readiness Gate

Read context files:
- `~/.claude/commands/context/dt-pipeline-stages.md`
- `~/.claude/commands/context/dt-artifact-schemas.md`
- `~/.claude/commands/context/dt-schemas-review.md`
- `~/.claude/commands/context/dt-hitl-protocol.md`
- `~/.claude/commands/context/dt-readiness-schema.md`
- `~/.claude/commands/context/dt-integration-map.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Run the Stage 5 Cross-Functional Readiness check. This launches GTM/Sales, Marketing, and CX/Support agents in parallel to assess whether the organization is ready to ship — beyond just code quality. This gate is always HITL regardless of calibration level. No feature ships without human sign-off on cross-functional readiness.

## Input

`$ARGUMENTS` = project/effort name or "current" (default: current effort from `sprints/efforts.yaml`).

See `dt-artifact-schemas.md` § Effort Resolution.

## Prerequisites

- `project-kickoff.md` — project context
- `launch-tier.md` — launch tier (determines scope of readiness requirements)
- `qa-gate.md` — QA verification complete (all stories passed)
- `sprint-status.yaml` — all stories in `done` status
- `design-spec.md` — design intent for stakeholder context
- `architecture-proposal.md` — architecture decisions (if produced by `/dt-architect`); used for context but readiness is not blocked on its presence
- `sprint-{N}-summary.md` — sprint results (if available)

**Architecture artifact presence check:** if `architecture-proposal.md` exists, verify a `dt-architect-review-*.md` companion exists with verdict `READY` or `MINOR REVISIONS`. If the review is `BLOCKING REVISIONS` or missing, add an ADVISORY to the readiness aggregation: "Architecture proposal exists but was not reviewed (or has blocking findings). Recommend running `/dt-architect-review` before launch decision." Do not block the gate — readiness is about cross-functional readiness, not architectural quality.

Read all prerequisites. If QA gates are not all passed, report: "QA gates must pass before cross-functional readiness. Run `/sprint-close` or resolve QA failures first." Exit.

## Phase 1: Parallel Stakeholder Assessment

Launch three agents in parallel — each operates independently with full context.

### Agent A: GTM/Sales Assessment

Launch `~/.claude/commands/agents/dt-gtm-sales.md` subagent (model: haiku) to produce a GTM readiness assessment. Provide:
- `project-kickoff.md` (project context, target users)
- `design-spec.md` (what was built)
- `launch-tier.md` (tier-appropriate requirements)
- Sprint summary (delivery results)

The GTM agent should:
1. Search HubSpot for deals affected by this feature (closing in next 60 days, relevant segment)
2. Assess sales enablement readiness (battlecards, competitive positioning, demo readiness)
3. Identify customer commitments tied to this feature
4. Produce `gtm-readiness.md` with verdict: READY / CONDITIONAL / NOT READY

### Agent B: Marketing Assessment

Launch `~/.claude/commands/agents/dt-marketing.md` subagent (model: haiku) to produce a marketing readiness assessment. Provide:
- `project-kickoff.md` (project context)
- `design-spec.md` (what was built)
- `launch-tier.md` (tier determines content requirements)
- Sprint summary

The Marketing agent should:
1. Verify tier-appropriate content exists or is drafted:
   - **Tier 1**: Changelog, blog post, social posts, email campaign, landing page update, internal announcement
   - **Tier 2**: Changelog, blog post, social posts, internal announcement
   - **Tier 3**: Changelog, internal announcement
2. Verify content accuracy against what was actually built (not what was planned)
3. Produce `marketing-readiness.md` with verdict: READY / CONDITIONAL / NOT READY

### Agent C: CX/Support Assessment

Launch `~/.claude/commands/agents/dt-cx-support.md` subagent (model: haiku) to produce a support readiness assessment. Provide:
- `project-kickoff.md` (project context)
- `design-spec.md` (what was built, user-facing changes)
- Sprint summary

The CX/Support agent should:
1. Identify documentation impact (new help articles needed, existing articles to update)
2. Draft help article outlines for new user-facing features
3. Assess support team briefing needs
4. Search existing Notion docs for articles that need updating
5. Produce `support-readiness.md` with verdict: READY / CONDITIONAL / NOT READY

## Phase 2: Aggregation

After all three agents return, synthesize into `cross-functional-readiness.md`:

```markdown
# Cross-Functional Readiness: {Project Name}
**Generated**: {YYYY-MM-DD HH:MM}
**Skill**: /readiness-gate
**Launch Tier**: {tier}
---

## Overall Verdict: {GO / CONDITIONAL GO / NO-GO}

## Function Readiness

| Function | Verdict | Key Gaps | Remediation ETA |
|----------|---------|----------|-----------------|
| GTM/Sales | {READY/CONDITIONAL/NOT READY} | {gaps} | {ETA if conditional} |
| Marketing | {READY/CONDITIONAL/NOT READY} | {gaps} | {ETA if conditional} |
| CX/Support | {READY/CONDITIONAL/NOT READY} | {gaps} | {ETA if conditional} |

## GTM Summary
{2-3 bullet highlights from gtm-readiness.md}
### Deal Impact
{List of affected deals with stage and close date}
### Sales Enablement Status
{What's ready, what's missing}

## Marketing Summary
{2-3 bullet highlights from marketing-readiness.md}
### Content Status (Tier {N} Requirements)
| Content Type | Status | Owner | ETA |
|-------------|--------|-------|-----|
| Changelog | {Done/Draft/Not Started} | ... | ... |
| ... |

## CX/Support Summary
{2-3 bullet highlights from support-readiness.md}
### Documentation Impact
| Article | Action | Status |
|---------|--------|--------|
| {article title} | {New/Update} | {Done/Draft/Not Started} |
| ... |

## Blocking Issues
{List of issues that must be resolved before GO}

## Conditions for CONDITIONAL GO
{If applicable: specific items + hard deadlines}

## Recommendation
{SM recommendation with rationale}
```

## Phase 3: HITL Decision (Always Required)

This gate always requires human sign-off. Regardless of HITL level.

Use `AskUserQuestion`:

"Cross-functional readiness assessment complete. Overall verdict: {verdict}.

{Brief summary of each function's status}

**Your decision:**
- **GO** — proceed to Comms + Release (Stage 6)
- **CONDITIONAL GO** — proceed with specific remediation items on a hard deadline
- **NO-GO** — hold release, address gaps first

What is your decision?"

If the user chooses CONDITIONAL GO, ask for the hard deadline and specific conditions.

## Persistence

Write all readiness documents to `sprints/{effort}/sprint-{N}/`:
- `cross-functional-readiness.md`
- `gtm-readiness.md`
- `marketing-readiness.md`
- `support-readiness.md`

Write to vault per `context/vault-access.md`: `docs/Delivery-Team/{date}/cross-functional-readiness.md`

## Chaining

After readiness gate:
- **GO**: "Run `/gate-review 5` for adversarial PM review, then proceed to Stage 6 (Comms + Release)."
- **CONDITIONAL GO**: "Address the conditions listed above. Run `/readiness-gate` again when ready."
- **NO-GO**: "Address the gaps. Run `/readiness-gate` when all functions are ready."
