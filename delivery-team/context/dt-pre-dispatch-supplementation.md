# Pre-Dispatch Live-Evidence Supplementation — delivery-team

Reference document for the proactive supplement pattern used when the orchestrator dispatches a dev subagent against a path-commitment AC that requires live MCP evidence the subagent cannot reach. Cited from `delivery-team/commands/dt-run.md` § Pre-Dispatch Live-Evidence Supplementation.

Proactive pattern for path-commitment ACs that require live Linear (or other MCP) state evidence the dispatched dev subagent does not have direct access to. The orchestrator runs the relevant MCP calls **before** dispatching the subagent and embeds the results inline in the dispatch prompt, so the subagent commits to a path against authoritative live evidence rather than documentary triangulation.

This is the **first line of defense** for the subagent tool-inheritance gap. The Tool-Gap Recovery Pattern (`dt-tool-gap-recovery.md`) remains the **second line of defense** for cases where the supplement was missed at dispatch time or embedded evidence diverges from current state at commit time.

### When to apply

All three conditions hold:

1. The story being dispatched has a **path-commitment AC** (e.g., AC-1 wording: "commit to exactly one path BEFORE T1 proceeds").
2. The path commitment requires **live state evidence** (named MCP calls in the AC — `list_issue_statuses`, `list_issue_labels`, `list_teams`, `list_initiatives`, etc.).
3. The dispatched subagent **does not have direct access** to those MCP tools (named in `tools:` frontmatter of `delivery-team/agents/{agent}.md`).

If any condition is absent, this pattern does not fire. Routine dev work without path-commitment ACs does not require supplementation. Subagents whose `tools:` list already includes the named MCP calls (e.g., dt-release-communicator's read-only Linear surface) call MCP directly — no orchestrator supplement needed.

### Procedure

Three-step pattern:

1. **Identify the live-evidence calls.** Read the dispatched story's path-commitment AC. Extract the explicit MCP tool names referenced (e.g., `mcp__claude_ai_Linear__list_issue_statuses` against a named team).
2. **Run the MCP call(s) in the orchestrator transcript.** Capture the structured response. Keep the call narrow — pull only the fields the AC's path commitment depends on (state inventory; label inventory; initiative tree; etc.). Do not over-fetch.
3. **Embed results as inline evidence in the dispatch prompt.** Include a clearly-labeled `## Live Linear Evidence (orchestrator-supplied)` block immediately above the story body. For each call: tool name, parameters used, timestamp, response payload (full or scoped to relevant fields). Then dispatch the subagent. The subagent treats embedded evidence as authoritative for the path commitment — it does not re-derive via documentary triangulation; it does not assume the evidence may be stale within the dispatch lifecycle.

The decision-document Stage 1 block records the supplemented evidence directly: source (orchestrator pre-dispatch supplement), MCP calls run, timestamp, key findings used to commit the path. The audit trail reads as a single coherent commitment, not a triangulation-then-pivot chain.

### Composition with Tool-Gap Recovery Pattern

The supplement is **proactive** (pre-dispatch); the recovery shape (`dt-tool-gap-recovery.md`) is **reactive** (post-dispatch). They compose:

- **Supplement first.** When a path-commitment AC is identifiable in advance and the dispatched subagent lacks the relevant MCP tools, run the supplement procedure. The subagent commits against live evidence in a single pass.
- **Recovery as fallback.** If the supplement was missed (orchestrator did not recognize the path-commitment AC at dispatch time) OR the embedded evidence diverged from current state between dispatch and commit (rare; Linear state changes mid-dispatch), fall through to the recovery shape. The subagent's documentary-triangulation commit stands; the orchestrator runs live evidence post-hoc; if divergent, dispatches a focused pivot rework.

The two patterns are NOT alternatives — they are layered. Successful supplement means recovery never fires. Missed supplement means recovery is available. Both paths preserve the audit trail; the supplement preserves it more cleanly because there is no triangulation-pivot dance.

### Design rationale: supplement over tool-granting

This pattern (orchestrator supplements evidence pre-dispatch) is preferred over the alternative of granting project-management MCP tools directly to dev subagents, because it: preserves the convention that the Scrum Master is the sole writer to the project-management tool; composes cleanly with the recovery shape rather than short-circuiting it; generalizes across MCP servers without growing every agent's tool list; and keeps dev subagents focused on implementation rather than tool orchestration.

**Revisit clause**: if recovery-shape invocations recur frequently despite the documented supplement pattern — i.e., the supplement step is repeatedly skipped under realistic operating conditions — the structural fix (granting the tools directly) becomes the right choice. Treat repeated recovery firings as the signal to reconsider.

### Operating expectation

A path-commitment AC that requires live project-management evidence SHOULD trigger this pre-dispatch supplement procedure, NOT the live-MCP-pivot recovery shape. Recovery is reserved for genuine missed-supplementation cases. If recovery fires on a routine path-commitment AC where the supplement was applicable, that is a discipline-tax signal worth logging against the revisit clause above.
