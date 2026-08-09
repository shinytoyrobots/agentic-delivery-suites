# Using flow

## Quickstart, in plain English

`flow` builds software by writing a precise spec, probing it with cheap parallel readers, then generating **one wide round** of competing implementations, scoring them against automated tests from multiple angles, adversarially reviewing the winner, and shipping it with a tested rollback path and pre-registered watches. You review the spec and make the judgment calls; the suite does the building and scoring. Further generations happen only when evidence demands them — a fired watch, a fork the tests can't settle, a spec change.

**What it costs**: each generated implementation runs roughly 150k–400k tokens depending on the effort's cost/rigor tier (weight class), so one generation of a heavyweight effort can run into millions of tokens. `flow-init` sets the tier and budgets with you up front. Evaluation, not generation, is the real cost center — the suite tiers eval depth accordingly.

**Three modes** (the mode gate is step 0 of every effort — `context/flow-operating-doctrine.md`):

| Mode | Skills | When |
|------|--------|------|
| **Spec-only** | `/flow-spec` → `/flow-panel` → conventional build; tests bound to SRs | Well-understood scope that still deserves executable requirements and a decision record — "the spec is the receipts" |
| **Spec + eval** | + `/flow-eval` graded conformance; no populations | You want graded conformance / a CI story without tournament cost |
| **Full flow** | The whole walkthrough below | Novel, ambiguous, security-bearing, or hard-to-revert scope |

**When not to use it at all**: work too vague to spec precisely, single-file fixes, or anything where one obvious implementation exists — a plain Claude Code session is cheaper and faster there. The suite's own hotfix path (`/flow-generate --hotfix`) covers emergencies.

---

Most AI delivery tools graft language models onto existing Scrum workflows. `flow` doesn't.

Scrum exists because humans get tired, change their minds, and need ceremony to coordinate. Agents have none of those problems. The rituals that compensate for them — sprints, stories, retros, readiness gates, fixed roles — aren't features. They're scar tissue from a constraint that no longer applies.

This is the practitioner's guide. If you're deciding whether `flow` fits your work, read the rationale and the benefits. If you've decided to try it, skip to the walkthrough. The philosophy in dense form is in `context/flow-philosophy.md`; the directory schema is in `context/flow-state-model.md`. This document is the bridge.

> **Reader note**: This doc frames `flow` against its sibling suite `delivery-team` (shipped alongside it in this repo). If you haven't used `delivery-team`, skim the comparisons and go straight to the principles and walkthrough. The current default run shape is `context/flow-operating-doctrine.md` — where older phrasing here and the doctrine disagree, the doctrine wins.

---

## What flow is

A Claude Code skills suite that runs software delivery as continuous flow toward an evidence-gated ship.

The unit of work is not a story. It's a **generation**: a population of implementation variants produced from a versioned spec, scored against a multi-objective eval suite, culled to a Pareto front, and either advanced or shipped. No sprint. No retro. No readiness gate. No fixed role topology.

The spec itself is two layers. **GWT behavioral scenarios** (`SCN-{NNN}`) are the product-facing layer — Given/When/Then examples a human authors and reviews, which also seed the eval datasets. **EARS requirements** (`SR-{NNN}`) are the system-centric layer — either decomposing a scenario's acceptance criteria or capturing ambient non-functional constraints (performance, security, cost) with no scenario parent. The two are complementary, not alternatives.

The exit is `flow-ship`'s gate — named qualitative grounds plus compensating controls. The calendar doesn't get a vote, and neither does a scalar.

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

`delivery-team` builds one implementation per story and asks "did it pass?" `flow` builds a population (3 standard, 5–7 heavy/novel, with a hotfix bypass to a single serialized variant) and asks "which trades off which way — and where do they disagree?" The field trial's highest-consequence defects were caught by cross-variant disagreement, not by the eval suites. Pareto-scored variants give gradient signal — this one is faster but more complex, that one is simpler but slower — instead of a binary pass/fail on a single attempt.

