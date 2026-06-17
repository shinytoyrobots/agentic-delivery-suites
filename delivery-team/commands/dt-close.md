---
description: Sprint review phase — validate qa-gate, produce sprint summary + retrospective, update velocity, close Linear cycle, write memory
argument-hint: "[sprint number or 'current']"
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
  - mcp__claude_ai_Linear__list_cycles
  - mcp__claude_ai_Linear__save_issue
  - mcp__claude_ai_Linear__save_comment
capability-class: retrospective-learning
tier: II
domain: [dt]
works-with:
  requires-context: [dt-pipeline-stages, dt-artifact-schemas, dt-schemas-planning, dt-schemas-build, dt-schemas-review, dt-hitl-protocol, dt-definition-of-done, vault-access]
  upstream-skills: [dt-run]
  downstream-skills: [dt-start, dt-gate-review]
  compatible-agents: [dt-scrum-master, dt-aggressive-pm]
readiness:
  state: green
  idempotent: false
  warm-start: false
cost:
  model-class: high
  agent-count: 2
  web-calls: none
  context-budget: large
---

# Sprint Close

Read context files:
- `~/.claude/commands/context/dt-pipeline-stages.md`
- `~/.claude/commands/context/dt-artifact-schemas.md`
- `~/.claude/commands/context/dt-schemas-planning.md`
- `~/.claude/commands/context/dt-schemas-build.md`
- `~/.claude/commands/context/dt-schemas-review.md`
- `~/.claude/commands/context/dt-hitl-protocol.md`
- `~/.claude/commands/context/dt-definition-of-done.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Close out a sprint — validate that all QA gates have passed, produce a comprehensive sprint summary with integrated retrospective analysis, update velocity tracking, close the Linear cycle, and write sprint memory for future reference. This is the Review phase (Stage 7).

This skill combines what were previously two separate ceremonies (sprint close and sprint retrospective) into a single pass. The retrospective is narrowly focused on agent prompt quality, story sharding effectiveness, gate calibration, and velocity accuracy. For general team/cycle retrospectives, use a general retrospective skill.

## Input

`$ARGUMENTS` = sprint number, effort name, `{effort} {sprint-number}`, or "current" (default: current).

See `dt-artifact-schemas.md` § Effort Resolution.

## Prerequisites

- `sprint-status.yaml` must exist with all stories in `done` or `blocked` status
- `qa-gate.md` files must exist for all completed stories

Read `project-kickoff.md` to load: HITL level, stack, conventions.

## Process

### Phase 1: Pre-Close Validation

#### Step 1: Read Sprint State

Read `sprint-status.yaml` and classify stories:
- **Completed**: status = done, gate-status = pass
- **Failed gate**: status = done, gate-status = fail
- **Blocked**: status contains blocked
- **Incomplete**: any other status

#### Step 2: Validate QA Gates

Read all `qa-gate.md` files. For each completed story:
- Verify verdict = PASS
- Collect advisory findings for the summary
- Flag any FAIL verdicts — these block sprint close

If any story has a FAIL gate:
- Report which stories failed and why
- Advise: "Resolve QA failures before closing. Run `/sprint-run` to address failed stories, or `/sprint-blocker` to register the blocker."
- Exit without closing

#### Step 3: Check for Active Vetoes

Read `design-veto.md` if it exists. Any active design veto blocks sprint close.

### Phase 2: Sprint Summary + Retrospective

#### Step 1: Prior Action Review

Read `sprints/{effort}/sprint-memory.md` and extract all entries from the `retro-actions` section with status `open` or `implemented` (outcome pending).

If no prior retro exists (first sprint), skip to Step 2.

For each prior action:

1. **Check implementation**: Examine sprint artifacts (`prompt-improvements.md` history, agent methodology files, gate configurations, story files) to determine if the action was implemented.
2. **Measure outcome**: If implemented, compare the target metric before and after:
   - Prompt quality actions -> QA pass rate for that agent type
   - Story quality actions -> dev agent external-document-reference count
   - Gate actions -> false positive/negative rate
   - Velocity actions -> estimation accuracy delta
3. **Update status**: Set `implemented` + outcome (`improved` / `no-change` / `worsened` / `inconclusive`), or keep `open` if not yet implemented.

**Staleness rule**: Actions that have been `open` for 3+ sprints -> present to user via `AskUserQuestion`:
> "Retro action {id} has been open since sprint {N}: '{description}'. Should we: (a) implement it this sprint, (b) drop it with a reason, or (c) reformulate it?"

Calculate the rolling retro action completion rate as a meta-metric.

#### Step 2: Invoke Scrum Master for Summary + Analysis

Launch `~/.claude/commands/agents/dt-scrum-master.md` subagent to produce both the sprint summary and the five-dimension retrospective analysis. Provide it with:
- `sprint-status.yaml` (full sprint state)
- All `qa-gate.md` files (quality data)
- All `story-{id}.md` files (story quality assessment)
- `sprint-plan.md` (original plan for comparison)
- `sprint-notes.md` (discovery/planning context)
- `dependency-map.md` (execution plan vs. actual sequence)
- `sprint-memory.md` (prior sprint trends)
- `project-kickoff.md` (project context)

The summary should include:
- Sprint goal assessment (met / partially met / not met)
- Stories completed vs. planned
- Velocity data (points completed, cycle time per story)
- Quality summary (QA findings, advisory items)
- Blockers encountered and resolution
- Fast-follow candidates (work deferred or discovered during sprint)

The five-dimension analysis:

**1. Prompt Quality**
- Which agent methodology files produced expected behavior?
- Trace gate failures backward through contributing factors: was the failure caused by the agent's prompt, by insufficient story context, by a missing pattern, or by a genuinely novel problem?
- Per-agent QA pass rate and gate rejection rate

**2. Story Quality**
- Were stories self-contained enough for dev agents to implement without consulting external documents?
- Did any dev agent reference files not listed in the story's Architecture Context or Design References sections?
- Sharding effectiveness: were stories the right size? Any that should have been split or merged?

**3. Gate Effectiveness**
- Did gates catch real problems (true positives) or create friction (false positives)?
- Were any blocking findings actually false positives that delayed the sprint?
- Were any issues missed by gates that surfaced later (false negatives)?
- Gate overhead: average time from story completion to gate verdict

**4. Velocity Calibration**
- Estimated vs. actual points completed
- Per-agent cycle time (time from `in-progress` to `done`)
- Estimation accuracy by story complexity/risk level
- Comparison to rolling 3-sprint velocity average from `sprint-memory.md`

**5. Action Follow-Through (meta-dimension)**
- What % of prior retro actions were completed?
- Of completed actions, what % produced measurable improvement?
- Are there recurring action themes that suggest a systemic issue?

**Structural guard**: The analysis must produce at least one root-cause observation that goes beyond fast-follow symptom listing. If the sprint was clean (100% pass, on-target velocity), the root-cause observation can be "what structural factor enabled this outcome" rather than a problem diagnosis.

#### Step 3: Gate Review -- T+2 Fast-Follow

Launch `~/.claude/commands/agents/dt-aggressive-pm.md` subagent to prioritize fast-follow items from the sprint. Provide the sprint summary, deferred work list, and any new issues discovered during QA. The Aggressive PM should produce a Time Cost assessment for each fast-follow candidate.

#### Step 4: Generate DAKI Recommendations

Based on the five-dimension analysis, produce **maximum 3 recommendations**. Each must be one of:

- **DROP**: Remove a behavior, prompt pattern, or gate configuration that consistently fails. Evidence must show repeated failure across this sprint (or prior sprints if pattern is recurring).
- **ADD**: Introduce a new strategy observed to be missing. Must reference a specific gap identified in the analysis.
- **KEEP**: Confirm a practice that metrics show is working. No change needed; continue monitoring. (Keep items do not count toward the 3-action cap.)
- **IMPROVE**: Refine a partially effective pattern. Must include a **testable hypothesis** with measurable success criteria.

Each recommendation includes:
- **Category**: prompt | story-quality | gate | velocity | process
- **Target artifact**: Specific file path (which agent methodology file, gate config, or process document)
- **Evidence**: What happened this sprint that supports this recommendation
- **Confidence**: High (multiple sprints of data) | Medium (one sprint, clear signal) | Low (one sprint, ambiguous signal)
- **Hypothesis** (Improve only): "If we {change}, then {metric} will {improve by threshold}"
- **Success criteria** (Improve only): Measurable threshold for the next sprint close to evaluate

### Phase 3: HITL Checkpoint

Check HITL level from `project-kickoff.md`:
- **Level 1-2**: Present sprint summary, retro analysis, and recommendations. Ask: "Review this sprint summary and retrospective. Approve, modify, or reject recommendations before I persist?"
- **Level 3**: Present summary and recommendations for awareness. Ask: "Any objections before I persist?"
- **Level 4**: Auto-persist. Display for awareness.

### Phase 4: Persistence & Cleanup

#### Step 1: Write to Vault

Write `sprint-{N}-summary.md` to `sprints/{effort}/sprint-{N}/`.
Write `sprint-{N}-retro.md` to `sprints/{effort}/sprint-{N}/`.

Write to vault per `context/vault-access.md`:
- `docs/Delivery-Team/{date}/sprint-{N}-summary.md`
- `docs/Delivery-Team/{date}/sprint-{N}-retro.md`

#### Step 2: Update Sprint Memory

Read `sprints/{effort}/sprint-memory.md`. Update:
- Velocity section with this sprint's data
- Recurring blockers with any new patterns
- Agent performance with observations from this sprint

Append new DAKI recommendations to the `retro-actions` section using the structured format:

```yaml
retro-actions:
  - id: RETRO-S{N}-01
    sprint-originated: {N}
    type: drop | add | keep | improve
    category: prompt | story-quality | gate | velocity | process
    description: "{action description}"
    target-artifact: "{file path}"
    hypothesis: "{if applicable}"
    success-criteria: "{if applicable}"
    status: open
    implemented-sprint: null
    outcome: null
    evidence: null
