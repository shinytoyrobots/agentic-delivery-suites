# Flow Dissent Protocol

How disagreement is preserved as a first-class artifact. The chavruta principle (P6) made operational.

---

## The premise

Code review aimed at consensus discards information. When two competent reviewers disagree, the disagreement itself is signal about the problem space — not noise to be resolved. The Talmud preserves minority rulings because a "defeated" argument may become the correct ruling under different conditions. Human teams cannot maintain that institutional memory at scale. Agent suites can.

**The dissent record is append-only, queryable, and self-surfacing when conditions change.**

---

## Dissent lifecycle

```
[chavruta-pair review]
       ↓
   raised → active → (reactivation triggered) → reactivated → acknowledged | mitigated | resolved
```

| Status | Meaning | Who sets it |
|--------|---------|-------------|
| `active` | Disagreement recorded; provisional resolution applied; waiting for triggers | `flow-chavruta` on creation |
| `reactivated` | A reactivation condition matched; the dissent needs attention | `flow-dissent-monitor` |
| `acknowledged` | Human or orchestrator reviewed the reactivation; the trade-off remains valid; no code change | `flow-dissent` skill |
| `mitigated` | Code was modified to address the dissent; trigger conditions should no longer match | `flow-dissent` skill |
| `resolved` | Dissent is formally retired (spec change made it moot, or it was wrong) | `flow-dissent` skill |

Status is monotonic: dissents can move forward through the lifecycle, never backward. A resolved dissent that becomes relevant again is **a new dissent**, citing the resolved one.

---

## Dissent object schema

Stored in `dissents-active.yaml` at the effort level.

```yaml
- id: "dissent-{YYYY-MM-DD}-{NNNN}"     # Date + 4-digit ordinal
  raised-at: "2026-05-13T11:30:00Z"
  raised-by: "flow-chavruta-pair / stability-bias"
  generation: 4
  context: |
    Brief description of the situation that prompted the dissent.
    Reference to the variant or spec change being reviewed.
  position: |
    The minority position. State it as if you believed it.
    Include the reasoning, not just the conclusion.
  counterposition: |
    The provisionally-accepted majority position.
    Symmetric structure — state it as if you believed it.
  provisional-resolution: |
    Which position won this round, and the rationale.
  reactivation-conditions:
    - type: spec-change
      trigger: "Description of the spec change pattern"
      match: "spec.md contains 'rate limit' OR 'throttle' (case-insensitive)"
      check: regex                     # regex | structural | code-pattern | metric
    - type: code-change
      trigger: "Description of the code pattern that would invalidate the resolution"
      match: "grep -c 'withRetry' src/ > 3"
      check: shell
    - type: metric
      trigger: "Eval-front shift"
      match: "performance score on this variant drops below 0.75"
      check: eval-result
    - type: time
      trigger: "Re-evaluate periodically"
      match: "spec semver major increment OR every 90 days"
      check: semantic
  status: active
  last-checked: "2026-05-13T14:22:00Z"
  reactivation-count: 0                # Number of times this dissent has been reactivated
  history:
    - "2026-05-13T11:30:00Z raised by chavruta-pair gen-4 convergence checkpoint"
```

---

## Reactivation condition types

### `spec-change`
Match against `spec.md` content (regex or structural). Checked on every spec version increment.

```yaml
reactivation-conditions:
  - type: spec-change
    trigger: "If the spec adds requirements around audit logging, this dissent is relevant"
    match: "SR-.* (audit|log retention|compliance)"
    check: regex
```

### `code-change`
Match against the working tree. Checked on every commit to the effort branch.

```yaml
reactivation-conditions:
  - type: code-change
    trigger: "Multiple callsites of inline retry indicate middleware was the right call"
    match: "grep -rc 'await withRetry' src/ | awk '{sum+=$NF}END{print sum}' "
    check: shell
    threshold-operator: ">"
    threshold-value: 3
```

### `metric`
Match against eval-front state. Checked on every generation's evaluation completion.

```yaml
reactivation-conditions:
  - type: metric
    trigger: "If performance regresses below threshold, the simplicity bias may have cost more than expected"
    match:
      dimension: performance
      variant-tag: simplicity-bias-survivors
      operator: "<"
      value: 0.75
    check: eval-result
```

### `time`
Periodic re-evaluation. Useful for assumptions that depend on external context (regulatory, business posture, market).

```yaml
reactivation-conditions:
  - type: time
    trigger: "Re-evaluate at every major spec version, regardless of other triggers"
    match: "spec semver major increment OR 90 days elapsed since last check"
    check: semantic
```

---

## Authoring dissents

Two agents author dissents:

### Primary: `flow-chavruta-pair`

The two reviewers (stability-bias + velocity-bias) generate dissents at convergence checkpoints, major spec changes, and metastable-candidate ship decisions.

