---
description: Release a converged or metastable variant. Promote to working tree, progressive rollout via flags, audience-tiered comms derived from spec delta, post-ship eval monitoring.
argument-hint: <variant-id> | --metastable | --rollback <ship-id>
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
capability-class: deploy
tier: I
domain: [flow]
works-with:
  requires-context: [flow-state-model, flow-philosophy, flow-spec-protocol, vault-access]
  upstream-skills: [flow-converge, flow-chavruta]
  downstream-skills: []
  compatible-agents: [flow-orchestrator, flow-narrator, flow-evaluator]
readiness:
  state: green
  idempotent: false
  warm-start: false
cost:
  model-class: high
  agent-count: 3
  web-calls: none
  context-budget: large
---

# Flow Ship

Read context files:
- `~/.claude/commands/context/flow-state-model.md`
- `~/.claude/commands/context/flow-philosophy.md`
- `~/.claude/commands/context/flow-spec-protocol.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Release a variant to production. Replaces five delivery-team skills (`dt-release-plan`, `dt-readiness-gate`, `dt-release`, `dt-release-comms`, `dt-release-monitor`) with a single consolidated ship operation. Comms are derived continuously from spec deltas (no readiness handoff stage); progressive rollout uses feature flags; post-ship eval continues running.

## Inputs

- **variant-id** — required, the variant to ship (typically chosen by `/flow-converge`)
- `--metastable` — explicitly ship as metastable / partial-completion release with deferred SRs disclosed
- `--rollback <ship-id>` — revert a prior ship; restore working tree and feature-flag state to pre-ship

## Procedure

### Step 1: Read state

- `flow-state.yaml`
- `generations/gen-{N}/population/{variant-id}/` — the variant + eval-result
- `dissents-active.yaml` — any blocking dissents?
- `spec/spec.md` and `spec/history/spec-v{N}.md` — current spec for narrator projection
- `spec/constitution.md` — release prohibitions, ring policy if defined

### Step 2: Pre-ship validation

- Variant exists and has a recent eval-result
- No blocking dissents (those flagged as blocking by chavruta must be acknowledged/mitigated/resolved first)
- Invariants pass on this variant
- Convergence-score meets ship threshold (or metastable flag set)
- HITL `preference-articulator` mode requires explicit user approval

If any check fails: halt and surface the gap.

### Step 3: Generate ship-record-id

Format: `ship-{YYYY-MM-DD}-{NNNN}` where NNNN is ordinal for the day.

Create `efforts/{effort}/shipped/{ship-record-id}/` directory.

### Step 4: Promote variant to working tree

The variant's `implementation/` directory contents are merged into the project's working tree.

**This is the canonical write operation in flow.** Per P1 (intelligence parallel, writes serial), this is where serialization happens — exactly one variant is promoted at a time.

Operationally:
1. Compute file-by-file diff between variant and current working tree
2. Apply changes via `Edit` or `Write` (not raw copy — preserves git-tracked metadata)
3. Verify checksum / re-read to confirm
4. **Do not commit yet** — the user (or downstream CI) commits

### Step 5: Generate comms artifacts

Launch `~/.claude/commands/agents/flow-narrator.md` subagent (model: opus) with:
- Spec version being shipped
- Ship-record-id
- Variant context (constraint-bias, eval-result)

Narrator writes to `efforts/{effort}/shipped/{ship-record-id}/comms/`:
- `changelog.md`
- `internal-changelog.md`
- `sponsor-comms-{customer}.md` (one per sponsor in constitution)
- `GA-comms.md`
- `sales-brief.md`
- `support-doc.md`
- `marketing-brief.md`

### Step 6: Progressive rollout plan

Read effort's `release-rings` from constitution (or use defaults):

```yaml
rings:
  - name: ring-0-internal
    audience: dogfood
    flag-coverage: 100%
    dwell-time-min: 15
    eval-tier: 1
  - name: ring-1-beta
    audience: sponsors-UAT
    flag-coverage: 5%
    dwell-time-min: 60
    eval-tier: 2
  - name: ring-2-early
    audience: opt-in
    flag-coverage: 25%
    dwell-time-min: 240
    eval-tier: 2
  - name: ring-3-ga
    audience: all
    flag-coverage: 100%
    dwell-time-min: continuous
    eval-tier: 3
```

Write `efforts/{effort}/shipped/{ship-record-id}/rollout-plan.yaml` with the plan.

**HITL gate at each ring transition** — the user explicitly advances rings. `flow-ship` does not auto-advance through rings; it produces the plan and ships ring-0.

### Step 7: Feature flag wiring

If the project uses feature flags, write a `feature-flags.yaml` snippet referencing the new flag(s). The actual flag platform integration is project-specific; the artifact is generated as documentation.

### Step 8: Post-ship eval

Continuous eval continues running. Configure in `efforts/{effort}/shipped/{ship-record-id}/post-ship-eval/`:
- Same eval suite as pre-ship
- Production data feeds in (instrumented via constitution-defined integration)
- Anomaly threshold: if any dimension regresses by >0.10 from pre-ship score, surface as alert

This skill produces the configuration; the running of post-ship eval is the project's CI/CD or `flow-orchestrator` cron.

### Step 9: Write ship record

```markdown
# Ship Record — {ship-record-id}

