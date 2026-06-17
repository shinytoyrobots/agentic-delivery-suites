---
description: Implementation phase — orchestrate story-by-story execution with parallel dev agents, QA gates, and blocker management
argument-hint: "'all' or specific story-id to run a single story"
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
  - mcp__claude_ai_Linear__get_issue
  - mcp__claude_ai_Linear__save_issue
  - mcp__claude_ai_Linear__save_comment
  - mcp__claude_ai_Linear__list_issues
capability-class: execution-orchestration
tier: I
domain: [dt]
works-with:
  requires-context: [dt-pipeline-stages, dt-artifact-schemas, dt-schemas-planning, dt-schemas-build, dt-hitl-protocol, dt-definition-of-done, dt-github-practices, dt-integration-map]
  upstream-skills: [dt-start, dt-gate-review]
  downstream-skills: [dt-close, dt-gate-review]
  compatible-agents: [dt-frontend-dev, dt-backend-dev, dt-middleware-dev, dt-qa-tester]
readiness:
  state: green
  idempotent: false
  warm-start: true
cost:
  model-class: high
  agent-count: 4
  web-calls: none
  context-budget: xlarge
---

# Sprint Run

Read context files:
- `~/.claude/commands/context/dt-pipeline-stages.md`
- `~/.claude/commands/context/dt-artifact-schemas.md`
- `~/.claude/commands/context/dt-schemas-planning.md`
- `~/.claude/commands/context/dt-schemas-build.md`
- `~/.claude/commands/context/dt-hitl-protocol.md`
- `~/.claude/commands/context/dt-definition-of-done.md`
- `~/.claude/commands/context/dt-github-practices.md`
- `~/.claude/commands/context/dt-integration-map.md`
- `~/.claude/commands/context/dt-pre-dispatch-supplementation.md` (path-commitment AC + subagent lacks named MCP)
- `~/.claude/commands/context/dt-tool-gap-recovery.md` (subagent triangulated; orchestrator has live access)

## Purpose

Execute the Implementation phase (Stage 4). This is the most complex skill in the delivery-team suite. It orchestrates story-by-story execution using parallel dev agents in worktrees, runs QA gates per story, manages blockers and escalations, and keeps sprint state synchronized in `sprint-status.yaml` and Linear.

## Input

`$ARGUMENTS` = "all" to run the full sprint, or a specific story ID to execute a single story.

Default: "all".

## Prerequisites

- `project-kickoff.md` — project context (stack, conventions, HITL level)
- `sprint-status.yaml` — sprint state with stories
- `sprint-plan.md` — execution plan with dependency order
- `dependency-map.md` — story dependency graph
- `story-{id}.md` — individual story files with ACs
- `.codebase-index/` — codebase context for dev agents

See `dt-artifact-schemas.md` § Effort Resolution. Resolve effort before locating prerequisites. Read all prerequisites at startup. If any are missing, report which are absent and exit.

## Orchestration Loop

The sprint run operates as a loop. Each iteration:
1. Read current sprint state from `sprint-status.yaml`
2. Identify stories ready for execution (dependencies met, not blocked)
3. Activate dev agents for ready stories (parallel where possible)
4. Wait for agent completion
5. Run QA gate per completed story
6. Update sprint state
7. Check for blockers and escalations
8. Repeat until all stories are done, blocked, or sprint time expires

### Story Lifecycle Within Sprint Run

```
drafted → ready-for-dev → in-progress → review → validating → done
                                                       ↓
                                                   (if FAIL)
                                                   in-progress (rework)
```

## Phase 1: Sprint Initialization

### Step 1: Load Sprint Context

Read `sprint-status.yaml`, `sprint-plan.md`, `dependency-map.md`, and `project-kickoff.md`.

Extract:
- HITL level
- Sprint length and days remaining
- Story execution order from dependency map
- Agent assignments per story
- Stories already completed (if resuming a partially-complete sprint)

### Step 2: Identify Ready Stories

A story is "ready" when:
- Status is `drafted` or `ready-for-dev`
- All entries in its `blocked-by` list have status = `done`
- No active `design-veto.md` blocks it

Group ready stories by parallelization potential (from `sprint-plan.md`).

### Step 3: HITL Checkpoint — Sprint Start

Check HITL level:
- **Level 1**: Present the execution plan. For each story, show: title, assigned agent, dependencies, estimated points. Ask: "Approve this execution plan? Or modify story order/assignments?"
- **Level 2-4**: Auto-proceed. Display execution plan for awareness.

## Phase 2: Story Execution (Loop)

For each batch of parallelizable stories:

### Step 0: Prepare Feature Branches

For each story in the batch, before launching the dev agent:
1. `git fetch origin main`
2. Create feature branch from `origin/main` using the naming pattern from `context/dt-github-practices.md` (default: `{type}/{story-id}-{slug}`)
3. If the project uses Linear integration, prefer Linear's `gitBranchName` for auto-linking
4. Create the worktree on this branch

