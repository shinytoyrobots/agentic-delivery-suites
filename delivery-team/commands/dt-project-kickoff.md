---
description: Initialize a new delivery project — gather stack, conventions, HITL level, launch tier, and produce shared context artifact
argument-hint: <project description or spec/PRD path>
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
  - mcp__claude_ai_Linear__list_teams
  - mcp__claude_ai_Linear__list_projects
  - mcp__claude_ai_Linear__save_project
capability-class: planning-design
tier: II
domain: [dt]
works-with:
  requires-context: [dt-pipeline-stages, dt-artifact-schemas, dt-schemas-planning, dt-hitl-protocol, dt-definition-of-done, dt-github-practices, vault-access]
  upstream-skills: []
  downstream-skills: [dt-start, dt-codebase-index]
  compatible-agents: [dt-codebase-indexer, dt-marketing]
readiness:
  state: green
  idempotent: false
  warm-start: false
cost:
  model-class: high
  agent-count: 2
  web-calls: none
  context-budget: medium
---

# Project Kickoff

Read context files:
- `~/.claude/commands/context/dt-pipeline-stages.md`
- `~/.claude/commands/context/dt-artifact-schemas.md`
- `~/.claude/commands/context/dt-schemas-planning.md`
- `~/.claude/commands/context/dt-hitl-protocol.md`
- `~/.claude/commands/context/dt-definition-of-done.md`
- `~/.claude/commands/context/dt-github-practices.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Initialize a new delivery project. This is always the first skill invoked for a new feature or project. It produces `project-kickoff.md` — the shared context artifact that every agent in the delivery-team reads as their first action. No other delivery-team skill should be run before this one.

## Input

`$ARGUMENTS` = project description, feature name, or path to a spec/PRD document.

If `$ARGUMENTS` is empty, use `AskUserQuestion` to gather a project description before proceeding.

## Phase 1: Interactive Setup

Use `AskUserQuestion` to gather the following. Ask one batch at a time — do not dump all questions at once.

### Batch 1: Project Identity
1. **Project description** — Confirm/refine from $ARGUMENTS. "What are we building and why?"
2. **Effort name** — "What should I call this effort? This is used to namespace sprints so multiple efforts can coexist in the same repo. Provide a short kebab-case slug (e.g., 'auth-overhaul', 'billing-v2'), or say 'auto' to derive from the current branch name."
   - If "auto" or empty: run `git branch --show-current`, slugify (lowercase, replace `/` and spaces with `-`), and propose the result for confirmation.
3. **Spec/PRD location** — "Where is the spec or PRD? Provide a file path, URL, or Notion page. Or say 'none' if starting from scratch."
4. **Target users** — "Who are the target users for this feature?"

### Batch 2: Technical Context
4. **Stack confirmation** — Read any existing `CLAUDE.md`, `package.json`, `pyproject.toml`, or framework config in the current directory. Present what was detected and ask: "Is this correct? Any additions or corrections?"
5. **Repository location** — "What repo(s) will this project touch? Confirm the current directory is correct, or provide path(s)." Also detect the GitHub org from the remote URL and confirm.
6. **GitHub workflow** — Present defaults from `context/dt-github-practices.md` and ask: "I'll use these GitHub defaults — any changes?" Show: branch naming pattern, conventional commits, squash-and-merge, 150-line PR target. Also check: does `.gitignore` exist and cover the detected stack? Does the main branch have protection rules?
7. **Conventions** — "Any other project-specific conventions I should know? (naming, deployment targets, etc.)"

### Batch 3: Process Calibration
7. **HITL calibration level** — Present the four levels with one-line descriptions:
   - Level 1: Full oversight — approve at every phase gate and every story
   - Level 2: Phase gates — approve at major transitions, autonomous within phases
   - Level 3: QA gate only — autonomous except QA/readiness sign-off
   - Level 4: Autonomous — full auto with auto-escalation safety net
   "Which level? (1-4)"
8. **Launch tier** — "Is this a Tier 1 (major launch), Tier 2 (notable feature), or Tier 3 (incremental improvement)? Say 'auto' to let Marketing Agent propose."
9. **Simplify before QA** — "Run a /simplify cleanup pass on dev output before QA gate? This catches reuse opportunities and quality drift but adds ~3 agent calls per story. (default: false)"

## Phase 2: Parallel Agent Work

Launch two agents in parallel:

### Agent A: Codebase Indexer
Launch `~/.claude/commands/agents/dt-codebase-indexer.md` subagent (model: haiku) to index the target repository. The indexer produces `.codebase-index/` with `index.md`, `architecture.md`, `api-surface.md`, `data-model.md`, `components.md`, `dependencies.md`, `test-map.md`, and `config.md`.

### Agent B: Launch Tier Proposal (if tier = 'auto')
Launch `~/.claude/commands/agents/dt-marketing.md` subagent (model: haiku) to assess the project description and propose a launch tier with rationale. Write output to `sprints/{effort}/sprint-{N}/launch-tier.md`.

## Phase 2.5: Architecture Foundation (Greenfield Only)

After the codebase indexer completes, determine if the project is greenfield:
- `.codebase-index/architecture.md` is missing or contains only stub content (e.g. < 30 lines), AND
- The repo's git history shows fewer than 10 commits, OR the repo is freshly initialized

If **greenfield AND a spec/PRD path was provided** (either as `$ARGUMENTS` or in the kickoff intake), auto-invoke `~/.claude/commands/agents/dt-architect.md` subagent (model: sonnet) to produce a foundational architecture proposal. Provide it the spec/PRD, the partial codebase index, and the team-shape signals captured in intake (Q3-Q5: team count, HITL level, conventions). Capture stdout to `sprints/{effort}/sprint-{N}/architecture-proposal.md`.

Then auto-invoke `/dt-architect-review` against the produced file. If the review verdict is `BLOCKING REVISIONS`, surface the findings to the user via `AskUserQuestion`: "The initial architecture proposal has blocking findings. Re-run dt-architect, edit manually, or proceed anyway?"

If **brownfield OR no spec/PRD provided**, skip this phase. Note in the kickoff intake that architecture-proposal.md was deferred.

## Phase 3: Produce project-kickoff.md

Synthesize all gathered information into `project-kickoff.md` (target: 100-150 lines). Write it to `sprints/{effort}/sprint-{N}/`. Create `sprints/`, `sprints/{effort}/`, and `sprints/{effort}/sprint-{N}/` if they do not exist, and add `sprints/` to the project's `.gitignore` if not already present.

Before writing `project-kickoff.md`, register this effort in `sprints/efforts.yaml` (create the file if it does not exist). See `context/dt-artifact-schemas.md` for the efforts.yaml schema. Set `active: true` and populate the `branches` list from `git branch --show-current`.

### project-kickoff.md Structure

```markdown
# Project Kickoff: {Project Name}
**Generated**: {YYYY-MM-DD HH:MM}
**Skill**: /project-kickoff
---

