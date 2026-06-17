---
description: Run the codebase indexer to produce or refresh structured context files
argument-hint: "[repository path — defaults to current directory]"
model: sonnet
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - Agent
capability-class: meta-orchestration
tier: III
domain: [dt]
works-with:
  requires-context: [vault-access]
  upstream-skills: [dt-project-kickoff]
  downstream-skills: [dt-run, dt-start, dt-gate-review]
  compatible-agents: [dt-codebase-indexer]
readiness:
  state: green
  idempotent: true
  warm-start: false
cost:
  model-class: low
  agent-count: 1
  web-calls: none
  context-budget: medium
---

# Codebase Index

Read context files:
- `~/.claude/commands/context/vault-access.md`

## Purpose

Thin wrapper that invokes the codebase-indexer agent to produce structured context files consumed by all delivery-team agents. Run this at project kickoff and whenever the codebase has changed significantly.

## Input

`$ARGUMENTS` = repository path (default: current working directory).

## Process

### Step 1: Staleness Check

Check if `.codebase-index/.last-indexed` exists in the target directory:
- If it exists, read it and compare the stored git commit hash against `git rev-parse HEAD`
- If hashes match, report "Codebase index is current (indexed at {hash}). Use `--force` to re-index." and exit
- If `$ARGUMENTS` contains `--force`, skip the staleness check and re-index

### Step 2: Invoke Codebase Indexer

Launch `~/.claude/commands/agents/dt-codebase-indexer.md` subagent (model: haiku) to index the repository at the target path. The agent should produce the full `.codebase-index/` family of files:
- `index.md` — high-level codebase overview
- `architecture.md` — architectural patterns and module organization
- `api-surface.md` — public APIs, endpoints, exported functions
- `data-model.md` — database schemas, data structures
- `components.md` — UI component inventory (if applicable)
- `dependencies.md` — dependency graph and external packages
- `test-map.md` — test coverage map and test file locations
- `config.md` — configuration files and environment variables
- `.last-indexed` — git commit hash and timestamp

### Step 3: Report

After the indexer completes, read `.codebase-index/index.md` and display a brief summary:
```
Codebase indexed at {git hash}.
- {N} source files analyzed
- Architecture: {style}
- Key modules: {list}
- Test coverage: {summary}
```

## HITL Checkpoints

None — this is an infrastructure skill with no decision points.

## Persistence

All output goes to `.codebase-index/` in the target repository directory. This is not persisted to the vault — it is project-local.