### Worktree Hook Safety

If the project uses a post-commit hook (for example, one that syncs artifacts to an external docs store), apply this bypass **before launching dev agents in worktrees that branch from `origin/main` while the user has uncommitted state on the primary tree**. Multiple worktrees committing in parallel would race on the hook and write partial state.

1. Per worktree, run: `git config core.hooksPath /dev/null` — this disables the post-commit hook for that worktree only; the primary tree's hook still runs on post-merge commits to `main`, so canonical syncing is preserved.
2. **After sprint close**: remove the worktree OR reset `core.hooksPath` so the primary hook is the live protection. Worktree removal makes the revert moot.

### Step 1: Activate Dev Agents (Parallel)

For each story in the batch, launch a dev agent in its own worktree:

**Frontend stories**: Launch `~/.claude/commands/agents/dt-frontend-dev.md` subagent (model: sonnet) to implement the story. Provide: `story-{id}.md`, `design-spec.md`, `api-contract.yaml` (if exists), `.codebase-index/components.md`, `.codebase-index/api-surface.md`, `project-kickoff.md` (conventions). The agent must produce `ready-for-review.md` (with branch name and PR URL) when complete. The agent should return only a 3-5 line summary to the caller; full details go into `ready-for-review.md`.

**Backend stories**: Launch `~/.claude/commands/agents/dt-backend-dev.md` subagent (model: sonnet) to implement the story. Provide: `story-{id}.md`, `api-contract.yaml`, `.codebase-index/api-surface.md`, `.codebase-index/data-model.md`, `project-kickoff.md`. The agent must produce `ready-for-review.md` when complete. The agent should return only a 3-5 line summary to the caller; full details go into `ready-for-review.md`.

**Middleware stories**: Launch `~/.claude/commands/agents/dt-middleware-dev.md` subagent (model: sonnet) to implement the story. Provide: `story-{id}.md`, `api-contract.yaml`, `.codebase-index/dependencies.md`, `.codebase-index/api-surface.md`, `project-kickoff.md`. The agent must produce `ready-for-review.md` when complete. The agent should return only a 3-5 line summary to the caller; full details go into `ready-for-review.md`.

**Multi-agent stories** (requiring both FE and BE): Launch both agents. Backend produces `api-contract.yaml` first; frontend consumes it. Coordinate via the contract file — not via conversation.

### Step 2: Update Sprint State

After launching agents, update `sprint-status.yaml`:
- Set story status to `in-progress`
- Set `started` date
- Sync to Linear (update issue status)

### Step 3: Monitor Agent Completion

As each agent completes:
1. Read its `ready-for-review.md` output
2. Update story status to `review`
3. Proceed to simplify pass (if enabled) or QA gate

### Step 3.5: Simplify Pass (Optional)

Check `project-kickoff.md` for `simplify-before-qa`. If `false` or absent, skip to Step 4.

If enabled, for each story in `review` status:
1. In the story's worktree, run `/simplify` — this launches 3 parallel review agents (reuse, quality, efficiency) against the dev agent's diff and fixes issues directly
2. If `/simplify` made changes, the dev agent's branch is updated in place — no separate commit needed beyond what `/simplify` produces
3. Proceed to QA gate

This pass catches codebase reuse opportunities dev agents miss (existing utilities, duplicate logic) and cleans up quality drift (parameter sprawl, redundant state, copy-paste) before QA sees the code. The goal is fewer QA FAIL verdicts and rework cycles.

### Step 4: QA Gate Per Story

