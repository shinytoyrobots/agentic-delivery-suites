---
description: "Author or edit the multi-objective eval suite. Add/refine dimensions, datasets, graders, thresholds. Goodhart-mitigation via real + adversarial datasets per dimension."
argument-hint: "[dimension-name] | --add-dataset <dim> <path> | --refine <grader> | --threshold <dim> <value>"
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
capability-class: planning-design
tier: II
domain: [flow]
works-with:
  requires-context: [flow-eval-protocol, flow-state-model, flow-philosophy, vault-access]
  upstream-skills: [flow-init, flow-spec]
  downstream-skills: [flow-generate, flow-cull]
  compatible-agents: [flow-evaluator, flow-spec-writer]
readiness:
  state: green
  idempotent: false
  warm-start: true
cost:
  model-class: high
  agent-count: 2
  web-calls: none
  context-budget: medium
---

# Flow Eval

Read context files:
- `~/.claude/commands/context/flow-eval-protocol.md`
- `~/.claude/commands/context/flow-state-model.md`
- `~/.claude/commands/context/flow-philosophy.md`
- `~/.claude/commands/context/vault-access.md`

## Purpose

Author, refine, or extend the eval suite. The eval suite is part of the spec contract — every SR-{NNN} maps to a (grader, dataset, threshold) tuple. This skill is where graders are written, datasets are bootstrapped, thresholds are set.

GWT behavioral scenarios (SCN-{NNN}) directly seed the `correctness` dimension — each scenario's acceptance criteria become scenario-graded tasks. When `/flow-spec` introduces a new SCN, it flags those acceptance criteria as pending dataset registration; this skill registers the mappings (scenario `tasks:` and any `derived-requirements:` entries) in `harness.yaml`.

## Modes

### Mode 1: Bootstrap a dimension

```
/flow-eval bootstrap correctness
```

Walks through generating an initial dataset and grader for a dimension. Useful right after `flow-init` to populate the empty placeholders. For `correctness`, extracts acceptance criteria from the current SCN-{NNN} in the spec and populates the skeleton dataset with scenario-graded tasks.

### Mode 2: Add a dataset

```
/flow-eval --add-dataset correctness ./fixtures/correctness-real-v2.jsonl
```

Imports an existing dataset file; validates format; registers in harness.yaml.

### Mode 3: Refine a grader

```
/flow-eval --refine accessibility
```

Iteratively improve a grader spec. Test the refined grader against a holdout set; compare scores against the prior version.

### Mode 4: Adjust thresholds

```
/flow-eval --threshold maintainability 0.75
```

Update pass threshold for a dimension. HITL required if change affects already-shipped variants.

### Mode 5: Add a new dimension

```
/flow-eval --add-dimension token-efficiency
```

Introduces a new objective dimension. Walks through grader spec, dataset bootstrap, threshold setting, and Pareto-front weights.

### Mode 6: Add adversarial dataset (Goodhart mitigation)

```
/flow-eval --adversarial correctness ./fixtures/correctness-adv-v2.jsonl
```

Specifically tags a dataset as adversarial; per harness policy, variants must pass on both real and adversarial to claim the dimension.

## Procedure

### Step 1: Read state

- `evals/harness.yaml`
- `evals/graders/`
- `evals/datasets/`
- `spec/spec.md` and `spec/constitution.md` for context

### Step 2: Mode-specific work

**Bootstrap dimension**: Invoke `flow-evaluator` (design mode). It produces a grader spec template based on the spec context. The user iteratively refines via AskUserQuestion prompts. A skeleton dataset is generated (5-10 seed tasks) that the user can extend. For `correctness`, extract the acceptance criteria from the current SCN-{NNN} in the spec and populate the skeleton with scenario-graded tasks (2-4 per scenario) rather than starting from blank seeds.

**Add dataset**: Validate format (JSONL with expected schema for the dimension). Register in harness.yaml. If the new dataset supersedes an existing version, mark prior version as `superseded-by` and keep it in version history.

**Refine grader**: Diff the prior grader vs. the proposed refinement. Run both against a holdout test set if available. Report score differences. HITL approval before committing the refinement.

**Adjust threshold**: Check if any already-shipped variants would have failed the new threshold. If yes, HITL preference-articulator mode (this is a re-eval that may invalidate prior decisions).

**Add dimension**: Big change. HITL required. Define grader, dataset (real + adversarial), threshold, weight, SR mapping if applicable.

**Add adversarial dataset**: Validate it's actually adversarial (samples should differ meaningfully from real-distribution samples). Register with `kind: adversarial` flag.

### Step 3: Update harness.yaml

Bump suite version per change type:

- Additive (new dataset, new dimension): minor bump
- Refinement (existing grader/dataset improved without re-tagging): patch bump
- Replacement (grader replaced, dataset replaced): major bump → HITL required + prior variants re-eval

### Step 4: Re-evaluation policy

Refinement: prior variants in the current generation are re-evaluated automatically. Variants from prior generations are not re-evaluated unless explicitly requested.

Replacement: HITL required. Prior eval results are invalidated. Decision: re-eval all shipped variants, or accept the previous evals as historical record.

### Step 5: Goodhart self-check

After any change, run a self-check:

- Is at least one adversarial dataset required for each numeric dimension?
- Are any dimensions missing real + adversarial pairing on `correctness` or `security`? (Constitution-required by default.)
- Is the score-climb-flag-threshold sensible (default 0.30)?

Surface gaps. Suggest fixes.

### Step 6: Write

1. Update `evals/harness.yaml`
2. Write new/refined grader specs to `evals/graders/{dimension}.md`
3. Place new datasets in `evals/datasets/`
4. Append to `flow-state.yaml.phase-log`

### Step 7: Report

Return:
- Suite version (before → after)
- Changes (dimensions / datasets / graders modified)
- Re-eval status (none / triggered-current-gen / triggered-all-shipped)
- Goodhart gaps surfaced

## Outputs

| Path | Action |
|------|--------|
| `evals/harness.yaml` | Updated |
| `evals/graders/{dimension}.md` | Created / updated |
| `evals/datasets/{dimension}-{real|adv}-v{N}.jsonl` | Created / updated |
| `efforts/{effort}/flow-state.yaml` | Phase-log appended |

## HITL surface

- Threshold change affecting shipped variants: full diff + approval
- Dimension addition: grader/dataset/threshold/weight review
- Grader replacement: side-by-side score comparison + approval
- Constitution-required dimension removal: explicit override required

## Failure modes

- Dataset fails validation: halt; report schema mismatch; suggest fix
- Adversarial dataset is too similar to real dataset: warn; offer to proceed with reduced Goodhart protection
- Grader refinement produces scores that invalidate a recently-shipped variant: HITL with proposed action

## Idempotency

Re-running with identical input produces a no-op. Re-running with a new version of the same dataset increments the suite version even if the change is minimal.

## Examples

### Bootstrap correctness for a fresh effort

```
/flow-eval bootstrap correctness
```

Walks through: grader spec → 5 seed real tasks → 3 seed adversarial tasks → threshold default 0.95.

### Add adversarial cases after a Goodhart signal

`flow-evaluator` flagged a Goodhart signal on `performance`. You generate new adversarial cases:

```
/flow-eval --adversarial performance ./fixtures/performance-adv-v3-postgoodhart.jsonl
```

Suite version bumps; next eval depth defaults to adversarial for performance dimension until the signal clears.

### Add cost dimension

```
/flow-eval --add-dimension cost
```

Defines: grader = token-counter, datasets = harness-tracking only (no separate dataset needed for cost), threshold = budget per generation, weight = 0.10.