The cost is real. Roughly 5x generation tokens per effort. A medium feature runs $5–15 per generation (estimate), against $1–3 for a single-implementation `delivery-team` run. With Sonnet or Haiku for generators and Opus reserved for the orchestrator and evaluator, the delta is meaningful but not prohibitive. On bounded problems with clear eval surfaces, the decision-quality gain pays for it.

### Consistent comms via spec projection

`delivery-team`'s Stage 5 launches Marketing, GTM, and CX/Support agents in parallel to produce launch artifacts. Each rediscovers the spec delta independently. `flow-narrator` reads the spec delta once and projects it into whichever audience tier is asked for, from the same source — changelog + ship record by default, wider tiers on request. Consistency is structural, not editorial.

A spec amendment that adds rate limiting becomes a changelog entry, a sales note about "now supports controlled-burst customers," and a support doc on the new 429 status code. All derived. Never authored ad-hoc. Never out of sync with what shipped.

### Structural institutional memory

`delivery-team` archives the adversarial PM review at gate-close. Nothing watches it afterward. `flow` writes every dissent to `efforts/{slug}/dissents-active.yaml` with explicit reactivation conditions — for example, "the stability reviewer argued this breaks if request volume exceeds 10x baseline; flag if `req-throughput > 10x` enters the spec." `flow-dissent-monitor` runs on every commit and surfaces matching dissents as check findings.

The pattern is designed to compound. The first three efforts produce no surfaced dissents — the registry is warming up. By effort five or six, it should begin rediscovering objections that human teams routinely forget. That's the expectation, not an observed outcome. `flow` is new; no effort has yet reached that range.

### End-to-end optimization is unblocked

`delivery-team`'s 13 statically wired agents cannot be optimized as a system. There is no end-to-end metric to train against. `flow`'s pipeline is structurally a DSPy-compatible program: predictor modules, tool calls, control flow, metric. Whether or not you ever run the optimizer — Optimas, MIPRO, GEPA — the option is architecturally available. The system can be measured as a single function from problem to ship.

### No close ceremony, no false closure

`delivery-team` runs `dt-close` at the end of every sprint, producing a summary and a retro. Sprints close on the calendar, even when the work hasn't reached a natural stopping point. `flow` has no `flow-close` and no `flow-retro`. An effort transitions to `shipped/` when a variant passes the ship gate — clean, or gated with watches armed. The retro function is absorbed into the cull cycle — every generation produces a diff between predicted and actual eval scores, so learning becomes structural rather than ceremonial.

Most "close" rituals manufacture closure on work that should remain open, and re-open it implicitly the next sprint. `flow` doesn't manufacture closure.

## What you don't get (anti-features)

Five things `flow` deliberately omits. Each absence is research-flagged.

- **No parallel writes.** Generators run in parallel but write only to their own variant directories. Only `flow-ship` promotes a single survivor to the working tree.
- **No purely evolutionary search.** AlphaEvolve works on well-defined computable objectives. Product work is partially open-ended. Variants exist within spec-bounded constraint space, not free generation.
- **No automated metric optimization without HITL.** Goodhart's law is real. The human preference-articulator role is non-optional for spec evolution and eval design.
- **No spec-as-source maturity at v1.** `flow` ships at Fowler's level 2 (spec-anchored): specs are primary, code is regenerated on spec change, but legacy paths can be edited directly when conformance tests are intact. Level 3 — spec-only edits — is a future state.
- **No full elimination of role narrative.** Generators get constraint variation (one biased for performance, another for simplicity) but the underlying agent is the same function. Niche differentiation is a runtime parameter, not an identity.

## When to use flow, when to use a lighter mode

`flow` is the right tool when:

- The problem can be written as GWT scenarios plus testable EARS requirements.
- The eval surface is instrument-able — correctness, performance, accessibility have measurable signals.
- The work is bounded enough that running five variants isn't prohibitive.
- You want population-search decision quality and are willing to pay the token cost.

Use spec-only / spec + eval mode, or a conventional session, when:

