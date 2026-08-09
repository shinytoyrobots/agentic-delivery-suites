# Flow Operator Voice

How every `flow` skill talks to the human operator. This file governs the **operator register** — everything printed to the window or written for human reading. It does NOT govern the **audit register** (`flow-state.yaml`, phase-log, dissent YAML, eval results), which stays dense and precise by design: those artifacts are load-bearing for future agents and post-hoc diagnosis. Two registers, one source of truth. Never dumb down the audit record; never hand the operator the audit record raw.

---

## The closing block (every command, every run)

Every flow command ends its run with a block of **at most 150 words**, structured exactly:

1. **What happened** — one or two sentences, plain English.
2. **What it means** — the consequence for the effort, not a restatement of the mechanics.
3. **Decisions needed** — the HITL items, if any (see §One decision per prompt). "None" is a valid and common entry.
4. **Next step** — the single suggested command, with a one-clause reason.

Evidence and per-variant detail live in artifacts (`summary.md`, eval results, the dispatch log) and are **referenced by path, not inlined**. When an operator wants the deep narrative of a generation, point them at the generation's `summary.md` — never at the phase-log, which is the audit register.

## Jargon translation

Suite terms stay canonical in state files. In operator output, use the plain phrase with the canonical term parenthesized on **every** use — not just the first. Operator sessions are read out of order and resumed cold, so no output may assume the reader saw an earlier gloss; the constant pairing is also what teaches the vocabulary.

| Canonical | Operator output |
|-----------|-----------------|
| Pareto front | "variants still worth keeping (the Pareto front) — no other variant beats them everywhere" |
| chavruta | "paired adversarial review (chavruta)" |
| metastable candidate | "stable and shippable but not covering the full spec (a metastable candidate)" |
| gated ship | "shipped behind a flag with the gaps disclosed and watched (a gated ship)" |
| wip-spread | "system load (wip-spread)" |
| Goodhart signal | "score-gaming risk (a Goodhart signal)" |
| cull | "scored the generation and archived the beaten variants (cull)" |
| dissent reactivation | "a recorded disagreement's trigger condition fired (dissent reactivation)" |
| noise floor | "differences too small for the graders to mean anything (inside the noise floor)" |
| post-ship watch | "a pre-registered condition that, if it fires, triggers action (a post-ship watch)" |
| revert probe | "the rollback path, actually tested rather than assumed (a fired revert probe)" |
| weight class | "the effort's cost/rigor tier (weight class)" |
| decision ledger | "the variant's record of judgment calls the spec left open (decision ledger)" |
| interpretation panel | "a cheap pre-check where several readers independently interpret the spec (interpretation panel)" |

(`temperature` and `convergence-score` were retired by the operating doctrine; if either appears in an old artifact, gloss it as a retired instrument rather than translating it as live state.)

Terms not in the table follow the same pattern: plain phrase first, canonical term in parentheses, every time.

## The cold-reader test

Every operator-register sentence must parse for someone who has never opened `flow-state.yaml` or a
dispatch record. If a sentence needs those files to make sense, it belongs in an artifact referenced
by path, not in the window. This applies to **interim progress updates between agent runs**, not only
the closing block — glossing a term is not enough if the sentence structure stays in the audit
register ("resolved on non-scalar grounds", "inside SENS bands"). Prefer short declarative sentences:
"We checked whether the project has settled enough to ship. It has — comfortably."

## No naked metrics

Any number whose naive reading is wrong is printed **with its correct reading attached**, or not printed at all.

- Wrong: `maintainability: var-2 0.78 vs var-5 0.77 — var-2 leads`
- Right: "on maintainability the two variants are tied — the 0.01 gap is inside the noise floor (differences too small for the graders to mean anything), so it can't justify picking one over the other."

If a metric needs a warning comment in the state file to prevent misreading, it fails this rule in raw form — translate it or omit it. (The retired convergence-score was the canonical offender — its own state-file comment had to warn "do NOT read as 25% to ship.")

## One decision per prompt

Each HITL surface carries exactly one decision. Question first, at most three sentences of context, options with their consequences stated plainly. Never stack multiple pending decisions behind a single prompt or a single `hitl-pending` count dump; if four decisions are pending, that is four prompts (or a list of four one-line items each pointing to its own prompt), presented in priority order.

## Anti-slop

Adopt `pm-skills/context/pm-plain-english.md` **Check B** (vocabulary tells, synonym cycling, over-explanation, trailing participial filler, hedging without committing, uniform rhythm, bullet bloat, relentless positivity) for all operator-register output. Check A (ticket register) does not apply — operator narrative is explanatory, not terse-ticket. Real runs contain trade-offs and unknowns; a closing block with no caveat where one exists is a defect, not polish.

## Scope

| Surface | Register |
|---------|----------|
| In-window text during/after a run; closing block | Operator (this file) |
| HITL prompts (AskUserQuestion or inline) | Operator (this file) |
| `flow-pulse` output | Operator (this file) |
| `USAGE.md`, `README.md` prose | Operator (this file) |
| `generations/gen-{N}/summary.md` | Operator-leaning (curator keeps it plain; it is the human narrative of a generation) |
| `flow-state.yaml`, phase-log, `dissents-active.yaml`, eval results, dispatch log | Audit — untouched by this file |
| `flow-narrator` external artifacts | Already audience-tiered by its own spec; its internal-audience tier follows this file |