A chavruta dissent is **always paired** — both positions are recorded, even if one is provisionally accepted. The chavruta exit condition is *documented disagreement with provisional resolution and explicit reactivation conditions*, NOT consensus.

### Secondary: `flow-evaluator`

When an evaluator detects a Goodhart signal (score climb anomaly) or a metric-design problem (one dimension is dominating in a way that crowds out others), it may raise a methodological dissent. The reviewer position is "the eval suite produced this score, but the score may be misleading."

### Forbidden: any other agent

Generators do not raise dissents. Generators implement; they don't second-guess. If a generator finds the spec ambiguous, it raises a HITL ambiguity flag, not a dissent. Dissents are about decisions, not specifications.

---

## `flow-dissent-monitor` behavior

Runs as a watcher process, triggered by:

- Every spec version increment (checks `spec-change` conditions)
- Every commit to the effort branch (checks `code-change` conditions)
- Every generation eval completion (checks `metric` conditions)
- Daily cron / on every `flow-pulse` (checks `time` conditions)

On match:

1. Set the dissent's `status: reactivated`
2. Append to `history` with the matched condition
3. Increment `reactivation-count`
4. Surface the dissent in `flow-state.yaml.dissents-reactivated`
5. If the dispatch rules require it (constitution override), block the next dispatch and HITL

False-positive management:

- `reactivation-count` is a quality metric on the dissent itself
- If a dissent reactivates >5 times without being mitigated or resolved, `flow-dissent-monitor` flags the dissent as **noisy** and surfaces it for `acknowledged-noisy` status (suppresses surfacing for 30 days; condition is still tracked)
- Noisy dissents are reviewed at major spec versions

---

## `flow-dissent` skill behavior

The `flow-dissent` skill is the human / orchestrator interface to the dissent registry.

Operations:

- `flow-dissent --list-active` — show all active dissents in current effort
- `flow-dissent --list-reactivated` — show all dissents currently in `reactivated` state
- `flow-dissent --check` — force a fresh scan of all conditions (idempotent)
- `flow-dissent acknowledge <id>` — set status to `acknowledged` (trade-off remains)
- `flow-dissent mitigate <id> --commit <sha>` — set status to `mitigated`, record the commit
- `flow-dissent resolve <id> --reason <text>` — set status to `resolved`, record rationale

Status transitions write to `dissents-active.yaml` history.

---

## Cross-effort dissents

The default is **effort-scoped**: each effort has its own `dissents-active.yaml`. Dissents from prior efforts are not surfaced in the current effort.

**Exception**: if `constitution.md` declares cross-effort dissent tracking, `flow-dissent-monitor` also reads `dissents-active.yaml` from sibling efforts and applies their reactivation conditions to this effort's spec + code.

Cross-effort tracking is opt-in because the cost is real (more conditions to check, more potential false positives) and the value compounds only after multiple efforts have shipped.

---

## When to amend a dissent

Dissents are append-only in their core fields (position, counterposition, provisional-resolution). The mutable fields are:

- `status` (forward-monotonic)
- `last-checked`
- `reactivation-count`
- `history` (append-only)

If the underlying disagreement evolves (the original position needs revision), resolve the old dissent and raise a new one citing it. **Never edit a dissent's position retroactively.** The historical record is part of the value.

---

## Comparison to `delivery-team` adversarial PM pattern

| `delivery-team` Conservative + Aggressive PM | `flow` chavruta-pair + dissent |
|---|---|
| Both PMs produce assessments | Both reviewers produce positions |
| Scrum Master synthesizes a recommendation | Provisional resolution is recorded with reactivation conditions |
| Divergence archived in sprint memory | Dissent is append-only registry, queryable |
| Memory is narrative ("sprint 7 retro noted...") | Memory is structured (regex/metric conditions) |
| Reactivation requires human re-reading the retro | Reactivation is automatic |
| Memory mostly dies at sprint close | Memory persists indefinitely across generations |
| One-shot decision | First-class artifact with lifecycle |

The chavruta pattern is the **operational form of institutional memory**. It is the single feature most likely to compound advantage over time, but the value is invisible until the first reactivation fires.

---

## Failure modes to monitor

1. **Dissent inflation** — every review produces too many dissents, the registry becomes noise. Mitigation: chavruta-pair has a quota (default: 2 dissents per checkpoint max; the most material ones).
2. **Reactivation noise** — overly loose match patterns produce false positives. Mitigation: `acknowledged-noisy` suppression; condition tightening review at major versions.
3. **Dissent staleness** — old dissents about defunct code persist forever. Mitigation: time-based reactivation surfaces stale dissents for resolve/discard.
4. **Authoring asymmetry** — one bias agent dominates dissent authorship. Mitigation: chavruta-pair logs who raised each dissent; over time, imbalance triggers a calibration review.