## Project Overview
- **Effort**: {effort-slug}
- **Description**: {1-3 sentences}
- **Target users**: {user segments}
- **Spec/PRD**: {location or "none — building from description"}
- **Launch tier**: {1/2/3 + rationale}

## Technical Context
- **Stack**: {detected + confirmed stack}
- **Repository**: {path(s)}
- **GitHub org**: {detected or confirmed org}
- **Key conventions**: {bullets}

## GitHub Workflow
{Defaults from context/dt-github-practices.md, with any user overrides applied}
- **Branch naming**: {type}/{story-id}-{slug}
- **Commit format**: conventional commits
- **Merge strategy**: squash
- **PR size target**: 150 lines
- **Main branch**: {main or detected default branch}
- **CI**: {GitHub Actions or detected CI system}
- **.gitignore**: {verified | missing — flag for setup}

## Process Configuration
- **HITL level**: {1-4} — {level name}
- **Simplify before QA**: {true|false} — run /simplify cleanup pass on dev output before QA gate
- **Auto-escalation triggers**: qa-gate blocking failure, design-veto, scope change, spec ambiguity, unresolved external dependency

## Codebase Summary
{Brief summary from .codebase-index/index.md — architecture style, key modules, test coverage baseline}

## Definition of Done
{Project-specific DoD, starting from context/dt-definition-of-done.md defaults, adjusted per user conventions}

## Agent Activation Plan
{Which agents are expected for this project: always FE+QA? BE+Middleware? Designer needed?}

## Open Questions
{Any unresolved items from the setup conversation}
```

## HITL Checkpoints

This skill is always interactive — the entire purpose is to gather user input. No HITL level bypasses the interactive setup.

## Persistence

- Register effort in `sprints/efforts.yaml` (create if it does not exist)
- Create `sprints/{effort}/sprint-{N}/` directory tree if it does not exist
- Add `sprints/` to the project's `.gitignore` if not already present
- Write `project-kickoff.md` to `sprints/{effort}/sprint-{N}/`
- Write `launch-tier.md` to `sprints/{effort}/sprint-{N}/` (if Marketing Agent produced one)
- Write sprint summary data to `docs/Delivery-Team/{date}/` after sprint completion (downstream — not this skill's responsibility)

## Chaining

After kickoff is complete, tell the user:

> Project initialized. Run `/sprint-start` to begin Discovery + Planning, or `/codebase-index` to re-index if the codebase changes.
