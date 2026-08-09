# Flow

An AI-first software delivery suite. Built as the **alternative** to `delivery-team` (its sibling suite in this repo) for head-to-head comparison; operated per `context/flow-operating-doctrine.md`.

**In plain English**: write a precise spec, probe it with cheap parallel readers, generate one wide round of competing implementations, score them from multiple angles, adversarially review the winner, and ship it with tested rollback and pre-registered watches. Costs real tokens (roughly 150k–400k per implementation, tiered by the effort's weight class — see `context/flow-dispatch-rules.md`); skip it for vague or trivially simple work — the mode gate and the full default run shape live in `context/flow-operating-doctrine.md`. The practitioner's guide is `USAGE.md`; operator-facing output across the suite follows `context/flow-operator-voice.md`.

Where `delivery-team` accelerates human Scrum workflows with AI, `flow` is AI-first in philosophy — the pipeline itself is rethought around what LLM agents are uniquely good at and bad at.

## Why this exists

A synthesis of the 2024–2026 compound-AI research literature (sources in the "Research provenance" table below) identified six load-bearing AI-first principles that the `delivery-team` suite either violates or doesn't exploit:

1. **Intelligence parallel, writes serial** — Cognition AI pivot. Parallel writes accumulate conflicting implicit decisions.
2. **Dynamic dispatch over fixed roles** — MASS paper (Stanford, 2025): topology + prompt optimization beats role-play by 78.8%.
3. **Spec as source of truth, code regenerated** — Tessl, Kiro, Spec-kit. Stories drift; specs don't.
4. **Multi-objective Pareto evaluation over single-threshold gates** — Optimas (ICLR 2026). Quality is a vector.
5. **Continuous flow over time-boxed cycles** — The exit is an evidence-gated ship, not the calendar.
6. **Preserved dissent with reactivation conditions** — Talmudic chavruta pattern. Institutional memory becomes structural.

## Core inversions vs. delivery-team

| Concern | delivery-team | flow |
|---------|---------------|------|
| Unit of work | Story (`story-{id}.md`) | GWT scenario (`SCN-{NNN}`) authored/reviewed; generation (population of variants) builds against it |
| Time discipline | Sprint cycle (calendar-bound) | Effort flow (evidence-bound) |
| Quality discipline | DoD thresholds + gates | Pareto front + metastable detection |
| Coordination | Phase-based agent activation | Dynamic complexity dispatch |
| Adversarial review | Conservative + Aggressive PM (consensus required) | Chavruta pair (disagreement preserved) |
| Source of truth | Story file + Linear issue | `spec.md` (SCN scenarios + SR requirements sections) + `evals/` |
| Comms generation | Cross-functional readiness stage | Projection of spec delta at ship, on demand |
| HITL pattern | Pause + resume + 4 calibration levels | Preference articulator + comprehension auditor + reactivation watcher |
| WIP control | Implicit; sprint-bound | Market-maker spread (admission cost) |
| Iteration | Sprint follows sprint | One wide probe generation; redispatch only on evidence (fired watch, eval-blind fork, spec delta) |
| Cost control | None (per-agent, ad hoc) | Weight class sets the dispatch envelope; budgets enforced at admission with recorded actuals |

## The operating doctrine (field-evidence run shape)

A two-week field trial (7 efforts, ~37 generations, ~144 variants, 16 ships) rewrote the default run shape. Value concentrated in the gen-1 population as spec probe, sibling disagreement as defect detection, and the chavruta/dissent layer; refinement generations bought near-zero movement at full price, and evaluation — not generation — was the cost center. The resulting doctrine (`context/flow-operating-doctrine.md`, referenced by every command):

**spec → panel → one wide probe generation → cull → chavruta → ship with controls → probe and rule post-ship → narrow redispatch only on evidence.**

Ships are justified on named qualitative grounds, never a scalar — the convergence metric is retired, replaced by `flow-ship`'s gate (deep eval pass, decision-ledger audit, a FIRED revert probe, pre-registered watches). The temperature parameter is retired with it; `flow-anneal`, `flow-converge`, and `flow-temperature-controller` are archived under `archive/flow/`.

## Three modes

| Mode | Skills | When |
|------|--------|------|
| **Spec-only** | `flow-spec` → `flow-panel` → conventional build; tests bound to SRs | Well-understood scope that still deserves executable requirements and a decision record |
| **Spec + eval** | + `flow-eval` graded conformance; no populations | Graded conformance / CI story without tournament cost |
| **Full flow** | The doctrine spine above | Novel, ambiguous, security-bearing, or hard-to-revert scope |

`flow-spec` standalone is first-class — "the spec is the receipts." The mode gate is step 0 of every effort.

## Weight classes and cost control

Every effort is assigned a **weight class** — light, standard, or heavy — at init. The class sets the dispatch envelope: population width, model tier per generator, evaluator depth, self-check depth, and token budgets. It is a default, not a cage — amendable via the constitution. Light class keeps a real population (three cheap-tier variants) because independent spec readings are the population's probe value; the cost cut comes from model tier and protocol depth, not width.

Three spec probes harden generation regardless of class:

- **Interpretation panel** (`/flow-panel`) — a cheap pre-generation pass where readers summarize the spec independently; divergent readings surface ambiguity before any variant is built (every semantic spec round ends with one).
- **Decision ledger** — every variant records severity-tagged decision points where the spec admitted two readings; culls audit the ledgers, and HIGH-severity entries escalate to HITL.
- **Light path** — an escalation backstop for light-class efforts when the population signals the class was set too low.

Spend is tracked per generation in `flow-state.yaml` (estimate at admission, observed after), with mandatory budget guardrails at dispatch. See `context/flow-dispatch-rules.md` for the full envelope, tier tables, and rules.

## Skills

| Skill | Purpose | When |
|-------|---------|------|
| `flow-init` | Initialize effort: spec, evals, constitution, flow-state | Effort start |
| `flow-spec` | Author/evolve the executable spec — GWT scenarios (SCN) → derived EARS (SR) | Anytime spec changes |
| `flow-eval` | Author/edit multi-objective eval suite | Eval bootstrapping or refinement |
| `flow-panel` | Interpretation panel — cheap parallel readers probe the spec for ambiguity | Closing every semantic spec round, before any generation |
| `flow-generate` | Spawn the wide probe generation (refinement: N=1–2 + graft, on evidence) | After a clean panel |
| `flow-cull` | Score generation with a noise floor, promote survivors, archive losers; closes the checkpoint | After generation completes |
| `flow-chavruta` | Adversarial paired review with preserved dissent | At the cull close, the ship gate, major spec changes |
| `flow-dissent` | Surface reactivated dissents matching new commits | On commit or on-demand |
| `flow-pulse` | Read-only state report (Pareto front, ship-gate status, WIP) | Anytime |
| `flow-ship` | The ship gate: named grounds, deep eval pass, ledger audit, fired revert probe, watches | At the cull close's ship decision |

## Agents

| Agent | Function | Shape |
|-------|----------|-------|
| `flow-orchestrator` | Complexity assessment + dynamic dispatch | Function, not role |
| `flow-spec-writer` | Natural language → EARS → executable spec | Function |
| `flow-evaluator` | Multi-objective scoring; Pareto front; metastable detection | Function |
| `flow-generator` | Single implementation variant; full context single-threaded writes | Function (many instances) |
| `flow-chavruta-pair` | Two opposing-bias reviewers (stability + velocity) | Paired function |
| `flow-dissent-monitor` | Watches commits for dissent reactivation | Function |
| `flow-context-curator` | Context compression, external memory (heavy-class efforts only, on demand) | Function |
| `flow-narrator` | Spec delta → changelog + ship record, on demand (wider tiers on explicit request) | Function |

Agents are **function-shaped, not role-shaped**. There is no "frontend dev" or "QA tester" — there are generators dispatched at the orchestrator's discretion, evaluators that score outputs, and a narrator that produces comms artifacts. Niche differentiation emerges through constraint variation, not fixed identity.

## State model

A `flow` effort has this directory layout:

```
project-root/
  spec/                           # Spec is the source of truth
    spec.md                       # GWT scenarios (SCN-{NNN}) + derived EARS requirements (SR-{NNN}) + traceability table
    constitution.md               # Governance: prohibitions, preferences, escalation triggers
    history/                      # Spec evolution log; append-only
  evals/                          # Multi-objective eval suite, versioned
    datasets/                     # Includes scenario-graded tasks seeded from SCNs
    graders/
    harness.yaml                  # Maps SCN/SR to eval dimensions
  efforts/
    {effort-slug}/                # Named body of work, replaces sprints
      flow-state.yaml
      generations/
        gen-{N}/
          population/             # Implementation variants
          eval-results/
          dissents/
      dissents-active.yaml        # Cross-generation; reactivation conditions
      shipped/
```

`efforts/` and `generations/` are gitignored. `spec/`, `evals/`, and `dissents-active.yaml` are version-controlled.

See `context/flow-state-model.md` for the full schema.

## Supporting context

| File | Contents |
|------|----------|
| `context/flow-philosophy.md` | 6 AI-first principles with evidence |
| `context/flow-state-model.md` | flow-state.yaml schema + directory layout |
| `context/flow-spec-protocol.md` | EARS authoring, spec evolution, conformance tests |
| `context/flow-eval-protocol.md` | Eval suite structure, multi-objective Pareto, metastable detection |
| `context/flow-operating-doctrine.md` | The field-evidence run shape: mode gate, three modes, the spine, the ship gate |
| `context/flow-dispatch-rules.md` | Weight classes, dispatch envelopes, per-bias model tiers, budget guardrails, light path, interpretation panel, decision ledger |
| `context/flow-dissent-protocol.md` | Dissent object schema, reactivation conditions, monitor behavior |
| `context/flow-operator-voice.md` | Operator register: plain-English closing block, per-use jargon glossing |

## Design principles

1. **Intelligence parallel, writes serial.** Many agents may analyze; only one commits.
2. **Spec is source of truth.** Stories drift; specs don't. Code regenerates.
3. **Quality is a vector.** Pareto fronts, not gates.
4. **Convergence is the exit.** No sprints; no calendar.
5. **Memory is structural.** Dissents persist append-only with reactivation conditions.
6. **Comms are derived.** Marketing/sales/support artifacts are functions of spec deltas.

## Anti-features (deliberately not built)

- **No `flow-retro`** — replaced by continuous diff-vs-prediction on every gen-cull cycle
- **No readiness gate stage** — comms are derived continuously from spec deltas
- **No `flow-blocker`** — blockers are first-class dissents with reactivation conditions
- **No `flow-close`** — convergence is the exit; there is nothing to "close"
- **No `flow-status` separate from `flow-pulse`** — one read-only state report
- **No convergence metric** (retired 2026-08) — it was the suite's most-misread instrument; ship decisions run on `flow-ship`'s gate checklist
- **No temperature parameter** (retired 2026-08) — it sat at its floor for the whole field trial; exploration beyond the probe is an explicit operator decision

## Testing this suite

An A/B harness for comparing the two suites. Six metrics, defined before either run:

- Wall-clock time to first shippable variant
- Total token spend
- Human review burden (minutes)
- Eval-front coverage (objective dimensions passing thresholds)
- Defect rate at +14 days post-merge
- Comprehension cost (a maintainer + one other reviewer self-report at +7 days)

`flow` wins if it improves ≥4 of 6 metrics by ≥20% AND no metric regresses by more than 10%.

## Research provenance

| Source | What it contributed |
|--------|---------------------|
| Cognition AI: "Don't Build Multi-Agents" | Intelligence-parallel-writes-serial constraint |
| Anthropic: Multi-agent research system | Dynamic complexity dispatch (1 / 2-4 / 10+) |
| Stanford MASS paper | Topology + prompt optimization beats role-play 78.8% |
| Stanford Optimas (ICLR 2026) | Globally aligned local rewards for compound systems |
| Drew Breunig / Martin Fowler / Tessl / Kiro | Spec-driven development; three maturity levels |
| Google DeepMind AlphaEvolve | Generate-score-select for bounded problems |
| Anthropic eval engineering guide + evaldriven.org | Eval as first-class versioned artifact |
| DORA 2025 AI report | Comprehension as the new bottleneck |
| Talmudic chavruta (lateral leap) | Preserved dissent with reactivation conditions |
| Drug discovery hit-to-lead (lateral leap) | Generation as unit of work; convergence as exit |
| Market maker spread (lateral leap) | WIP price not WIP limit |
| Simulated annealing (lateral leap) | Temperature parameter for exploration↔exploitation (retired 2026-08 on field evidence) |