- The spec genuinely cannot be written precisely (exploratory research, brand-new product surface).
- One obvious implementation exists and independent readings could not meaningfully disagree.
- External dependencies dominate the schedule and population search adds no signal.

The explicit escape hatch: if spec confidence drops below threshold, drop out of the machine — a conventional session, or spec-only mode if the requirements are still worth recording. The mode gate runs both ways.

## How to use it

The lifecycle follows the doctrine spine: **spec → panel → one wide probe generation → cull → chavruta → ship with controls → probe and rule post-ship → narrow redispatch only on evidence.** Skills are user-invoked slash commands; agents are background functions skills dispatch (e.g., `flow-init` dispatches `flow-spec-writer` and `flow-evaluator`). You invoke skills. The orchestrator decides which agents to spawn.

### Prerequisites

Before running any flow skill:

- Claude Code installed and able to read `~/.claude/commands/`
- The `flow` suite installed into `~/.claude/` — run `./install.sh --suite flow` from the repo root (see the root `README.md` for options)
- A working directory — greenfield or an existing codebase with git initialized
- Working familiarity with EARS notation (Easy Approach to Requirements Syntax) — see `context/flow-spec-protocol.md` if unfamiliar
- A purpose paragraph for the effort: what problem you're solving and why

The walkthrough below lists each skill in the order you'd invoke them on a typical effort.

### Phase 1 — Initialize the effort

```
/flow-init <effort-slug> [--from-spec <path>] [--from-delivery-team <effort>]
```

`flow-init` first applies the mode gate — if the scope doesn't warrant full flow, it says so and proposes spec-only or spec + eval instead. For a full-flow effort it asks for a purpose paragraph, the codebase path, your HITL mode, any hard prohibitions, the artifact's real consumers (for the cross-boundary objective), and the weight class. It then writes:

- `spec/spec.md` — initial EARS-formatted executable spec (may be skeletal)
- `spec/constitution.md` — governance: prohibitions, preferences, escalation triggers, weight class, budgets
- `evals/harness.yaml` — eval suite scaffolded with the default dimensions plus the two non-negotiables: dedicated invariant graders and at least one cross-boundary objective (the seam is where the field trial's one commercially costly defect lived)
- `efforts/{slug}/flow-state.yaml` — WIP spread, Pareto front, active dissents, spend tracking
- `.flow-index/` — codebase index for context curation (heavy-class efforts)

Flags: `--from-spec <path>` ingests an existing PRD as the spec seed; `--from-delivery-team <effort>` migrates from a prior sprint-shaped effort.

This step is **not idempotent**. Re-running on an existing effort halts.

### Phase 2 — Evolve the spec

```
/flow-spec <natural-language intent or "amend SR-NNN ..."> | --restructure | --constitution
```

Any time intent changes, route it through `flow-spec`. It refuses vague natural language: user journeys become GWT scenarios (`SCN-{NNN}`), and non-functional intents become derived EARS requirements (`SR-{NNN}`). It versions `spec/spec.md`, writes an entry in `spec/history/`, and triggers a dissent reactivation check — a spec change may match an archived dissent's condition. Every semantic spec round closes with the interpretation panel (next phase); pure-ratification rounds pay for neither a panel nor a generation.

`--restructure` groups SRs without changing semantics. `--constitution` amends `spec/constitution.md` — prohibitions, preferences, escalation triggers, dispatch overrides — which is the only sanctioned way to change governance after init.

The spec is the contract every downstream skill assumes. Skip `flow-spec` and edit requirements ad-hoc, and the chain breaks silently.

### Phase 3 — Author the eval suite

```
/flow-eval [dimension-name] | --add-dataset <dim> <path> | --refine <grader> | --threshold <dim> <value> | --characterize <dim>
```

`flow-eval` populates the per-dimension datasets and graders. Each dimension needs at least one real-world dataset; correctness and security additionally require an adversarial holdout (Goodhart mitigation). Two outputs are non-negotiable before the first cull: dedicated invariant graders and at least one cross-boundary objective. `--characterize` records a grader's score variance so culls can treat within-noise deltas as ties.

Evals are a first-class versioned artifact — and the priority target for spend. Depth is tiered: quick during rounds, deep exactly once at pre-ship, adversarial only on gating dimensions. Measure one judge before spawning a fleet.

### Phase 4 — Panel: probe the spec before building

```
/flow-panel [scope SR-IDs] [--readers <3-5>]
```

Three to five cheap readers independently commit to readings of the spec slice; the diff of their readings locates ambiguity at ~5–8k tokens per reader instead of ~400k per implementation. Divergences route back to `/flow-spec` as amendments. `flow-generate` won't dispatch gen-1 without a panel record. In spec-only mode, this is where the machine stops — build conventionally from the paneled spec.

### Phase 5 — One wide probe generation, then cull

```
/flow-generate [scope SR-IDs or "all"] [--hotfix] [--N <count>]
/flow-cull     [--depth quick|standard|deep|adversarial]
```

`flow-generate` dispatches the **wide probe**: 5–7 parallel generators on heavy/novel scope, 3 on standard, 3 cheap-tier on light. Each gets a distinct constraint bias (default rotation: `maintainability`, `simplicity`, `convention`, plus `security` when scope warrants) and writes to its own variant directory. The population is a spec probe — its decision ledgers and forks are primary output, not just its scores. `--hotfix` bypasses population search entirely and serializes a single variant with a mandatory decision ledger + audit.

`flow-cull` runs the eval suite against each variant (quick depth), computes the Pareto front with a noise floor (within-variance deltas are ties; saturated dimensions don't rank), archives strictly-dominated variants, and flags gated-ship (metastable) candidates. **The cull close is the checkpoint**: chavruta and the ship decision follow immediately.

### Phase 6 — Review, ship with controls

```
/flow-chavruta [variant-id | "spec-change" | "metastable"]
/flow-ship     <variant-id> | --gated | --rollback <ship-id>
```

`flow-chavruta` runs the stability-bias and velocity-bias reviewers against the survivor. **Their disagreement is the deliverable.** The review exits at documented disagreement with provisional resolution and explicit reactivation conditions — not at consensus. Dissents append to `dissents-active.yaml`. In the field trial this layer changed shipped code in every repo — best value per token in the system.

`flow-ship` owns the ship gate: named qualitative grounds (never a scalar), one deep eval pass, decision-ledger audit, a **fired revert probe** (the rollback path demonstrated, not assumed), and pre-registered post-ship watches. Then it promotes the variant to the working tree, plans progressive rollout via feature flags, and derives the slim comms bundle (changelog + ship record). `--gated` ships a stable partial-coverage state behind flags with the gaps disclosed and watched. `--rollback` reverts a prior ship by ID.

### Phase 7 — Post-ship: probe and rule, redispatch only on evidence

Post-ship work is spec-side and probe-side — rulings, remedy PRs, probes — with **zero new generations by default**. A new generation needs named evidence: a fired watch, a fork the evals can't discriminate, or a spec delta needing implementation. Then `/flow-generate` dispatches N=1–2 grafting from the shipped variant. Scheduled or confirmation generations are forbidden — the trial priced them at full cost for near-zero movement.

### Cross-cutting skills

These aren't phase-bound. Invoke any time:

- `/flow-pulse [--comms | --verbose | --json]` — read-only state report: Pareto front, ship-gate status, watches, WIP, active dissents. The single status command; a convenience and resume aid, not a decision instrument. `--comms` shows the comms state for the latest ship.
- `/flow-dissent --list-active | --list-reactivated | --check | acknowledge <id> | mitigate <id> --commit <sha> | resolve <id> --reason <text>` — query the registry, run a manual reactivation check, or take action on a surfaced dissent.

## A walkthrough sketch

Illustrative, not a script. A typical full-flow effort ships from its **first** generation. Rough shape:

1. **Init.** `/flow-init customer-portal-rewrite` with a purpose paragraph, the codebase path, and the artifact's real consumers. Mode gate confirms full flow is warranted. Skeletal spec with 3–5 SRs; weight class standard.
2. **Spec authoring.** Two or three `/flow-spec` passes to firm up the GWT scenarios and their derived EARS requirements. HITL counter-prompts vague NL into testable form.
3. **Eval bootstrapping.** `/flow-eval` populates the datasets, authors the invariant graders, and wires a cross-boundary objective against the named consumers.
4. **Panel.** `/flow-panel` spawns 3 readers. They split two ways on SR-007's retry scope — `/flow-spec amend` closes the fork before a single implementation token is spent.
5. **The wide probe.** `/flow-generate` spawns 3 variants (maintainability, simplicity, convention). `/flow-cull` at quick depth reveals two on the Pareto front, one dominated; one maintainability delta is inside the noise floor and named a tie; a decision-ledger fork the suite can't discriminate is routed to `/flow-eval` as a suite gap.
6. **Checkpoint.** The cull close invokes `/flow-chavruta` — one dissent recorded (stability reviewer flags a load-spike condition), non-blocking, reactivation conditions armed.
7. **Ship.** `/flow-ship var-2` walks the gate: grounds named, deep eval pass, ledger audit, revert probe fired in a scratch worktree, watches registered. Variant promoted behind a percentage rollout; changelog + ship record generated.
8. **Post-ship.** Two weeks of rulings and remedy PRs, zero new generations. Then the load-spike watch fires — `/flow-generate SR-007` dispatches N=2 grafting from the shipped variant, with the fired watch as recorded evidence.

The whole cycle is evidence-bound. No sprint number on any of these artifacts — and no scheduled generation, ever.

## State at a glance

`flow-state.yaml` is the single readable state file. Key fields:

| Field | Meaning |
|-------|---------|
| `current-generation` | The active generation number |
| `wip-spread` | Admission cost for new work items (price signal, not cap) |
| `pareto-front` | Best score per dimension across the current generation |
| `metastable-candidates` | Variants qualifying for a gated ship (stable, partial coverage) |
| `spend` | Last generation's estimate vs observed tokens, with a precision tag |
| `active-dissents` | Count; full records in `dissents-active.yaml` |
| `hitl-mode` | `preference-articulator` / `comprehension-auditor` / `reactivation-watch` / `autonomous` |

(Schema 1.0's `convergence-score` and `temperature` fields are retired — ship readiness is `flow-ship`'s gate checklist, not a scalar.)

`/flow-pulse` reads this file and prints a human-readable summary.

## Validating that flow is working

The suite is opinionated. It should be testable.

The 2026-07-28 → 2026-08-10 field trial already ran this test at scale (7 efforts, ~37 generations, ~144 variants, 16 ships, with a conventional control) — its verdict is what the operating doctrine encodes. For future validation, watch the doctrine's own instruments: did the panel catch forks before generation, did sibling disagreement surface defects the suites missed, did any post-ship watch fire on something the gate should have caught. Use the data, not intuition.

Two limits worth naming up front. Fourteen days is too short to measure long-term comprehension debt. The dissent registry's value is cumulative — it won't show up until effort five or six. Plan a re-measurement at 90 days and across multiple efforts before drawing firm conclusions.

## Related reading

- `README.md` — concise suite manifest (skills, agents, state model)
- `context/flow-operating-doctrine.md` — the field-evidence run shape: mode gate, three modes, the spine, the ship gate
- `context/flow-philosophy.md` — the six principles in dense form with citations
- `context/flow-state-model.md` — full `flow-state.yaml` schema and directory layout
- `context/flow-spec-protocol.md` — EARS authoring, spec evolution, conformance tests
- `context/flow-eval-protocol.md` — eval suite structure, multi-objective Pareto, metastable detection
- `context/flow-dispatch-rules.md` — dynamic complexity-based dispatch and the canonical generator-count rules
- `context/flow-dissent-protocol.md` — dissent object schema, reactivation conditions, monitor behavior
- Research provenance: the sources behind the six principles are listed in the "Research provenance" table in `README.md`
