# Using flow

Most AI delivery tools graft language models onto existing Scrum workflows. `flow` doesn't.

Scrum exists because humans get tired, change their minds, and need ceremony to coordinate. Agents have none of those problems. The rituals that compensate for them — sprints, stories, retros, readiness gates, fixed roles — aren't features. They're scar tissue from a constraint that no longer applies.

This is the practitioner's guide. If you're deciding whether `flow` fits your work, read the rationale and the benefits. If you've decided to try it, skip to the walkthrough. The philosophy in dense form is in `context/flow-philosophy.md`; the directory schema is in `context/flow-state-model.md`. This document is the bridge.

> **Reader note**: This doc frames `flow` against its sibling suite `delivery-team`. If you haven't used `delivery-team`, skim the comparisons and go straight to the principles and walkthrough.

---

## What flow is

A Claude Code skills suite that runs software delivery as continuous flow toward convergence.

The unit of work is not a story. It's a **generation**: a population of implementation variants produced from a versioned spec, scored against a multi-objective eval suite, culled to a Pareto front, and either advanced or shipped. No sprint. No retro. No readiness gate. No fixed role topology.

The spec itself is two layers. **GWT behavioral scenarios** (`SCN-{NNN}`) are the product-facing layer — Given/When/Then examples a human authors and reviews, which also seed the eval datasets. **EARS requirements** (`SR-{NNN}`) are the system-centric layer — either decomposing a scenario's acceptance criteria or capturing ambient non-functional constraints (performance, security, cost) with no scenario parent. The two are complementary, not alternatives.

The exit is convergence. The calendar doesn't get a vote.

`delivery-team` accelerates a Scrum team's workflow with AI. `flow` discards the Scrum scaffolding and rebuilds the pipeline around what LLM agents are good at — parallel reading, structured scoring, deterministic projection — and what they are famously bad at — parallel writes, free-form coordination, drifting prose. The two suites are siblings in this repo, designed for head-to-head comparison.

## Why it exists

`flow` is the operational answer to six findings in the 2024–2026 compound-AI research literature. Each finding contradicts a structural assumption the older `delivery-team` suite carries forward from human workflows. The full evidence trail lives in the deep-research source (see Related reading); the short form follows.

**P1 — Intelligence parallel, writes serial.** Cognition AI's 2025 "Don't Build Multi-Agents" pivot. Parallel writes by independent agents accumulate conflicting implicit decisions. The narrow case where multi-agent works is parallel readers feeding a single decision-maker. `delivery-team` violates this whenever its frontend, backend, and middleware devs author against the same story in parallel.

**P2 — Dynamic dispatch over fixed roles.** Stanford's MASS paper (2025) shows that optimizing pipeline topology and prompts beats fixed agent role-play by 78.8%. Anthropic's multi-agent research system dispatches by complexity — one agent for simple tasks, two-to-four for comparisons, ten or more for complex research — and gets 90% improvement over single-agent. Roles are a human hiring compromise. They are not an architectural property.

**P3 — Spec as source of truth, code as regenerated output.** Drew Breunig's `whenwords` library (Feb 2026) has zero human-written code, 750 conformance tests, and is maintained spec-only. Tessl, Kiro, and GitHub Spec-kit are production-grade. Stories drift from code; specs don't, because code is rebuilt from them.

**P4 — Multi-objective Pareto evaluation over single-threshold gates.** Stanford's Optimas (ICLR 2026) and Anthropic's eval engineering work converge on the same point: quality is a vector. Single thresholds — the classic "80% coverage" — invite Goodhart-gaming. Multi-objective fronts plus adversarial holdouts resist it.

**P5 — Continuous flow over time-boxed cycles.** Sprints time-box human commitment uncertainty. Agents don't have that uncertainty. The calendar is arbitrary. Convergence is the natural exit.

**P6 — Preserved dissent with reactivation conditions.** Borrowed laterally from the Talmudic chavruta pattern. The minority position in a review becomes a structured object with an explicit condition under which it would later be vindicated. A monitor watches every commit for that condition. Institutional memory stops being ceremonial and becomes structural.

These six aren't aspirational. Every skill in the suite traces back to them, and the skills cite them as P1–P6 when a design choice needs defending.

## What you get

Five benefits. Each one is tied to a mechanism, not a slogan.

### Decision quality from population search

`delivery-team` builds one implementation per story and asks "did it pass?" `flow` builds five (default; the orchestrator scales from 1 to 10 by complexity, with a hotfix bypass to a single serialized variant) and asks "which trades off which way?" Five Pareto-scored variants give gradient signal — this one is faster but more complex, that one is simpler but slower — instead of a binary pass/fail on a single attempt.

