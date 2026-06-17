# Flow Eval Protocol

How quality is measured. Evals replace gates (P4). The eval suite is a first-class versioned artifact — part of the spec contract.

---

## Anatomy: eval = dataset + grader + harness

Adopted from evaldriven.org and Anthropic's eval engineering guide.

### Dataset
A set of realistic input tasks with expected outputs (or scoring instructions). Lives in `evals/datasets/{dimension}-{type}-v{N}.jsonl`.

- **scenario-derived** — each GWT behavioral scenario (SCN-{NNN}) is a graded example; its acceptance criteria become 2-4 tasks. E.g. SCN-001 (login) → 3 tasks: valid creds → 200 + session; invalid password → 401; rate-limited → 429 + Retry-After. This source seeds the `correctness` dataset directly from the spec.
- **real** — drawn from actual production incidents, user research, or prior bugs. 20-50 tasks is plenty.
- **adversarial** — crafted to catch known failure modes and metric-gaming. Smaller (10-20 tasks) but high-leverage.

### Grader
A specification of how a variant's output on the dataset is scored. Lives in `evals/graders/{dimension}.md`. The grader is **explicitly versioned** and **independently runnable**.

A grader produces:
- A numeric score (0..1) per task in the dataset
- A pass/fail per task (against a threshold)
- A failure rationale for any failed task

Graders can be **deterministic** (test pass/fail, axe-core violations, lint errors) or **LLM-as-judge** (semantic correctness, design adherence). LLM-judge graders include their judge model and prompt as part of the version.

### Harness
The runner. `evals/harness.yaml` specifies:

- Which graders run on which datasets
- Which SR-{NNN} each (grader, dataset) pair covers
- Thresholds for pass
- Pareto-front configuration (which dimensions; weights for tiebreakers)
- Adversarial-vs-real ratio policy

---

## Dimensions (default)

`flow` ships with 6 default dimensions. Every variant is scored on all 6, regardless of which SRs it emphasizes.

| Dimension | What it measures | Default grader type |
|-----------|------------------|---------------------|
| `correctness` | Variant behavior matches GWT scenarios (SCN-{NNN}) and their derived SR-{NNN} constraints | Deterministic (test execution) + LLM-judge for non-test ACs |
| `performance` | Latency, throughput, resource use against budget | Deterministic (benchmark suite) |
| `maintainability` | Cyclomatic complexity, coupling, readability | Deterministic (cyclomatic + LLM-judge for readability) |
| `accessibility` | WCAG 2.2 AA conformance for any UI surface | Deterministic (axe-core + playwright) |
| `security` | High-severity findings; auth surfaces; secrets | Deterministic (security scanner + LLM-judge for design) |
| `cost` | Tokens to generate + tokens to evaluate, against budget | Deterministic (token counter) |

Constitution may add or remove dimensions. Removing `accessibility` or `security` requires explicit override in `constitution.md` with rationale.

---

## Pareto-front mechanics

Quality is a vector. `flow-cull` operates on the **Pareto front** of variants.

### Definition

Variant A **dominates** variant B if:
- A scores ≥ B on every dimension AND
- A scores > B on at least one dimension

A variant on the **Pareto front** of a generation is one that is not dominated by any other variant in that generation.

### What survives the cull

Default policy (configurable in harness.yaml):
- Variants on the **first Pareto front** survive.
- Variants on the **second Pareto front** survive only if first-front count < 2 (avoid premature convergence).
- All other variants are archived to `generations/gen-{N}/superseded/`.
- **Invariant grader failure is exempt from Pareto logic** — variants that fail an INV-* grader are culled regardless of position. Hard cut.

### Weighting (used only for tiebreakers and reporting)

The Pareto front itself is unweighted — it's a set, not a ranking. But for human reporting and tiebreakers when only one variant can ship, a weighted scalar is computed:

```yaml
weights:
  correctness: 0.35
  performance: 0.15
  maintainability: 0.15
  accessibility: 0.10
  security: 0.15
  cost: 0.10
```

These are defaults. Constitution may override per effort. Sum must equal 1.0.

---

## Goodhart mitigation

Every numeric dimension is paired with an **adversarial holdout** dataset that the optimizer does not see during generation. Variants must score above threshold on **both** real and adversarial datasets to claim the dimension.

