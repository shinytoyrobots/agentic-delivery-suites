# Flow Philosophy — Six AI-First Principles

These principles govern the entire `flow` suite. Every skill, every agent, every artifact derives from them. They are not aspirational — they are operational constraints with research-backed evidence. Cite them by number (P1–P6) when justifying design decisions.

---

## P1: Intelligence parallel, writes serial

**Statement**: Multiple agents may read, analyze, score, dissent, search, or generate variants in parallel. Decisions and writes to the canonical codebase must serialize through a single thread with full context.

**Evidence**: Cognition AI's "Don't Build Multi-Agents" (2025) → Devin 2.0 retrospective. Parallel writes accumulate conflicting implicit decisions ("Mario background + non-game-asset bird" failure). Anthropic's 90% multi-agent improvement comes from a lead agent dispatching parallel **readers** that feed back to one decision-maker.

**Implication in flow**:
- `flow-generator` instances run in parallel, but each writes only to its **own variant directory** (`generations/gen-{N}/population/{variant-id}/`).
- Only `flow-converge` promotes a single survivor to the working tree.
- `flow-chavruta-pair` has two reviewer agents producing structured dissent — both reads. Neither writes to code.
- `flow-evaluator` may run multiple grader subagents in parallel — all reads. The composite score is consolidated by a single instance.

**Failure to apply**: parallel `flow-generator` instances modifying shared files; multiple `flow-chavruta` agents committing rework simultaneously; orchestrator delegating writes to subagents.

---

## P2: Dynamic dispatch over fixed roles

**Statement**: Agent count and configuration are functions of task complexity, not fixed by job title.

**Evidence**: Stanford MASS paper (2025): optimizing pipeline topology + prompts beats fixed agent role-play by **78.8%**. Anthropic's explicit dispatch rules: 1 agent for simple tasks, 2–4 for comparisons, 10+ for complex research. Role abstraction is a human cognitive crutch, not an architectural property.

**Implication in flow**:
- `flow-orchestrator` assesses complexity per request and chooses generator count, evaluator depth, whether chavruta is warranted.
- Agents are **function-shaped, not role-shaped**: `flow-generator` is one function with constraint-variation parameters, not separate frontend/backend/middleware roles.
- Niche differentiation (one generator biased for performance, another for simplicity) is a **runtime parameter**, not an agent identity.

**Failure to apply**: spinning up the same N agents regardless of problem; treating "front-end work" as a fixed agent slot.

---

## P3: Spec as source of truth, code as regenerated output

**Statement**: The spec is version-controlled and authoritative. Code is regenerated when the spec changes. Conformance tests bridge them. The spec is **layered**: GWT behavioral scenarios are the primary, product-facing layer; EARS requirements are the derived, normative layer.

**Evidence**: Drew Breunig (Feb 2026); Martin Fowler's three-tier model (spec-first → spec-anchored → spec-as-source); production tools (Tessl, Kiro, GitHub Spec-kit). The `whenwords` library: **zero human-written code, 750 conformance tests, spec-only maintenance**. BDD/Gherkin practice: behavioral scenarios written as Given/When/Then double as acceptance tests — the same examples that specify behavior also grade it (P4).

**Layered specification — scenarios first, requirements derived**:
- **`SCN-{NNN}` — behavioral scenarios (primary).** Given/When/Then descriptions of observable user behavior, each with measurable acceptance criteria. This is the unit of work a human authors and reviews: it keeps the spec anchored to *user value*, not premature system decomposition. Each scenario's acceptance criteria seed the eval datasets directly.
- **`SR-{NNN}` — EARS requirements (derived).** System-centric, parseable. Each SR either decomposes a scenario's criteria into testable constraints (and names its `SCN` parent) or captures a non-functional / ambient requirement — performance, security, cost — that has no user-observable trigger and therefore no scenario parent.
- **Why not pure GWT.** The very dimensions on `flow`'s Pareto front (security, perf, cost) are mostly not user-observable events, so they don't fit Given/When/Then. EARS's ubiquitous and state-driven forms carry them. GWT and EARS are complementary, not competing.

