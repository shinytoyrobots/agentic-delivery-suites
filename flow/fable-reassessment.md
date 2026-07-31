# Fable 5 and the flow suite — open considerations

Status as of 2026-07-28: **flow-spec-writer is the only Fable-targeted component** (pilot).
Everything else stays on opus/sonnet. This note records why, what's unresolved, and what a
full reassessment should cover.

## What changed in this pilot

- `flow/agents/flow-spec-writer.md` — frontmatter `model: opus` → `model: fable`
- `flow/commands/flow-init.md` Step 3 — prose invocation `(model: opus)` → `(model: fable)`

flow-init:124's `(model: opus)` annotates flow-evaluator, not the spec-writer, and
flow-spec.md never names a model — both invocation paths inherit the agent's frontmatter.

## Why flow-spec-writer, and not init/spec/eval

The original hypothesis targeted flow-init, flow-spec, flow-eval. Prescriptiveness counts
(step-headers + numbered procedures + MUST/NEVER/BLOCKING markers) said otherwise:

| File | Markers |
|---|---|
| flow-converge | 25 |
| **flow-spec-writer** (agent) | 24 |
| flow-ship | 23 |
| flow-init | 22 |
| flow-orchestrator / flow-generator | 21 |
| flow-spec (command) | 12 |
| flow-eval | 11 |

The command files are mostly mode dispatch; the actual spec authoring — where Fable's
migration guidance says over-prescriptive scaffolding degrades output — happens in the
spec-writer agent. flow-eval was dropped from the Fable target list entirely: least to
gain (lowest prescriptiveness of the candidates), most to lose (see refusal risk below).
It stays in the suite on Opus.

## Open considerations

### 1. The API/frontmatter split — three mitigations don't exist at this layer

`fallbacks: "default"`, `thinking.display: "summarized"`, and `output_config.effort` are
Messages API request parameters. Skill/agent frontmatter carries `model:` and nothing that
touches the request body. Consequences:

- **No refusal fallback.** Claude Code's harness owns refusal handling. A Fable
  `stop_reason: "refusal"` mid-spec-authoring is a dead turn re-run manually — there is no
  opt-in server-side fallback to Opus from a `.md` file.
- **Thinking display is a session/config concern**, not per-skill. Fable turns run minutes
  and default to omitted thinking, so interactive spec sessions can look hung.
- **Effort can't be tuned per-skill** either.

### 2. Refusal risk is concentrated in flow-eval

flow-eval's core job — adversarial dataset authoring, `--adversarial` mode, Goodhart
red-team cases — is the shape most likely to trip Fable's elevated cyber classifiers, and
with no fallback path (above), a refusal there is an operational failure. This is the main
reason flow-eval stays on Opus. Revisit only if (a) the spec-writer pilot shows a clear
quality gain and (b) Claude Code grows a refusal-fallback story.

### 3. Retention gate — check the org, not the repo

Fable requires 30-day data retention; a non-compliant org gets `400 invalid_request_error`
on every request regardless of payload. The gate is the API org behind the active Claude
Code credential, not whether the repo is personal.
**Verify before debugging anything else** when Fable requests fail suspiciously.

### 4. Prescriptiveness — the swap alone may make specs worse

flow-spec-writer remains the second-most step-enumerated file in the suite. Fable's
migration guidance is explicit that prompts written for prior models are often too
prescriptive and reduce output quality — state goal and constraints rather than enumerate
steps. If early Fable specs look worse, suspect the scaffolding before the model. A proper
A/B needs a de-prescriptivized variant of the agent file as a third arm, not just
opus-vs-fable on identical text.

### 5. Model refs live in prose, not just frontmatter

11 prose `(model: ...)` invocation refs exist across flow commands (flow-init ×4,
flow-cull ×3, flow-generate ×2, flow-dissent ×1, flow-ship ×1). Frontmatter alone doesn't
migrate an agent — any future Fable move is a two-place edit minimum per agent. A
reassessment should consider removing the prose pins entirely and letting agent
frontmatter be the single source of truth.

### 6. Eval harness prerequisite

`evals/dt-vs-flow/pricing.yaml` has **no `claude-fable-5` entry** ($10/MTok in, $50/MTok
out as of 2026-07-28 — verify before pinning). `measure.py` correctly voids any run
containing a subagent model with no price entry, so a measured spec-writer run dies
silently until this is added. The harness is otherwise ready: subagents are priced at
their own `resolvedModel` rates, which is exactly what a mixed Opus-orchestrator /
Fable-spec-writer arm needs.

### 7. Cost shape

Fable is 2× Opus per token, and Fable turns run longer at higher effort. The spec-writer
is invoked once or twice per spec change (not fanned out), so exposure is bounded — unlike
flow-generator, where N-way fan-out on Fable would multiply the premium. Any wider
migration should price fan-out components last.

## Recommended full reassessment (future work)

With Fable available, the suite's model assignments deserve a fresh pass rather than
piecemeal swaps:

1. **De-prescriptivize first, then benchmark.** Rewrite the high-marker files
   (flow-converge, flow-spec-writer, flow-ship, flow-init, flow-orchestrator,
   flow-generator) toward goal-and-constraints style, A/B against current text on Opus —
   that's a win regardless of model, and it's the precondition for a fair Fable trial.
2. **Candidate tiers.** Fable where single-agent depth on hard reasoning pays
   (spec-writer, possibly chavruta-pair's dissent quality); Opus for fan-out and
   orchestration (generator, orchestrator, evaluator); Sonnet stays where it is
   (pulse, dissent-monitor, temperature-controller, context-curator).
3. **Keep Fable away from** flow-eval (refusal shape) and flow-generator (fan-out cost)
   until there's evidence.
4. **Measure with the dt-vs-flow harness pattern**: fresh-session validity rule,
   pre-registered predictions, pricing pinned. A session that has read this note cannot
   score the runs.