```

Update prior action statuses based on Phase 2 Step 1 findings.

#### Step 3: Write Prompt Improvements

If any recommendation targets an agent methodology file, write `sprints/{effort}/sprint-{N}/prompt-improvements.md` with specific suggested changes. Reference the retro-action ID for traceability.

#### Step 4: Update sprint-status.yaml

Set sprint status to `closed`. Set `completed` date.

#### Step 5: Stale-Branch Audit

Run `git fetch origin && git remote prune origin` and capture output. If fetch fails (no network or no `origin`), emit "Could not reach origin; stale-branch audit skipped" and proceed without halting close.

Identify stale remote branches by two heuristics: (a) branches whose slug matches a merged-PR title from this sprint (prefer `gh pr list --state merged --base main --limit 50` when available; fall back to `git log --remotes` parsing), and (b) branches with last-commit date >30 days ago. If `gh` is unavailable, use only the 30-day heuristic.

Report matches as an ADVISORY list in the sprint summary. If none found, report "No stale branches detected" and proceed silently.

**WARNING**: Do NOT run `git push origin --delete <branch>` automatically. Remote branch deletion is destructive and requires user approval. Report only.

#### Step 6: Close Linear Cycle

Update all Linear issues to their final status. Close the Linear cycle.

## Output Artifacts

### sprint-{N}-summary.md

```markdown
# Sprint {N} Summary
**Generated**: {YYYY-MM-DD HH:MM}
**Skill**: /dt-close
**Sprint**: {start date} -- {end date}
---