**Implication in flow**:
- `spec/spec.md` is the single source of truth. It contains a **Behavioral scenarios** section (SCN) followed by a derived **Requirements** section (SR) and a **traceability** table. `story-{id}.md` files do not exist.
- Both scenarios and EARS are **load-bearing**, not advisory. Every scenario acceptance criterion and every requirement is testable.
- `flow-generate` always reads from `spec.md`. It never reads from prior implementations except as architectural context.
- When a spec changes, prior code is **regenerated**, not patched, unless the change is purely additive (new requirement, no existing requirement modified).
- Default maturity level for `flow` v1: **spec-anchored** (level 2 of Fowler's hierarchy). Specs are primary; legacy code paths can be edited directly when conformance tests are intact. Level 3 (spec-only edits) is a future state.

**Failure to apply**: editing code without updating the spec; allowing prose stories to be the work unit; specs that aren't testable.

---

## P4: Multi-objective Pareto evaluation over single-threshold gates

**Statement**: Quality is a vector. Pareto fronts replace single-threshold gates. Feature flags + A/B testing extend evaluation past the deploy line.

**Evidence**: Optimas (Stanford, ICLR 2026): globally aligned local rewards prevent Goodhart-gaming. Anthropic eval engineering: 20–50 realistic tasks beat hundreds of synthetic ones. evaldriven.org: eval = dataset + grader + harness, all versioned.

**Implication in flow**:
- `evals/` is a first-class versioned artifact. Eval suite is part of the spec contract.
- GWT scenarios (`SCN-{NNN}`) are the direct source of graded examples for the **correctness** dimension: each scenario's acceptance criteria become 2–4 dataset tasks. The product spec and the eval suite are the same artifact viewed two ways (P3).
- Every variant in a generation gets a **multi-dimensional score**: correctness, performance, maintainability, accessibility, security, cost. No single "quality score."
- `flow-cull` operates on the **Pareto front** — variants that dominate (better on at least one axis, no worse on others) survive. Variants strictly dominated are archived.
- **Metastable states** (high stability, partial spec proximity) are first-class ship candidates, not work-in-progress.
- Goodhart mitigation: every numeric metric is paired with at least one adversarial holdout dataset and one human-judgment dimension.

**Failure to apply**: collapsing the eval to a single score; gating on a fixed threshold (e.g., "80% coverage"); ignoring metastable states.

---

## P5: Continuous flow over time-boxed cycles

**Statement**: Work flows from problem to convergence without arbitrary time boxes. The unit of work is a generation that converges, not a sprint that ends.

**Evidence**: Kanban literature on flow vs cadence; AlphaEvolve operational data ("days of automated experiments"); market-maker spread analogy from continuous-distribution finance.

**Implication in flow**:
- No sprint number. The directory is `efforts/{effort-slug}/generations/gen-{N}/`, not `sprints/sprint-{N}/`.
- WIP regulated by `wip-spread` (admission cost rising with inventory), not WIP cap.
- Convergence (inter-variant similarity above threshold) is the exit condition. Not calendar time.
- No "close" ceremony. The effort transitions to `shipped/` when convergence is reached or a metastable variant is promoted.

**Failure to apply**: invoking calendar-based skills; treating sprints as a planning horizon; cutting work to fit a time box.

---

## P6: Preserved dissent with reactivation conditions

**Statement**: Disagreement during review is recorded as a structured object with explicit conditions under which the minority position would become correct. A monitor watches for reactivation triggers.

**Evidence**: Talmudic chavruta pattern (yeshiva paired study); MASFT failure taxonomy (UC Berkeley, ICLR 2025) on institutional memory loss in long-running agent suites.

**Implication in flow**:
- `flow-chavruta-pair` exits not at consensus, but at **documented disagreement with provisional resolution and explicit reactivation conditions**.
- Dissents are stored in `dissents-active.yaml` at the effort level — append-only across generations.
- `flow-dissent-monitor` watches each commit for triggers matching archived reactivation conditions.
- A reactivated dissent is **not a veto** — it surfaces as a check finding that requires acknowledgment (accept the trade-off, mitigate, or pivot).

**Failure to apply**: closing review at consensus; discarding the minority position; treating disagreement as a problem to resolve rather than information to preserve.

---

## How the principles interact

These are not independent axioms. They reinforce each other:

- **P1 + P2**: Dynamic dispatch (P2) without serialized writes (P1) produces conflicting decisions (Cognition's Mario/bird).
- **P3 + P4**: Spec as truth (P3) is necessary for Pareto evaluation (P4) — you cannot score "correctness" without a precise spec.
- **P5 + P4**: Continuous flow (P5) requires multi-objective evaluation (P4) — there's no gate to advance through.
- **P6 + P3**: Dissent preservation (P6) requires a stable spec (P3) for reactivation conditions to remain testable.

## When to violate

The principles are defaults, not laws. Violations should be:

1. **Explicit** — declared in `spec/constitution.md` or in the skill invocation
2. **Justified** — the reason is recorded
3. **Bounded** — the violation is scoped (one effort, one generation, one decision)
4. **Reversible** — there's a path back to principle-conformance

Examples of legitimate violation:
- Critical security patch: bypass population search; single-variant fast path (violates P5 on time)
- Spec genuinely cannot be written precisely: drop to `delivery-team` story mode (violates P3 explicitly)
- Adversarial review consensus is genuinely available and useful: collapse chavruta to single reviewer (violates P6 case-by-case)
