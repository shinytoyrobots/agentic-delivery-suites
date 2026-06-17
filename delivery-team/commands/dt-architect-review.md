---
description: Adversarial review of architecture-proposal.md — required-elements check, quality scoring, red-flag detection. Emits a severity-scored report with overall verdict.
argument-hint: "[path to architecture-proposal.md or directory containing it]"
model: sonnet
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Write
capability-class: content-review
tier: II
domain: [dt]
works-with:
  requires-context: [dt-pipeline-stages, dt-artifact-schemas, dt-schemas-planning, vault-access]
  upstream-skills: [dt-architect]
  downstream-skills: [dt-start]
  compatible-agents: []
readiness:
  state: green
  idempotent: true
  warm-start: false
cost:
  model-class: medium
  agent-count: 0
  web-calls: none
  context-budget: medium
---

# Adversarial Architecture Review — dt-architect-review

Read-only review of an `architecture-proposal.md` produced by `dt-architect`. MUST NOT modify the proposal. Output is one report with one row per check (severity `BLOCKING` / `ADVISORY` / `OK`) and an overall verdict from the exact vocabulary: `READY`, `MINOR REVISIONS`, `BLOCKING REVISIONS`.

This skill closes the schema-discipline loop: dt-architect produces an opinionated artifact, this review enforces the schema before downstream agents (`dt-start`) consume it.

## Required Reading

- `~/.claude/commands/context/dt-pipeline-stages.md`
- `~/.claude/commands/context/dt-artifact-schemas.md`
- `~/.claude/commands/context/dt-schemas-planning.md`
- `~/.claude/commands/context/vault-access.md`

## Input & Path Resolution

1. If `$ARGUMENTS` is a path to `architecture-proposal.md`, use it directly.
2. Else if `$ARGUMENTS` is a directory, look for `architecture-proposal.md` inside it.
3. Else `Glob` `sprints/*/sprint-*/architecture-proposal.md`, sort by mtime desc, pick first. Announce: `Resolved proposal path: {path}`.
4. If file missing, halt: `MISSING: architecture-proposal.md not found at {path}. Cannot review.`
5. `Read` the proposal in full.
6. Derive `feature-slug`: lowercase parent dir name, replace non-alphanumerics with `-`, collapse repeat dashes, trim edge dashes.

## Per-Check Logic

Run each check independently. A check produces one row: `{id} | {severity} | {evidence} | {suggested fix if severity != OK}`.

### Required-elements checks (binary — missing = BLOCKING)

#### E1 — Workload Signature precedes architectural names

Verify §2 (Workload Signature) exists and contains content. Then `Grep` §2 for any of these architectural nouns: `microservice`, `monolith`, `event-sourced`, `event sourcing`, `CQRS`, `lambda`, `serverless`, `mesh`, `service mesh`, `kafka`, `pub/sub`, `pub sub`. If found in §2 → `BLOCKING` with suggestion: "Workload signature contaminated with pattern names — agent failed Pass 1. Re-run dt-architect."

If §2 missing entirely → `BLOCKING`: "§2 Workload Signature absent. Required for Pass 1 discipline."

#### E2 — Quality attributes with measurable response measures

§3 must contain ≥2 quality attributes. For each, check that at least one of these is present: a number, a unit (ms, s, %, RPS, GB), or a 6-part scenario (Source / Stimulus / Environment / Artifact / Response / Response Measure). Vague-only attributes ("fast", "reliable", "secure" with no numbers) → `BLOCKING` per attribute with suggestion: "Replace vague verb with measurable response measure (e.g. 'p95 < 200ms')."

If §3 has fewer than 2 attributes → `BLOCKING`: "Fewer than 2 quality attributes. Architecture must articulate the qualities it optimizes for."

#### E3 — Approach options + Option 0

§4 must contain 2 or 3 distinct approach options PLUS an Option 0 ("Don't build this yet" or equivalent). Count headings like `### Option N` and verify Option 0 is present.

- Fewer than 2 approaches → `BLOCKING`: "Need 2-3 approaches; only N found."
- More than 3 approaches → `ADVISORY`: "More than 3 options dilutes recommendation. Consider consolidating."
- Option 0 missing → `BLOCKING`: "Option 0 ('Don't build yet') is mandatory. Forces defense of bias toward action."

#### E4 — Transposition check stated

§4 must contain explicit text addressing whether the proposed options are topologically distinct. Look for phrases like "transposition", "topologically distinct", "do not converge", "independent topologies", or equivalent. Missing → `BLOCKING`: "Transposition check absent. Verify options are topologically distinct, not cosmetically different."