For each story in `review` status, launch `~/.claude/commands/agents/dt-qa-tester.md` subagent (model: sonnet) to perform a full quality review. Provide:
- `story-{id}.md` (acceptance criteria)
- `ready-for-review.md` (dev agent's implementation summary)
- The implementation code (QA reads the codebase directly)
- `design-spec.md` (if exists — for visual/interaction verification)
- `api-contract.yaml` (if exists — for contract compliance)
- `.codebase-index/test-map.md` (for coverage context)
- `project-kickoff.md` (conventions and DoD)

QA produces `qa-gate.md` for the story with verdict: PASS, WARN, or FAIL. The QA agent should write the full `qa-gate.md` to disk and return only a 3-5 line summary (story-id, verdict, blocking count) to the caller.

### Step 5: Process QA Result

**PASS**:
1. Merge the PR (squash-and-merge default per `context/dt-github-practices.md`)
2. Verify merge completed successfully
3. Delete the remote feature branch
4. Remove the worktree
5. Update story status to `done`, gate-status to `pass`. Set `completed` date. Sync to Linear.
6. Check if any in-progress stories need rebasing onto updated main. If conflicts detected, add to blocker list.

**WARN**:
1. Merge the PR, delete branch, remove worktree (same as PASS)
2. Update story status to `done`, gate-status to `pass`. Log advisory findings. Proceed.
3. Check for rebase needs on in-progress stories.

**FAIL**:
1. Update story status to `in-progress` (rework cycle)
2. Check failure type:
   - **Blocking QA failure**: This is an auto-escalation trigger at all HITL levels
   - Write `HITL-needed.md` with QA findings and rework guidance
   - Use `AskUserQuestion`: "QA gate FAIL on {story-id}: {failure summary}. Rework automatically, or provide guidance?"
3. If user approves rework: re-activate the dev agent with QA findings as additional context
4. If user provides guidance: incorporate into rework instructions
5. After rework: re-run QA gate (max 2 rework cycles per story, then hard escalate)

### Step 6: Update Sprint Memory

After each QA gate (pass or fail), append to `.claude/agent-memory/qa-tester/MEMORY.md`:
- Story ID, verdict, key findings
- Any new patterns or recurring issues

## Phase 3: Blocker Detection

After each execution cycle, check for auto-escalation conditions:

1. **QA blocking failure**: Already handled in Step 5 above
2. **Design veto**: Check for `design-veto.md` → escalate, halt affected stories
3. **Scope change**: If a story's ACs have been modified since sprint start → escalate
4. **External dependency**: If a story is blocked on something outside the sprint → write `HITL-needed.md`

For each escalation:
- Write `HITL-needed.md` with context, options, and recommendation
- Update `sprint-status.yaml`
- Use `AskUserQuestion` to present the escalation

## Phase 4: Sprint Completion Check

After all stories in the current batch are processed:

### Step 1: Check Sprint State

Read `sprint-status.yaml`:
- **All stories done**: Sprint execution complete. Report success.
- **Stories remaining with dependencies met**: Loop back to Phase 2 with the next batch.
- **Stories remaining but blocked**: Report blocked stories and their blockers.
- **Sprint time expired**: Report incomplete stories and recommend next action.

### Step 2: Linear Sync

Update all Linear issues to match `sprint-status.yaml` status.

### Step 3: Final Report

Display execution summary:
```
## Sprint Run Summary
Stories completed: {N}/{total}
QA pass rate: {N}%
Rework cycles: {N}
Blockers encountered: {N}
Time elapsed: {N} days

### Completed Stories
{table of completed stories with QA verdicts}

### Remaining Work
{table of incomplete/blocked stories with status and blocker info}
```

## HITL Checkpoints Summary

| HITL Level | Per-Story Approval | QA Failure | Auto-Escalation |
|------------|-------------------|------------|-----------------|
| 1 | Yes — approve each story before dev starts | Always escalate | All conditions |
| 2 | No | Always escalate | All conditions |
| 3 | No | Always escalate | All conditions |
| 4 | No | Always escalate | All conditions |

Auto-escalation is never disabled. Even at Level 4, certain conditions require human intervention.

## Persistence

All sprint artifacts are written to `sprints/{effort}/sprint-{N}/` within the project working directory:
- `sprint-status.yaml` — updated continuously throughout execution
- `qa-gate.md` — one per completed story
- `HITL-needed.md` — written on escalation
- `blocker.md` — written on blocker detection
- Sprint memory files updated per QA gate
- Linear synced at each story state transition

## Pre-Dispatch Live-Evidence Supplementation

Proactive pattern: when a dispatched subagent's path-commitment AC needs live MCP evidence it cannot reach, the orchestrator runs MCP calls **before** dispatch and embeds results inline. First line of defense; recovery below is the second.

See `delivery-team/context/dt-pre-dispatch-supplementation.md` — When to apply, Procedure, composition with recovery, and the Path B design rationale + revisit clause.

## Tool-Gap Recovery Pattern

Reactive recovery shape: when a dispatched subagent commits under documentary triangulation (per an AC escape-hatch) because it lacks an MCP tool the orchestrator does have, the orchestrator runs live evidence post-hoc and dispatches a focused pivot rework. Both commits remain in PR history.

See `delivery-team/context/dt-tool-gap-recovery.md` — When to apply, Mechanics (4-step procedure), and the path-c → path-a worked example. When the trigger fires (subagent triangulated; orchestrator has live access; evidence diverges), follow the procedure rather than re-deriving it.

This recovery shape composes with the canonical two-stage operator-artifact gate — see `delivery-team/context/dt-definition-of-done.md` § Operator-Artifact ACs § Recovery Shapes for how the recovery mechanism produces the Mid-flight pivot outcome shape in the gate framework.

## Chaining

After sprint run completes:
> Sprint execution {complete/partial}. {N}/{total} stories done.
> - `/sprint-status` — view full sprint state
> - `/sprint-close` — close sprint and produce summary (if all stories done)
> - `/gate-review 4` — adversarial review before cross-functional readiness
> - `/sprint-blocker {story-id}` — register a blocker (if stories are stuck)
