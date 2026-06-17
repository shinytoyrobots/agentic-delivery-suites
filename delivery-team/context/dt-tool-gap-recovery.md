# Tool-Gap Recovery Pattern — delivery-team

Reference document for the recovery shape used when a dispatched dev subagent commits under documentary triangulation because it lacks an MCP tool the orchestrator does have. Cited from `delivery-team/commands/dt-run.md` § Tool-Gap Recovery Pattern.

Named recovery shape for the situation where a dispatched dev subagent commits under documentary triangulation (per an AC escape-hatch) because it lacks an MCP tool the orchestrator does have. The orchestrator can run the live evidence post-hoc and dispatch a focused pivot rework. The pattern preserves the audit trail (both commits remain in PR history; decision document records the full chain) and avoids wasted work.

This is a known playbook — not ad-hoc decision-making. If you observe the trigger, follow the procedure rather than re-deriving it.

### When to apply

Both conditions must hold:

1. A dispatched dev subagent committed under documentary triangulation per an AC escape-hatch (e.g., AC-1 language: "if MCP tools unavailable, use documentary triangulation").
2. The orchestrator has access to live evidence the subagent did not (e.g., Linear MCP tools the subagent's tool inheritance did not include).

If only (1) holds — the subagent triangulated and the orchestrator also has no live access — the triangulation stands; this pattern does not fire. If only (2) holds — the subagent had live access and committed normally — there is nothing to recover from.

### Mechanics

Four-step procedure:

1. **Subagent commits under triangulation.** The dispatched dev subagent reaches an AC requiring live evidence; tool inheritance does not include the needed MCP; subagent invokes the AC's documentary-triangulation escape-hatch and commits to a path/value with full reasoning recorded in the decision document Stage 1 block.
2. **Orchestrator runs live evidence post-hoc.** With broader tool access, the orchestrator runs the MCP call(s) the subagent could not (e.g., `list_issue_statuses`, `list_issue_labels`, `list_teams`).
3. **If live evidence diverges from triangulation, orchestrator dispatches focused pivot rework.** Rework is scoped narrowly: update the path commitment, adjust the implementation accordingly, update the decision document. If live evidence confirms the triangulation, no pivot — the original commit stands and the decision document gets a confirmation note.
4. **Decision document records the full chain.** Stage 1 triangulation reasoning + live evidence captured by orchestrator + pivot rationale + final commitment. All four are preserved so the audit trail reads coherently months later.

### Worked example — path-c → path-a pivot

Consider a story whose AC-1 requires a live `list_issue_statuses` call against a project-management tool to determine whether a target workflow state already exists. Three implementation paths are spec'd: (a) use the existing state, (b) create a new state, (c) label-only fallback. The default is path (c).

1. **Subagent triangulation (Stage 1).** The dispatched dev subagent does not have `list_issue_statuses` / `list_teams` / `list_issue_labels` MCP tools registered. Per AC-1's documentary-triangulation escape-hatch, the subagent commits to path (c) — label-only fallback — based on the default and documentary evidence. Full Stage 1 reasoning is recorded in the decision document § Path Commitment.
2. **Orchestrator live evidence (post-hoc).** With project-management MCP access, the orchestrator runs `list_issue_statuses` and receives the full state inventory: the target state already exists as a real workflow state (type `completed`). Independently, `list_issue_labels` returns NO matching label — the label that path (c) required does not actually exist.
3. **Pivot rework dispatched.** The path commitment changes from (c) to (a). Rework is a single focused commit updating: the preflight check (single state-existence check, no label dance), the state-transition step (single `save_issue` transition), the relevant config block, test fixtures, the blocker file (marked RESOLVED), and the decision document § Path Commitment with live evidence + pivot rationale.
4. **Decision document records the chain.** The decision document captures: original Stage 1 path-(c) reasoning, live `list_issue_statuses` and `list_issue_labels` evidence, path (c) → (a) pivot rationale, and Stage 2 PM sign-off accepting path (a). Both commits remain in PR history. The PR merges cleanly.

The original subagent commit was honest within tool constraints — path (c) was the right call for a subagent without MCP access. The pivot was an upgrade to live evidence at the orchestrator layer, not a correction of an error.

### Composition with the pre-dispatch supplementation pattern

The complementary **Path B** — orchestrator runs MCP calls pre-dispatch and embeds live evidence in the dispatch prompt — lives at `delivery-team/context/dt-pre-dispatch-supplementation.md`. This recovery pattern composes with it as the second line of defense:

- **Supplement (pre-dispatch / proactive)** — first line of defense. Orchestrator runs the relevant MCP calls and embeds results as inline evidence in the dispatch prompt. The dispatched subagent treats embedded evidence as authoritative and commits accordingly.
- **Recovery (post-dispatch / reactive — this pattern)** — second line of defense. Fires when pre-dispatch supplementation was skipped, when its embedded evidence went stale between dispatch and commit, or when the subagent encountered an evidence need the orchestrator did not anticipate.

Both patterns preserve the audit trail and avoid wasted work; supplement is the cheaper path when applicable.

### What NOT to do

**Anti-pattern**: orchestrator silently overwrites the subagent's commit (force-push, amend, or fresh branch) without dispatching focused pivot rework and without updating the decision document. This destroys the audit trail and conflates an honest tool-constrained commit with the live-evidence upgrade. The two are separate decisions and should remain separately attributable in PR history.

The recovery preserves both commits AND the decision-document chain so that, months later, a PM reading the PR can reconstruct: (i) what the subagent knew at commit time, (ii) what live evidence surfaced, (iii) why the pivot was correct. That trail is the value; collapsing it is the failure mode.