#### E5 — Recommendation includes objection and consultation list

§5 must contain:
- A "Strongest objection" or "Steelman" subsection with concrete dissent (not "this could be wrong")
- A "Who to consult" or "Consultation list" subsection mapping domains/concerns to roles or named individuals

Either missing → `BLOCKING`: "§5 must include strongest objection AND consultation list. Agent operates as advisor (Harmel-Law); recommendation without dissent is shadow architecture."

#### E6 — C4 levels 1–3 present

§6 must reference all of: System Context (L1), Container (L2), Component (L3). Code (L4) is optional.

- Any of L1/L2/L3 missing → `BLOCKING`: "C4 level {N} absent. Component view incomplete."

#### E7 — Team Topology with explicit count + Inverse Conway flag

§8 must contain:
- A team count (number of teams the architecture assumes)
- An Inverse Conway flag — either "requires reorg" with reasoning, "no reorg required", or "not assessed" with note

Either missing → `BLOCKING`: "§8 Team Topology must specify team count AND Inverse Conway flag. Conway's Law blindness is a documented architectural failure mode."

#### E8 — ADRs in Nygard format

§9 must contain at least one ADR. Each ADR must include all of: Status, Context, Decision, Options Considered, Consequences. Verify with `Grep` for these section headers within each `### ADR-N:` block.

- §9 has zero ADRs → `BLOCKING`: "§9 must contain at least one architecturally-significant decision in Nygard format."
- ADRs present but missing required fields → `ADVISORY` per ADR: "ADR-N missing field {Status|Context|Decision|Options Considered|Consequences}."

#### E9 — Fitness functions trace to quality attributes

§10 must contain 3–7 fitness functions. For each, verify it explicitly references a §3 quality attribute (by name or hashtag). Functions without traceability → `ADVISORY` per function: "Fitness function {name} does not trace to a §3 quality attribute. Functions divorced from scenarios drift from intent."

- Fewer than 3 functions → `BLOCKING`: "Fewer than 3 fitness functions. Quality attributes need automated guardrails."
- More than 7 → `ADVISORY`: "More than 7 functions. Consider whether all are load-bearing."

#### E10 — Vertical slices, not horizontal layers

§11 must contain at least 2 slices. For each slice, verify it is organized by use-case (named after a user-visible or operator-visible capability), not by architectural layer. Detect horizontal slicing via these patterns in slice names: `Database`, `API layer`, `UI layer`, `Frontend`, `Backend`, `Persistence layer`, `Service layer`. Any horizontal slice → `BLOCKING`: "Slice {name} is horizontal (layered). Vertical slicing (by use-case) is required for INVEST-shaped stories."

If §11 has fewer than 2 slices → `BLOCKING`: "Need at least 2 vertical slices to bridge architecture to stories."

#### E11 — Walking skeleton with mode + components + validation criteria

§12 must contain:
- An explicit Cockburn vs Adzic mode choice
- The slice (named user-visible or operator-visible path)
- Components exercised (list)
- Validation criteria (3–5 measurable assertions)
- Estimated time-to-walking (in days)

Any missing → `BLOCKING` per missing field. If walking skeleton describes a "hello world deploy" without exercising actual architecture components → `BLOCKING`: "Walking skeleton must exercise every container in §6, even trivially. 'Hello, production' — not 'Hello, dev environment'."

### Quality dimension checks (graded — ADVISORY if poor)

#### Q1 — Length discipline

Count words in the proposal. Roughly:
- ≤ 4 pages worth (~2400 words): `ADVISORY` — "Possibly too brief; verify all 14 sections are present and substantive."
- 4–8 pages (~2400–4800 words): `OK`
- 8–12 pages: `OK` — note "Approaching upper bound."
- > 12 pages (~7200+ words): `ADVISORY` — "Architecture writeup exceeds 12 pages. Decision is probably too big and should be split (Harmel-Law self-throttling)."

#### Q2 — Optionality discipline (Gregor's Law)

For each option in §4, verify a "complexity cost" or equivalent line exists. Missing on any option → `ADVISORY`: "Option {N} omits complexity cost. Gregor's Law: every option's price tag must be named."

#### Q3 — Reversibility honesty

For each option in §4 and each ADR in §9, verify reversibility classification (one-way / two-way / time-bounded-two-way) is present. Missing → `ADVISORY` per occurrence: "Reversibility classification absent. Time-qualifier preferred (e.g. 'two-way until first external API consumer integrates')."