Additional mitigations:

1. **Multi-objective by construction** — Goodhart on one dimension is exposed by regression on another.
2. **Human-judgment dimension on critical surfaces** — UX, public APIs, security-bearing code include an LLM-judge dimension calibrated against human reviewers.
3. **Eval-drift detection** — `flow-evaluator` flags when scores rise faster than expected across generations; rapid score climb is a Goodhart signal.
4. **Adversarial dataset refresh** — adversarial datasets are rotated quarterly or on every dissent that names a new failure mode.

---

## Metastable detection

A variant is a **metastable candidate** if it scores high on stability and is locally optimal, even if it does not yet hit full convergence on spec proximity.

Stability components (each 0..1; equal-weighted by default):

- **Test stability** — invariant + correctness grader pass across 5 retest runs
- **Reversibility** — variant uses additive changes only; rollback path exists
- **Blast radius** — how much surface area changes if this variant ships
- **Coupling delta** — variant's coupling score vs. baseline; lower is better

Spec proximity = fraction of spec elements mapped to a passing grader for this variant, counting both SCN-{NNN} scenario graded coverage and SR-{NNN}-mapped coverage.

`flow-evaluator` flags a variant as metastable when:
- Stability ≥ 0.85 AND
- Spec proximity ≥ 0.60 AND
- Variant is on the Pareto front for at least 2 dimensions

Metastable candidates are surfaced in `flow-state.yaml`. `flow-ship` may release a metastable candidate as a feature-flagged early access without waiting for full convergence.

---

## When the eval suite changes

Evals evolve. Three permitted patterns:

1. **Additive** — new dataset or grader added. No effect on prior results. Variants in flight get the new dimension on next evaluation.
2. **Refinement** — existing grader tightened or dataset extended. Prior variants are **re-evaluated** so the Pareto front remains consistent. Tagged `re-evaluated-from-prior-gen` in eval-result.yaml.
3. **Replacement** — grader or dataset replaced. Prior results are invalidated. Tagged `pre-eval-replacement` in superseded.

A replacement always increments the eval suite's version. `flow-spec-writer` requires HITL on any replacement that touches a grader for an SR-{NNN} with prior shipped variants.

---

## Eval ownership and authorship

- `flow-eval` skill is the only writer to `evals/`.
- The skill invokes `flow-evaluator` agent for design work.
- HITL preference-articulator mode is engaged whenever a dimension is added/removed or a threshold is changed.
- Datasets sourced from production incidents must have privacy review noted in front matter.

---

## Running evals

Three depths configurable in `flow-state.yaml.dispatch.evaluator-depth`:

| Depth | What runs | When |
|-------|-----------|------|
| `quick` | Deterministic graders on real datasets only. ~minutes. | Single-variant prototyping; debug iterations |
| `standard` | All graders (deterministic + LLM-judge) on real + adversarial datasets. ~10s of minutes. | Default per-variant per-generation |
| `deep` | Standard + extended LLM-judge passes + reproducibility re-runs (5x sampling on stochastic graders) | Pre-ship; post-major spec change |
| `adversarial` | Deep + active adversarial generation (synthesize new attack cases). ~hours. | On dissent reactivation; on Goodhart signal |

The orchestrator picks depth. Generators do not invoke evals directly.

---

## Comparison to delivery-team's qa-gate

| `delivery-team` qa-gate | `flow` eval suite |
|-------------------------|-------------------|
| Single file, parsed for blocking failures | Per-dimension scores; Pareto front |
| Binary pass/fail | Multi-objective scalar tuple |
| Fixed thresholds (80% coverage, 0 axe-AA, 0 high-sev) | Configurable per dimension; constitution overrides |
| Run once per story before merge | Run per variant per generation, continuously |
| Static dataset (the change under review) | Versioned real + adversarial datasets |
| Failure = block merge | Failure on one dimension = lower Pareto rank; failure on invariant = cull |
| QA agent has veto authority | Evaluator has scoring authority; orchestrator + chavruta decide ship |

The `flow` evaluator is **non-vetoing**. It scores. Decisions are made by `flow-converge` (advance/ship) and `flow-chavruta` (preserved dissent on the decision).
