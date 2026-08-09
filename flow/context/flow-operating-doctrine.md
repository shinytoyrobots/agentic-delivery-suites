# Flow Operating Doctrine

The default run shape, distilled from field evidence rather than design intent. Written
after the 2026-07-28 → 2026-08-10 field trial: 7 efforts, ~37 generations, ~144 variants,
16 ships across five repos, with one conventional control. Every rule below traces to a
measured outcome, not a principle. Where this file and an older habit disagree, this file
wins.

---

## Field verdict (why the doctrine looks like this)

- Value concentrates in three places: the **gen-1 population as spec probe** (default
  biases lost decisively; five wrong readings collapsed to one), **sibling disagreement
  as defect detection** (the highest-consequence defects were invisible to the eval
  suites and caught only by cross-variant comparison), and the **chavruta/dissent layer**
  (changed shipped code in every repo; best value per token in the system).
- Refinement generations bought near-zero score movement at full price.
- **Evaluation, not generation, was the cost center** (1.4–1.6× generation at deep depth).
- Tournaments over saturated suites ranked on instrument noise.
- In-prompt budgets are theater — agents cannot see their own spend.
- The convergence metric was the most-misread instrument in the suite; its
  stability criterion was waived or lineage-read in most real ships.
- Cross-repo seams were ungraded, and that is where the one commercially costly defect
  lived.

Retired on this evidence: the temperature parameter and `flow-anneal` (sat at floor;
reheats never fired), `flow-converge` and the convergence metric (ship criteria moved
into `flow-ship`'s gate; the chavruta trigger moved onto `flow-cull`'s close). Archived
under `archive/flow/` in the skills repo.

---

## Step 0 — mode gate

Full flow is for **novel, ambiguous, security-bearing, or hard-to-revert** scope. For
anything else, a lighter mode is the honest choice — the machine's cost is only justified
where independent readings can genuinely disagree.

| Mode | Skills | When |
|------|--------|------|
| **Spec-only** | `flow-spec` → `flow-panel` → conventional build; tests bound to SRs | Well-understood scope that still deserves executable requirements and a decision record. Proven pattern: five PRs shipped spec-first in one day with no generations — "the spec is the receipts." |
| **Spec + eval** | + `flow-eval` graded conformance; no populations | You want graded conformance / a CI story without tournament cost. |
| **Full flow** | The spine below | Novel, ambiguous, security-bearing, or hard-to-revert scope. |

`flow-spec` standalone is first-class, not step one of the machine.

## The spine (full-flow default)

**spec → panel → one wide probe generation → cull → chavruta → ship with controls →
probe and rule post-ship → narrow redispatch only on evidence.**

1. **Init lean, two non-negotiables:** dedicated invariant graders authored BEFORE the
   first cull, and at least one **cross-boundary objective** grading the artifact against
   its real consumers (the seam is where the costly defect lived).
2. **Every spec round ends with the interpretation panel** (`flow-panel`, 3–5 cheap
   readers). Divergence routes back to `flow-spec`. **Pure-ratification spec rounds do
   not dispatch a generation** — and don't pay for a panel either.
3. **One wide generation.** N=5–7 heavy/novel, 3 standard, 3 cheap-tier light. Bias menu:
   `maintainability`, `simplicity`, `convention`, `security`-when-scope-warrants.
   `reversibility` and `performance` are off the default rotation (0-for-12 combined
   survival in the trial) unless the spec is literally about them. Harvest decision
   ledgers and forks as primary output, not just scores.
4. **Cull with a noise floor:** score deltas within characterized grader variance are
   ties; absent characterization, deltas ≤ 0.01 are ties. Invariants hard-cull.
   Saturated dimensions (every variant at or near ceiling) do not rank.
5. **Chavruta + ship decision immediately after the first cull** — the checkpoint is the
   cull close, not a convergence score. Ship on **named qualitative grounds, never the
   scalar**. The retired stability criterion is replaced by compensating controls (see
   Ship gate).
6. **Post-ship, work spec-side and probe-side:** rulings, remedy PRs, and probes — zero
   new generations by default. The dissent registry stays live.
7. **Redispatch only on evidence** — a fired watch, a fork the evals can't discriminate,
   or a spec delta needing implementation. Then **N=1–2 + graft** from surviving
   variants; decision ledger + ledger audit mandatory at N=1. **Never a scheduled or
   confirmation generation.**
8. **Tier the evals like the dispatch table tiers generators:** quick during rounds,
   deep exactly once at pre-ship, adversarial only on gating dimensions. **Measure ONE
   judge agent's unit rate before spawning the fleet.** Spare tokens go to the verifier —
   holdouts, grader-variance characterization, seam objectives — before width.
9. **External controls:** budgets enforced at admission with recorded actuals
   (in-prompt token caps are removed as a claimed control — agents cannot see their own
   spend); calendar-fixed kill/continue reviews held outside the effort; dispatch pace
   sized to human absorption, not agent throughput.

## Ship gate (what replaced the convergence metric)

`flow-ship` owns the gate. A ship is justified by a checklist, not a score:

1. **Named qualitative grounds** for this variant, recorded in the ship record — what it
   does that the others don't, in behavior terms.
2. Invariants pass; no blocking dissents (acknowledge/mitigate/resolve first).
3. Chavruta has run since the last cull (paired adversarial review is the checkpoint).
4. **One deep eval pass** — the single deep run the tiering budget allows.
5. **Decision-ledger audit** complete; suite-gap findings addressed or explicitly
   accepted.
6. **A FIRED revert probe** — the rollback path demonstrated, not assumed: the reverse
   diff has actually been computed and applied cleanly somewhere disposable.
7. **Pre-registered post-ship watches** — the specific regressions and dissent
   reactivation conditions that would trigger action, written down before ship.
8. HITL approval (always preference-articulator for ship).

**Ship kinds collapse to two:** **clean** (full in-scope coverage) or **gated** (partial
coverage or waived checks, behind flags, with deferred SRs disclosed and watches armed).
"Metastable" survives only as the evaluator's assessment — stable but not covering the
full spec — that qualifies a variant for a *gated* ship.

## What did NOT change

P1 (writes serial, own variant dirs), the pre-spawn hygiene sweep, and the isolation
contract are untouched — correctness properties, not cost knobs. The chavruta/dissent
layer is protected in every cost cut: it was the best value per token in the system.
