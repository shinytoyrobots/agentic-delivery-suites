---
description: Release a variant through the ship gate — named qualitative grounds, deep eval pass, ledger audit, a FIRED revert probe, and pre-registered watches. Promote to working tree, progressive rollout via flags, changelog + ship record derived from spec delta.
argument-hint: <variant-id> | --gated (alias --metastable) | --rollback <ship-id>
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
  requires-context: [flow-state-model, flow-philosophy, flow-spec-protocol, flow-operating-doctrine, flow-operator-voice, vault-access]
  upstream-skills: [flow-cull, flow-chavruta]
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
- `~/.claude/commands/context/flow-operating-doctrine.md`
- `~/.claude/commands/context/flow-operator-voice.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Release a variant to production. This skill **owns the ship gate** (doctrine §Ship gate): the decision to ship is made here, on named qualitative grounds with compensating controls — never on a scalar. There is no upstream convergence check; the cull close hands the decision straight to this gate. Comms are slim by default (changelog + ship record); progressive rollout uses feature flags; pre-registered watches monitor post-ship.

Ship kinds are **clean** (full in-scope coverage) or **gated** (partial coverage or waived checks, behind flags, deferred SRs disclosed, watches armed).

## Inputs

- **variant-id** — required, the variant to ship (the survivor surfaced at `/flow-cull`'s close)
- `--gated` (alias: `--metastable`) — explicitly ship as a gated / partial-completion release with deferred SRs disclosed
- `--rollback <ship-id>` — revert a prior ship; restore working tree and feature-flag state to pre-ship

## Procedure

### Step 1: Read state

- `flow-state.yaml`
- `generations/gen-{N}/population/{variant-id}/` — the variant + eval-result
- `dissents-active.yaml` — any blocking dissents?
- `spec/spec.md` and `spec/history/spec-v{N}.md` — current spec for narrator projection
- `spec/constitution.md` — release prohibitions, ring policy if defined

### Step 2: The ship gate

A ship is justified by this checklist, not a score (doctrine §Ship gate — the compensating controls that replaced the retired convergence criterion):

1. **Named qualitative grounds** — what this variant does that the alternatives don't, in behavior terms. Written before anything else; goes verbatim into the ship record. "Highest weighted scalar" is not grounds.
2. **Invariants pass** on this variant.
3. **No blocking dissents** — those flagged blocking by chavruta must be acknowledged/mitigated/resolved first.
4. **Chavruta has run since the last cull.** If not, run `/flow-chavruta` now — the paired adversarial review is the checkpoint.
5. **One deep eval pass** on this variant — the single deep run the eval tiering budget allows (rounds run quick; this is where deep lives).
6. **Decision-ledger audit complete** — suite-gap findings addressed via `/flow-eval` or explicitly accepted with rationale.
7. **A FIRED revert probe** — compute the reverse diff and apply it cleanly somewhere disposable (scratch worktree). A rollback path that has never fired is an assumption, not a control.
8. **Pre-registered post-ship watches** — the specific regressions and dissent reactivation conditions that would trigger action, written into the ship record before promotion.
9. **HITL approval** — always preference-articulator for ship.

Gated ships additionally disclose exactly which SRs are deferred. If any check fails: halt and surface the gap.

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

### Step 5: Generate comms artifacts (slim by default)

Launch `~/.claude/commands/agents/flow-narrator.md` subagent (model: opus) with:
- Spec version being shipped
- Ship-record-id
- Variant context (constraint-bias, eval-result)

Narrator writes to `efforts/{effort}/shipped/{ship-record-id}/comms/`:
- `changelog.md`
- `internal-changelog.md` (doubles as the human-readable ship narrative)

That is the default bundle — the field trial produced eight full comms bundles with zero inbound references. The wider tiers (sponsor comms, GA comms, sales brief, support doc, marketing brief) are generated **only on explicit operator request**, per audience, never automatically.

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

### Step 8: Arm the post-ship watches

Write the pre-registered watches (gate item 8) to `efforts/{effort}/shipped/{ship-record-id}/post-ship-eval/watches.yaml`:
- Each watch: the specific regression or condition, how it is observed, and what firing triggers (rollback, ruling, remedy PR, or narrow redispatch)
- Dissent reactivation conditions in scope stay armed alongside
- Anomaly default: any dimension regressing >0.10 from the pre-ship deep pass surfaces as an alert

This skill produces the configuration; observing the watches is the project's CI/CD, `flow-dissent-monitor`, or the operator. **A fired watch is the doctrine's licensed trigger for a new generation** — post-ship work is otherwise spec-side and probe-side (rulings, remedy PRs, probes), zero new generations by default.

### Step 9: Write ship record

```markdown
# Ship Record — {ship-record-id}

**Date**: {ISO8601}
**Effort**: {effort-slug}
**Variant**: gen-{N}/population/{variant-id}
**Constraint bias**: {bias}
**Spec version**: v{spec-version}
**Ship kind**: clean | gated
**HITL approval**: {user, timestamp}

## Grounds for ship

{The named qualitative grounds from gate item 1, verbatim — what this variant does
that the alternatives don't, in behavior terms. Never a scalar.}

## Revert probe

**Fired**: {ISO8601} in {scratch worktree path} — reverse diff applied cleanly: yes/no
{any caveats}

## Post-ship watches (pre-registered)

| Watch | Observed via | Fires → |
|-------|--------------|---------|
| {regression/condition} | {mechanism} | {rollback / ruling / remedy PR / narrow redispatch} |

## Pareto-front scores at ship (context, not grounds)

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
- SR-020: deferred (gated ship) — watch armed; covered on evidence
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
- `status`: `shipped` if clean; `in-flight` continues if gated (deferred SRs remain open)
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
- Variant shipped + the named grounds
- Spec version
- Revert-probe result + watches armed
- Comms artifacts (paths)
- Rollout plan summary
- Active dissents at ship (with status)
- Next-step suggestion: advance ring | watch | start next effort (post-ship work is spec-side and probe-side unless a watch fires)

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

- Always preference-articulator on ship (production deployment is **always** human-initiated)
- Gated ship: confirm deferred SRs disclosure
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

### Clean ship after the first cull

```
/flow-ship var-2
```

The cull close surfaced var-2 and chavruta ran. The gate walks its nine checks: grounds named ("only variant whose retry handling survives the SR-019 adversarial cases"), deep eval pass run, ledger audit clean, revert probe fired, watches registered. HITL approval. Variant promoted. Ring 0 ships now, ring 1 awaits explicit advance.

### Gated ship with deferred SRs

```
/flow-ship var-3 --gated
```

Stability is high, spec proximity is partial (a metastable candidate from the cull). HITL confirms which SRs are deferred. Variant ships feature-flagged with watches armed on the deferred scope; remaining SRs are implemented on evidence, not on a schedule.

### Rollback

```
/flow-ship --rollback ship-2026-05-13-0001
```

Reverses the prior ship. Working tree restored. Rollback comms generated. Post-ship monitoring continues for forensic data.

## Operator output

Every run closes with the operator block per `context/flow-operator-voice.md` — What happened / What it means / Decisions needed / Next step, at most 150 words, suite terms glossed on every use, no naked metrics. For this skill: report what went out, to whom, behind which flag, and the watch condition that would trigger rollback — all four, plainly.