**Date**: {ISO8601}
**Effort**: {effort-slug}
**Variant**: gen-{N}/population/{variant-id}
**Constraint bias**: {bias}
**Spec version**: v{spec-version}
**Ship kind**: full | metastable
**Convergence-score at ship**: {score}
**HITL approval**: {user, timestamp}

## Pareto-front scores at ship

| Dimension | Score |
|-----------|-------|
| correctness | 0.94 |
| performance | 0.81 |
| maintainability | 0.78 |
| accessibility | 1.00 |
| security | 0.92 |
| cost | 0.55 |

## SRs covered

- SR-001 through SR-019: passing
- SR-020: deferred (metastable) — covered in next effort
- ...

## Active dissents at ship time

- dissent-2026-05-13-0001 (acknowledged; inline retry vs middleware)
  - Reactivation conditions remain armed in post-ship monitoring

## Rollout plan

Ring 0: ships immediately. Ring 1+ requires explicit advance.

## Rollback path

If post-ship eval regression detected:
- Run `/flow-ship --rollback {ship-record-id}`
- Working tree reverts to pre-ship state
- Feature flags disabled
- Post-ship monitoring continues for forensic data

## Comms artifacts

Generated in: `comms/` subdirectory.
```

### Step 10: Update state

Write to `flow-state.yaml`:
- `status`: `converged` if full ship; `in-flight` continues if metastable
- `phase-log`: append ship record
- `shipped` count incremented

### Step 11: Linear / external mirror (if configured)

If constitution declares external system mirror:
- Linear: update relevant issues, post comment with ship-record-id
- GitHub: create release with changelog
- Slack: post sponsor-comms (per audience)

These are constitution-configurable. By default, none happen automatically — the user mirrors manually using the generated comms artifacts.

### Step 12: Report

Return:
- Ship-record-id
- Variant shipped
- Spec version
- Pareto-front summary
- Comms artifacts (paths)
- Rollout plan summary
- Active dissents at ship (with status)
- Next-step suggestion: advance ring | monitor post-ship eval | start next effort

## Rollback mode

`--rollback <ship-id>`:

1. Read ship record
2. Compute reverse diff (current working tree → pre-ship state)
3. Apply reverse diff via Edit/Write
4. Update feature flags (disable)
5. Write rollback record to `efforts/{effort}/shipped/{ship-id}/rollback-{timestamp}.md`
6. Surface in phase-log
7. Optional: generate rollback comms via narrator (separate audience tiering)

Rollback is **always** HITL preference-articulator mode regardless of effort default.

## What this skill does NOT do

- **It does not commit to git.** The user (or downstream automation) commits.
- **It does not deploy.** This is project-CI/CD's job. `flow-ship` produces the artifacts and rollout plan; deployment is initiated separately.
- **It does not auto-advance rings.** Each ring transition is explicit.
- **It does not modify the spec.** Spec is already committed in `spec/`.

## Outputs

| Path | Action |
|------|--------|
| Working tree | Variant promoted (file-by-file Edit/Write) |
| `efforts/{effort}/shipped/{ship-id}/ship-record.md` | Ship record |
| `efforts/{effort}/shipped/{ship-id}/rollout-plan.yaml` | Rollout plan |
| `efforts/{effort}/shipped/{ship-id}/comms/*` | Audience-tiered comms |
| `efforts/{effort}/shipped/{ship-id}/post-ship-eval/` | Post-ship eval config |
| `efforts/{effort}/flow-state.yaml` | Status + phase-log updated |

## HITL surface

- Always preference-articulator on ship (production deployment is **always** human-initiated per the philosophy carried over from delivery-team)
- Metastable ship: confirm deferred SRs disclosure
- Active dissent blocking ship: prompt to resolve first or override-with-rationale
- Rollback: full ship record displayed + confirmation

## Failure modes

- Pre-ship validation fails: halt; surface gaps; suggest remediation
- Working tree dirty (uncommitted changes from non-flow sources): halt; surface; offer to stash or merge resolution
- Comms generation fails: complete ship with placeholder comms + flag; user can re-run narrator
- Rollback target ship-id not found: halt; list available ship records

## Idempotency

Not idempotent — re-running a ship creates a new ship-record-id with new timestamps. To re-ship the same variant, the ship-record IS the audit trail of the prior attempt.

## Examples

### Standard ship after convergence

```
/flow-ship var-2
```

After `/flow-converge` recommended var-2 (Pareto-front winner). HITL approval. Variant promoted. Comms generated. Rollout plan: ring 0 ships now, ring 1 awaits explicit advance.

### Metastable ship with deferred SRs

```
/flow-ship var-3 --metastable
```

Stability is high, spec proximity is partial. HITL confirms which SRs are deferred. Variant ships as feature-flagged early access; remaining SRs continue in future generations.

### Rollback

```
/flow-ship --rollback ship-2026-05-13-0001
```

Reverses the prior ship. Working tree restored. Rollback comms generated. Post-ship monitoring continues for forensic data.