The cost is real. Roughly 5x generation tokens per effort. A medium feature runs $5–15 per generation (estimate), against $1–3 for a single-implementation `delivery-team` run. With Sonnet or Haiku for generators and Opus reserved for the orchestrator and evaluator, the delta is meaningful but not prohibitive. On bounded problems with clear eval surfaces, the decision-quality gain pays for it.

### Consistent comms via spec projection

`delivery-team`'s Stage 5 launches Marketing, GTM, and CX/Support agents in parallel to produce launch artifacts. Each rediscovers the spec delta independently. `flow-narrator` reads `git diff(spec_N, spec_N+1)` once and projects it into every audience tier — changelog, sales talking points, support doc, marketing brief — at the same time, from the same source. Consistency is structural, not editorial.

A spec amendment that adds rate limiting becomes a changelog entry, a sales note about "now supports controlled-burst customers," and a support doc on the new 429 status code. All derived. Never authored ad-hoc. Never out of sync with what shipped.

### Structural institutional memory

`delivery-team` archives the adversarial PM review at gate-close. Nothing watches it afterward. `flow` writes every dissent to `efforts/{slug}/dissents-active.yaml` with explicit reactivation conditions — for example, "the stability reviewer argued this breaks if request volume exceeds 10x baseline; flag if `req-throughput > 10x` enters the spec." `flow-dissent-monitor` runs on every commit and surfaces matching dissents as check findings.

The pattern is designed to compound. The first three efforts produce no surfaced dissents — the registry is warming up. By effort five or six, it should begin rediscovering objections that human teams routinely forget. That's the expectation, not an observed outcome. `flow` is new; no effort has yet reached that range.

### End-to-end optimization is unblocked

`delivery-team`'s 13 statically wired agents cannot be optimized as a system. There is no end-to-end metric to train against. `flow`'s pipeline is structurally a DSPy-compatible program: predictor modules, tool calls, control flow, metric. Whether or not you ever run the optimizer — Optimas, MIPRO, GEPA — the option is architecturally available. The system can be measured as a single function from problem to ship.

### No close ceremony, no false closure

`delivery-team` runs `dt-close` at the end of every sprint, producing a summary and a retro. Sprints close on the calendar, even when the work hasn't reached a natural stopping point. `flow` has no `flow-close` and no `flow-retro`. An effort transitions to `shipped/` when convergence is reached or a metastable variant is selected. The retro function is absorbed into the cull cycle — every generation produces a diff between predicted and actual eval scores, so learning becomes structural rather than ceremonial.

Most "close" rituals manufacture closure on work that should remain open, and re-open it implicitly the next sprint. `flow` doesn't manufacture closure.

## What you don't get (anti-features)

Five things `flow` deliberately omits. Each absence is research-flagged.

- **No parallel writes.** Generators run in parallel but write only to their own variant directories. Only `flow-converge` promotes a single survivor to the working tree.
- **No purely evolutionary search.** AlphaEvolve works on well-defined computable objectives. Product work is partially open-ended. Variants exist within spec-bounded constraint space, not free generation.
- **No automated metric optimization without HITL.** Goodhart's law is real. The human preference-articulator role is non-optional for spec evolution and eval design.
- **No spec-as-source maturity at v1.** `flow` ships at Fowler's level 2 (spec-anchored): specs are primary, code is regenerated on spec change, but legacy paths can be edited directly when conformance tests are intact. Level 3 — spec-only edits — is a future state.
- **No full elimination of role narrative.** Generators get constraint variation (one biased for performance, another for simplicity) but the underlying agent is the same function. Niche differentiation is a runtime parameter, not an identity.

## When to use flow, when to stay on delivery-team

`flow` is the right tool when:

- The problem can be written as GWT scenarios plus testable EARS requirements.
- The eval surface is instrument-able — correctness, performance, accessibility have measurable signals.
- The work is bounded enough that running five variants isn't prohibitive.
- You want population-search decision quality and are willing to pay the token cost.

Stay on `delivery-team` when:

- The spec genuinely cannot be written precisely (exploratory research, brand-new product surface).
- Stakeholders need Scrum vocabulary for organizational legibility.
- External dependencies dominate the schedule and population search adds no signal.

The `flow` constitution includes an explicit escape hatch: if spec confidence drops below threshold, drop to `delivery-team` story mode. The two suites are not exclusive.

## How to use it

The lifecycle is six phases. Skills are user-invoked slash commands; agents are background functions skills dispatch (e.g., `flow-init` dispatches `flow-spec-writer`, `flow-evaluator`, and `flow-context-curator`). You invoke skills. The orchestrator decides which agents to spawn.

### Prerequisites

Before running any flow skill:

- Claude Code installed and able to read `~/.claude/commands/`
- The `flow` suite linked into `~/.claude/commands/` (symlinked from this repo per the repository convention in the root `CLAUDE.md`)
- A working directory — greenfield or an existing codebase with git initialized
- Working familiarity with EARS notation (Easy Approach to Requirements Syntax) — see `context/flow-spec-protocol.md` if unfamiliar
- A purpose paragraph for the effort: what problem you're solving and why

The walkthrough below lists each skill in the order you'd invoke them on a typical effort.

### Phase 1 — Initialize the effort

```
/flow-init <effort-slug> [--from-spec <path>] [--from-delivery-team <effort>]
```

`flow-init` bootstraps the directory structure. It asks for a purpose paragraph, the codebase path, your HITL mode, any hard prohibitions, and the starting temperature. It then writes:

- `spec/spec.md` — initial EARS-formatted executable spec (may be skeletal)
- `spec/constitution.md` — governance: prohibitions, preferences, escalation triggers
- `evals/harness.yaml` — eval suite scaffolded with six default dimensions (correctness, performance, maintainability, accessibility, security, cost)
- `efforts/{slug}/flow-state.yaml` — convergence score, temperature, WIP spread, Pareto front, active dissents
- `.flow-index/` — codebase index for context curation

Flags: `--from-spec <path>` ingests an existing PRD as the spec seed; `--from-delivery-team <effort>` migrates from a prior sprint-shaped effort.

This step is **not idempotent**. Re-running on an existing effort halts.

### Phase 2 — Evolve the spec

```
/flow-spec <natural-language intent or "amend SR-NNN ..."> | --restructure | --constitution
```

Any time intent changes, route it through `flow-spec`. It refuses vague natural language: user journeys become GWT scenarios (`SCN-{NNN}`), and non-functional intents become derived EARS requirements (`SR-{NNN}`). It versions `spec/spec.md`, writes an entry in `spec/history/`, and triggers a dissent reactivation check — a spec change may match an archived dissent's condition.

`--restructure` groups SRs without changing semantics. `--constitution` amends `spec/constitution.md` — prohibitions, preferences, escalation triggers, dispatch overrides — which is the only sanctioned way to change governance after init.

The spec is the contract every downstream skill assumes. Skip `flow-spec` and edit requirements ad-hoc, and the chain breaks silently.

### Phase 3 — Author the eval suite

```
/flow-eval [dimension-name] | --add-dataset <dim> <path> | --refine <grader> | --threshold <dim> <value>
```

`flow-eval` populates the per-dimension datasets and graders. Each dimension needs at least one real-world dataset; correctness and security additionally require an adversarial holdout (Goodhart mitigation). Run with no arguments for an interactive walk through the suite. Use the targeted flags to add datasets, refine graders, or adjust thresholds.

Evals are a first-class versioned artifact. They aren't a test harness — they're the executable half of the spec contract.

### Phase 4 — Generate and cull

```
/flow-generate [scope SR-IDs or "all"] [--hotfix] [--N <count>]
/flow-cull     [--depth quick|standard|deep|adversarial]
```

`flow-generate` dispatches generator agents in parallel. Default population is 5; the orchestrator scales from 1 to 10 based on complexity (SR count, blast radius, plateau state, temperature). `--hotfix` bypasses population search entirely and serializes a single variant. `--N` overrides the orchestrator's choice. Each generator gets a distinct constraint bias (`simplicity`, `performance`, `maintainability`, `security`, `convention`, plus `radical` at high temperatures) and writes to its own variant directory under `efforts/{slug}/generations/gen-{N}/population/`.

`flow-cull` runs the eval suite against each variant, computes the Pareto front, archives strictly-dominated variants, and flags any metastable candidates — stable intermediate states with partial spec proximity that are first-class ship candidates, not WIP. The `--depth` flag controls eval depth; `adversarial` runs the Goodhart-detection passes.

### Phase 5 — Converge or anneal

```
/flow-converge [--force-ship | --force-iterate]
/flow-anneal   heat | cool | reset | --to <0.0-1.0> | --status
```

`flow-converge` checks two signals: inter-variant similarity (have the survivors converged on a solution shape?) and Pareto-front stability (are the dimension scores still climbing?). If converged, it triggers `flow-chavruta` and prepares to ship. If not, it advances to gen N+1. The `--force-*` flags override the recommendation when the operator has out-of-band judgment.

`flow-anneal` adjusts the temperature parameter. When the front plateaus across two generations without progress, `heat` widens exploration and forces constraint-variation divergence. Cool it back down as convergence reapproaches. Reheating triggers — eval plateau, architectural blocker, dissent reactivation cluster — fire automatically; this skill is the manual override.

### Phase 6 — Review, ship, monitor

