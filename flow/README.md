# Flow

An AI-first software delivery suite. **Alternative** to `delivery-team`, designed for head-to-head A/B comparison.

Where `delivery-team` accelerates human Scrum workflows with AI, `flow` is AI-first in philosophy — the pipeline itself is rethought around what LLM agents are uniquely good at and bad at.

## Why this exists

A synthesis of the 2024–2026 compound-AI research literature (sources in the "Research provenance" table below) identified six load-bearing AI-first principles that the `delivery-team` suite either violates or doesn't exploit:

1. **Intelligence parallel, writes serial** — Cognition AI pivot. Parallel writes accumulate conflicting implicit decisions.
2. **Dynamic dispatch over fixed roles** — MASS paper (Stanford, 2025): topology + prompt optimization beats role-play by 78.8%.
3. **Spec as source of truth, code regenerated** — Tessl, Kiro, Spec-kit. Stories drift; specs don't.
4. **Multi-objective Pareto evaluation over single-threshold gates** — Optimas (ICLR 2026). Quality is a vector.
5. **Continuous flow over time-boxed cycles** — Convergence is the exit, not the calendar.
6. **Preserved dissent with reactivation conditions** — Talmudic chavruta pattern. Institutional memory becomes structural.

## Core inversions vs. delivery-team

| Concern | delivery-team | flow |
|---------|---------------|------|
| Unit of work | Story (`story-{id}.md`) | GWT scenario (`SCN-{NNN}`) authored/reviewed; generation (population of variants) builds against it |
| Time discipline | Sprint cycle (calendar-bound) | Effort flow (convergence-bound) |
| Quality discipline | DoD thresholds + gates | Pareto front + metastable detection |
| Coordination | Phase-based agent activation | Dynamic complexity dispatch |
| Adversarial review | Conservative + Aggressive PM (consensus required) | Chavruta pair (disagreement preserved) |
| Source of truth | Story file + Linear issue | `spec.md` (SCN scenarios + SR requirements sections) + `evals/` |
| Comms generation | Cross-functional readiness stage | Continuous projection of spec delta |
| HITL pattern | Pause + resume + 4 calibration levels | Preference articulator + comprehension auditor + reactivation watcher |
| WIP control | Implicit; sprint-bound | Market-maker spread (admission cost) |
| Exploration/exploitation | Implicit; human-managed | Temperature parameter with reheating triggers |

## Skills

| Skill | Purpose | When |
|-------|---------|------|
| `flow-init` | Initialize effort: spec, evals, constitution, flow-state | Effort start |
| `flow-spec` | Author/evolve the executable spec — GWT scenarios (SCN) → derived EARS (SR) | Anytime spec changes |
| `flow-eval` | Author/edit multi-objective eval suite | Eval bootstrapping or refinement |
| `flow-generate` | Spawn a generation of N implementation variants | Generation start |
| `flow-cull` | Score generation, promote survivors, archive losers | After generation completes |
| `flow-converge` | Check convergence; advance generation or ship | After cull |
| `flow-chavruta` | Adversarial paired review with preserved dissent | At convergence checkpoint or on user request |
| `flow-dissent` | Surface reactivated dissents matching new commits | On commit or on-demand |
| `flow-pulse` | Read-only state report (Pareto front, temperature, WIP spread) | Anytime |
| `flow-anneal` | Adjust system temperature (exploration vs exploitation) | On signal: eval plateau, architectural blocker, debt accumulation |
| `flow-ship` | Release with progressive rollout; comms derived from spec delta | Convergence achieved or metastable state selected |

## Agents

| Agent | Function | Shape |
|-------|----------|-------|
| `flow-orchestrator` | Complexity assessment + dynamic dispatch | Function, not role |
| `flow-spec-writer` | Natural language → EARS → executable spec | Function |
| `flow-evaluator` | Multi-objective scoring; Pareto front; metastable detection | Function |
| `flow-generator` | Single implementation variant; full context single-threaded writes | Function (many instances) |
| `flow-chavruta-pair` | Two opposing-bias reviewers (stability + velocity) | Paired function |
| `flow-dissent-monitor` | Watches commits for dissent reactivation | Function |
| `flow-context-curator` | Context compression, external memory, summary references | Function |
| `flow-temperature-controller` | Modulates exploration/exploitation | Function |
| `flow-narrator` | Spec delta → audience-tiered comms (deterministic projection) | Function |

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
| `context/flow-dispatch-rules.md` | Dynamic complexity-based dispatch (1 / 2-4 / 10+) |
| `context/flow-dissent-protocol.md` | Dissent object schema, reactivation conditions, monitor behavior |

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
| Simulated annealing (lateral leap) | Temperature parameter for exploration↔exploitation |