#### Q4 — Conway's Law alignment

If §8 declares team count N and §6 declares M components, with M > 2N AND no Inverse Conway flag, → `ADVISORY`: "Architecture proposes M components for N teams. Either flag Inverse Conway requirement or reduce component count."

#### Q5 — Decomposition bridge quality

For each slice in §11, verify presence of a splitting hint (SPIDR or Humanizing Work pattern). Slices without hints → `ADVISORY`: "Slice {name} has no splitting hint. dt-start will reverse-engineer; pre-stage with SPIDR or Humanizing Work pattern."

### Behavioral red-flag checks (any one = BLOCKING — re-run dt-architect)

These supplement E1–E11 with second-pass diagnostics that rerun the same content from a different angle.

#### R1 — Topologically identical options

If §4 contains 3 options where 2+ describe the same runtime topology (same process count, same data store, same protocol), → `BLOCKING`: "Options N and M are topologically identical despite cosmetic differences. Fake trilemma. Re-run with explicit transposition check enforcement."

#### R2 — Recommendation lacks credible objection

§5's "Strongest objection" must be a substantive critique, not a strawman. Heuristic: if the objection is shorter than 30 words OR contains hedging language ("might", "perhaps", "could be"), → `ADVISORY`: "Objection appears weak. The strongest objection should be specific and uncomfortable for the recommendation."

#### R3 — Walking skeleton omits architectural components

§12's "Components exercised" list must overlap meaningfully with §6's container list. If §12 exercises < 50% of §6 containers, → `BLOCKING`: "Walking skeleton does not exercise the architecture. Cockburn: 'should link together the main architectural components.'"

## Report Assembly

### Severity → Verdict

Any `BLOCKING` row → `BLOCKING REVISIONS`. Else any `ADVISORY` → `MINOR REVISIONS`. Else → `READY`. Use these exact strings. Do not paraphrase.

### Output path

If the proposal lives in `sprints/{effort}/sprint-{N}/architecture-proposal.md`, write to `sprints/{effort}/sprint-{N}/dt-architect-review-{feature-slug}.md`. Else write to `{proposal-dir}/dt-architect-review-{feature-slug}.md`.

### Report format

```markdown
# Architecture Review — {feature-slug}
**Verdict**: {READY | MINOR REVISIONS | BLOCKING REVISIONS}
**Source**: {resolved proposal path}
**Reviewed**: {YYYY-MM-DD}

## Required-elements findings
| Check | Severity | Evidence | Suggested fix |
|-------|----------|----------|---------------|
| E1 | {sev} | {snippet} | {fix or —} |
| E2 | {sev} | … | … |
| … |

## Quality dimension findings
| Check | Severity | Evidence | Suggested fix |
|-------|----------|----------|---------------|
| Q1 | {sev} | … | … |
| … |

## Behavioral red-flag findings
| Check | Severity | Evidence | Suggested fix |
|-------|----------|----------|---------------|
| R1 | {sev} | … | … |
| … |

## Summary
- BLOCKING count: {N}
- ADVISORY count: {N}
- OK count: {N}

## Next steps
{If READY: proceed to /dt-start.
If MINOR REVISIONS: address advisories at human reviewer's discretion.
If BLOCKING REVISIONS: re-run dt-architect with the BLOCKING items as constraints, OR address inline if review is by human.}
```

`Write` once. Do not read back. Print output path + verdict in a final one-line summary.

## Failure Modes

- **Missing proposal file** → halt with `MISSING: architecture-proposal.md`. No partial report.
- **Malformed sections** → continue other checks; add `ADVISORY` row naming the parse failure.
- **Empty section that's required** → emit the corresponding BLOCKING row. Do not halt.
- **Write target unwritable** → report OS error + print the full report inline so the reviewer still receives it.
- **Read-only guarantee** → writes exactly one file (the review report). MUST NOT modify `architecture-proposal.md`.

## Calibration note

This skill is intentionally strict. The schema is opinionated; the review enforces that opinion. If too many proposals fail, either (a) the schema is over-tuned (revise dt-architect), or (b) the agent's prompt is under-specified (revise dt-architect's foundational principles). Don't loosen the review — it's the schema-discipline loop.

## When to invoke

- After every `dt-architect` run, before `dt-start` consumes the proposal
- During `pm-spec-review` if the spec bundle includes an architecture-proposal.md
- During `dt-readiness-gate` to validate architecture-proposal.md as a readiness artifact
- Manually, when reviewing a proposal authored by a human (the schema applies to humans too)