## Goal Assessment
**Goal**: {sprint goal}
**Outcome**: {Met / Partially Met / Not Met}
{1-2 sentence assessment}

## Delivery Metrics
| Metric | Planned | Actual |
|--------|---------|--------|
| Stories | {N} | {N completed} |
| Points | {N} | {N completed} |
| Cycle time (avg) | -- | {N} days |
| QA pass rate | -- | {N}% |
| Blockers | -- | {N} |

## Story Results
| Story | Title | Status | Points | Cycle Time | QA Verdict |
|-------|-------|--------|--------|------------|------------|
| ... |

## Quality Summary
### QA Advisory Findings
{Consolidated advisory findings across all stories}

### Recurring Patterns
{Any patterns in QA findings that suggest systemic issues}

## Blockers & Resolutions
{List of blockers encountered, how they were resolved, time impact}

## Fast-Follow Candidates
{Aggressive PM's prioritized list with Time Cost assessments}

## Velocity Trend
{Rolling 3-sprint average if prior sprint data exists in vault}
```

### sprint-{N}-retro.md

```markdown
# Sprint {N} Retrospective
**Generated**: {YYYY-MM-DD HH:MM}
**Skill**: /dt-close
**Sprint**: {start date} -- {end date}
---

## Prior Action Review

| ID | Sprint | Type | Description | Status | Outcome |
|----|--------|------|-------------|--------|---------|
| RETRO-S{N-1}-01 | {N-1} | improve | ... | implemented | improved |
| RETRO-S{N-1}-02 | {N-1} | add | ... | open (carried) | -- |

**Action completion rate**: {N}% (rolling 3-sprint: {N}%)

## Five-Dimension Analysis

### 1. Prompt Quality
**Signal**: {per-agent QA pass rate, gate rejection rate}
{Contributing factor chains for any failures}

### 2. Story Quality
**Signal**: {self-containment score, external reference count}
{Sharding effectiveness observations}

### 3. Gate Effectiveness
**Signal**: {true positive rate, false positive rate, gate overhead}
{Specific gate calibration observations}

### 4. Velocity Calibration
**Signal**: {estimated vs actual points, per-agent cycle time}
{Estimation accuracy by complexity tier}

### 5. Action Follow-Through
**Signal**: {completion rate, outcome distribution}
{Stale action escalations}

## Recommendations

### DROP: {title}
- **ID**: RETRO-S{N}-01
- **Category**: {prompt | story-quality | gate | velocity | process}
- **Target**: {artifact path}
- **Evidence**: {what happened this sprint}
- **Confidence**: {High | Medium | Low}

### IMPROVE: {title}
- **ID**: RETRO-S{N}-02
- **Category**: {prompt | story-quality | gate | velocity | process}
- **Target**: {artifact path}
- **Hypothesis**: {if we do X, then Y}
- **Success criteria**: {measurable threshold}
- **Confidence**: {High | Medium | Low}

### KEEP: {title}
- **Evidence**: {metrics confirming effectiveness}
```

## Chaining

After close:
> Sprint {N} closed. Velocity: {points} points in {days} days. {N} new retro actions, {N} prior actions reviewed ({N}% completion rate).
> - `/dt-start` — begin next sprint (reads retro actions from sprint-memory.md)
> - `/dt-readiness-gate` — run cross-functional readiness check (if approaching release)
> - `/dt-gate-review 7` — adversarial review of fast-follow priorities
