---
description: Interpretation panel — probe the spec before any generation. 3-5 cheap parallel readers independently commit to readings of the in-scope slice; divergence is located spec ambiguity, routed to flow-spec before a single implementation token is spent.
argument-hint: "[scope SR-IDs or SCN-IDs, default: full in-scope slice] [--readers <3-5>]"
model: sonnet
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - Agent
capability-class: review
tier: III
domain: [flow]
works-with:
  requires-context: [flow-spec-protocol, flow-state-model, flow-operating-doctrine, flow-operator-voice, vault-access]
  upstream-skills: [flow-spec, flow-init]
  downstream-skills: [flow-spec, flow-generate]
  compatible-agents: [flow-orchestrator]
readiness:
  state: green
  idempotent: true
  warm-start: true
cost:
  model-class: low
  agent-count: variable
  web-calls: none
  context-budget: small
---

# Flow Panel

Read context files:
- `~/.claude/commands/context/flow-spec-protocol.md`
- `~/.claude/commands/context/flow-state-model.md`
- `~/.claude/commands/context/flow-operating-doctrine.md`
- `~/.claude/commands/context/flow-operator-voice.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

The pre-generation spec probe, standalone. Part of the probe moves to where it is
cheapest: **before implementation**. Independent cheap readers each commit to a reading
of the spec slice without seeing each other; the diff of their readings locates ambiguity
at ~5–8k tokens per reader instead of ~400k per implementation — two orders of magnitude
cheaper than discovering the same fork as population disagreement.

Doctrine (step 2): **every spec round ends with a panel**, and spec → panel runs without
committing to a generation. This command exists so the panel is reachable on its own —
previously it was buried in `flow-generate`'s pre-dispatch step and `flow-spec --panel`.
In spec-only mode (no populations at all), the panel is the *only* probe the effort gets;
in full flow it is the pre-filter that makes the expensive population argue about fewer
known ambiguities.

A panel predicts divergence; a population demonstrates it, including forks nobody
articulates. The panel does not replace the gen-1 population on full-flow efforts.

## Inputs

- **scope** (optional) — SR-{NNN}/SCN-{NNN} list; defaults to the full in-scope slice for
  the next generation (or the whole spec if no generation is planned)
- `--readers <count>` — 3–5; default 3, use 5 when the slice is large or security-bearing

## Procedure

### Step 1: Read state and assemble the slice

- `spec/spec.md` — extract in-scope SCN/SR + glossary + the invariants this scope can
  violate. The slice, not the bundle.
- `spec/constitution.md` — weight class (informs reader count default)
- `flow-state.yaml` if present — current generation context

### Step 2: Skip check (pure ratification)

If the last spec round changed nothing semantically (patch-only since the last panel, no
new or amended SCN/SR in scope), report "nothing to probe" and stop. Pure-ratification
rounds do not pay for a panel.

### Step 3: Spawn readers

Spawn N cheap-tier readers in parallel (one Agent call each, model: sonnet, **reads
only — P1-clean, no writes anywhere**). Each receives the identical slice and, without
seeing the others, must commit to a structured reading:

1. **Per SR: its interpretation, in one sentence.** No hedging, no "it could mean" — commit.
2. **Every decision point where the text admits ≥2 readings**, and which reading it
   would pick.
3. **An implementation sketch** — interfaces and control flow, no code.

### Step 4: Diff the readings

The command (single thread, full context) compares the N readings:

- **Convergent** on an SR → confidence the text is tight; note it.
- **Divergent** → located spec ambiguity. For each divergence record: the SR, the
  readings found, which readers held each, and a proposed disambiguation.

### Step 5: Write the panel record

Write `spec/.staging/panel-{date}.md`: readers spawned, slice covered, per-SR verdict
(convergent | divergent), each divergence with its proposed amendment, and a one-line
panel verdict (`panel-clean` | `N divergences`).

### Step 6: Route divergences

Each divergence becomes either:
- a proposed spec amendment → `/flow-spec amend ...` (normal HITL amendment flow), or
- a recorded **accepted ambiguity** (the operator decides the fork is genuinely free) —
  noted in the panel record so generator decision ledgers can cite it.

The panel locates ambiguity; it never resolves it. No spec change happens here.

### Step 7: Report

Return: readers spawned, SRs covered, convergent/divergent counts, divergences with
proposed routes, and the next-step suggestion — `/flow-spec` to amend if divergent;
`/flow-generate` (full flow) or conventional build (spec-only mode) if panel-clean.

## What this skill does NOT do

- **It does not modify the spec.** Divergences route through `/flow-spec`'s amendment flow.
- **It does not dispatch generators.** `flow-generate` checks for a recent panel; it does
  not run one implicitly.
- **It does not replace the population probe** on full-flow efforts.

## Outputs

| Path | Action |
|------|--------|
| `spec/.staging/panel-{date}.md` | Panel record: readings, diff, verdict |
| `efforts/{effort}/flow-state.yaml` | Phase-log appended (if an effort is active) |

## HITL surface

- Each divergence surfaced as its own decision (amend vs accept), never a stacked list
- Reader count above 5 requested: refused — width beyond 5 adds cost, not signal, at
  panel depth

## Failure modes

- A reader returns an unstructured or hedged reading: re-prompt once with the commit
  requirement restated; if still hedged, note the reader as non-committal and diff the rest
- Spec has no in-scope SCN/SR: report and suggest `/flow-spec` first

## Idempotency

Idempotent per spec version — re-running on an unchanged spec produces a fresh panel
record with (modulo sampling variance) the same divergences. Each run writes its own
dated record.

## Examples

### Panel after a spec round, before deciding on a generation

```
/flow-panel
```

3 readers over the 6 in-scope SRs. Two divergences located on SR-012 (retry scope) —
routed to `/flow-spec amend`. Generation deferred until the amendment lands.

### Security-bearing slice, wide panel

```
/flow-panel SR-001,SR-007 --readers 5
```

5 readers; the SR-001/SR-007 interaction is exactly the class of fork that previously
cost 9 implementations to surface.

## Operator output

Every run closes with the operator block per `context/flow-operator-voice.md` — What
happened / What it means / Decisions needed / Next step, at most 150 words, suite terms
glossed on every use, no naked metrics. For this skill: lead with the verdict — "the
readers agreed" or "the readers split N ways on {SR}" — and what each split would have
cost if discovered after implementation instead.