```
/flow-chavruta [variant-id | "spec-change" | "metastable"]
/flow-ship     <variant-id> | --metastable | --rollback <ship-id>
```

`flow-chavruta` runs the stability-bias and velocity-bias reviewers against the survivor. **Their disagreement is the deliverable.** The review exits at documented disagreement with provisional resolution and explicit reactivation conditions — not at consensus. Dissents append to `dissents-active.yaml`.

`flow-ship` promotes the variant to the working tree, runs progressive rollout via feature flags, and invokes `flow-narrator` to derive audience-tiered comms from the spec delta. `--metastable` ships a stable intermediate state that doesn't yet hit every threshold but is valuable as-is. `--rollback` reverts a prior ship by ID. Post-ship, the eval-front continues running in production.

### Cross-cutting skills

These aren't phase-bound. Invoke any time:

- `/flow-pulse [--comms | --verbose | --json]` — read-only state report: convergence score, Pareto front, temperature, WIP spread, active dissents. The single status command. No sprint velocity. `--comms` projects the current spec-delta into audience-tiered comms on demand.
- `/flow-dissent --list-active | --list-reactivated | --check | acknowledge <id> | mitigate <id> --commit <sha> | resolve <id> --reason <text>` — query the registry, run a manual reactivation check, or take action on a surfaced dissent.

## A walkthrough sketch

Illustrative, not a script. A first effort using `flow` typically runs three to four generations before convergence. Rough shape:

1. **Init.** `/flow-init customer-portal-rewrite` with a purpose paragraph and the codebase path. Skeletal spec with 3–5 SRs. Default temperature 0.5.
2. **Spec authoring.** Two or three `/flow-spec` passes to firm up the GWT scenarios and their derived EARS requirements. HITL counter-prompts vague NL into testable form.
3. **Eval bootstrapping.** `/flow-eval` populates the datasets. Correctness and security get adversarial holdouts.
4. **Gen 1.** `/flow-generate` spawns 5 variants. `/flow-cull` reveals two on the Pareto front, three dominated. `/flow-converge` says no — inter-variant similarity is low.
5. **Gen 2.** Generators re-run against the spec, biased by the gen-1 front. Similarity rises but the maintainability dimension plateaus.
6. **Reheat.** `/flow-anneal heat`. A new constraint-bias is seeded.
7. **Gen 3.** Survivors converge. Pareto front is stable. `/flow-chavruta` runs and produces one dissent — stability reviewer flags a load-spike condition.
8. **Ship.** `/flow-ship` promotes the survivor, flags it behind a percentage rollout, and `flow-narrator` projects the spec delta into the changelog, sales note, and support doc.

The whole cycle is convergence-bound. No sprint number on any of these artifacts.

## State at a glance

`flow-state.yaml` is the single readable state file. Key fields:

| Field | Meaning |
|-------|---------|
| `current-generation` | The active generation number |
| `convergence-score` | 0..1; ship threshold is 0.85 by default |
| `temperature` | 0..1; 1.0 = full explore, 0.0 = full exploit |
| `wip-spread` | Admission cost for new work items (price signal, not cap) |
| `pareto-front` | Best score per dimension across the current generation |
| `active-dissents` | Count; full records in `dissents-active.yaml` |
| `hitl-mode` | `preference-articulator` / `comprehension-auditor` / `reactivation-watch` / `autonomous` |

`/flow-pulse` reads this file and prints a human-readable summary.

## Validating that flow is working

The suite is opinionated. It should be testable.

`README.md` lists the six-metric A/B harness — three velocity dimensions (wall-clock, token spend, human review burden) and three quality dimensions (eval-front coverage, defect rate at +14 days, comprehension cost at +7 days) — along with the decision rule and the tie back to the research source. Run the comparison head-to-head against `delivery-team` on a single effort. Use the data, not intuition, to decide whether to keep going.

Two limits worth naming up front. Fourteen days is too short to measure long-term comprehension debt. The dissent registry's value is cumulative — it won't show up until effort five or six. Plan a re-measurement at 90 days and across multiple efforts before drawing firm conclusions.

## Related reading

- `README.md` — concise suite manifest (skills, agents, state model)
- `context/flow-philosophy.md` — the six principles in dense form with citations
- `context/flow-state-model.md` — full `flow-state.yaml` schema and directory layout
- `context/flow-spec-protocol.md` — EARS authoring, spec evolution, conformance tests
- `context/flow-eval-protocol.md` — eval suite structure, multi-objective Pareto, metastable detection
- `context/flow-dispatch-rules.md` — dynamic complexity-based dispatch and the canonical generator-count rules
- `context/flow-dissent-protocol.md` — dissent object schema, reactivation conditions, monitor behavior
- Research provenance: the sources behind the six principles are listed in the "Research provenance" table in `README.md`
