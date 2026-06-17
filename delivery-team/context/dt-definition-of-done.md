# Definition of Done — delivery-team

These criteria apply to every story completed by the delivery-team suite. A story cannot transition to `done` in `sprint-status.yaml` unless all blocking criteria pass. Advisory criteria produce findings in `qa-gate.md` but do not block transition.

The Scrum Master enforces this definition by parsing `qa-gate.md` content — not merely checking for the file's existence.

---

## Blocking Criteria (All Stories)

### 1. Acceptance Criteria — 100% Coverage
- Every AC in `story-{id}.md` has a corresponding test at the appropriate level (unit, integration, or E2E).
- AC statements use EARS format in story files. QA Tester converts to Gherkin for test scaffolding.
- No AC may be marked "not testable" without a written justification in `qa-gate.md` approved by the Scrum Master.

### 2. TypeScript Strict Mode
- Zero TypeScript errors in strict mode on all new and modified files.
- No `any` type. No `@ts-ignore` without a comment explaining why.
- Verified via `tsc --strict --noEmit` in CI.

### 3. Test Coverage — Statement ≥ 80% (New Files)
- Statement coverage on all newly created files must be ≥ 80%.
- Coverage target applies per-story, not per-file individually — a story's total new-file coverage must meet the threshold.
- Advisory, not blocking, if a single utility file is below 80% but the story aggregate passes.
- Coverage tool: Vitest coverage reporter. Coverage report referenced in `qa-gate.md`.

### 4. Linting — Zero Errors
- ESLint passes with zero errors (warnings are advisory).
- Prettier formatting applied to all modified files.
- Verified in CI on the PR branch.

### 5. API Contract Match
- If the story touches any API endpoint covered by `api-contract.yaml`, the implementation must match the contract exactly.
- Response schemas, error codes, and HTTP status codes must match the OpenAPI spec.
- Deviation requires a contract update (bump `x-sprint-version`) before the story can close — not an after-the-fact fix.

### 6. Accessibility Audit — Zero Blocking Violations
- axe-core automated scan passes with zero WCAG 2.2 Level A or AA violations on all new or modified UI components.
- Score target: 0 blocking violations (advisory: 0 violations of any kind is the goal, but Level AAA failures are advisory).
- Applies to all stories with UI output. Backend-only stories are exempt from this criterion.
- Verified via Playwright + axe-core integration in CI or QA Tester's test run.

### 7. Security — No High-Severity Findings
- No high-severity findings from the security review section of `qa-gate.md`.
- Specific checks (always applied to auth-related stories): no plaintext secrets, no raw SQL in route handlers, all user input validated at API boundary with Zod or equivalent, no missing rate limits on auth endpoints.
- Medium-severity findings are advisory; they must be documented but do not block the story.

### 8. Linear Issue Updated
- The Linear issue ID in `story-{id}.md` (`linear-id` field) must be updated to reflect the story's current status.
- Stories that transition to `done` must have their Linear issue set to the team's "Done" state.
- Scrum Master (sole Linear writer) performs this sync. Dev agents do not call Linear directly.

### 9. PR Reviewed and Merged
- A pull request exists for the branch (referenced in `ready-for-review.md`).
- PR title follows convention: `{type}({scope}): {story-title} [{story-id}]` (per `context/dt-github-practices.md`).
- PR description includes: summary, story/Linear link, change list, testing plan.
- CI checks pass on the PR branch (verified by QA tester as step 0 of qa-gate).
- The PR has at least one approval (human or designated review agent per project conventions).
- The PR is merged to the main branch (squash-and-merge default) before the story is marked `done`.
- The feature branch is deleted after merge (Scrum Master responsibility).
- Merge strategy per `project-kickoff.md` conventions (squash default, or rebase/merge commit if overridden).

---

## Advisory Criteria (All Stories)

These produce findings in `qa-gate.md` but do not block transition to `done`. However, advisory findings accumulate in the QA Tester's memory (written by the Scrum Master) and become blocking if they recur across 3+ consecutive stories.

- Statement coverage between 70-79% on new files (below 70% is blocking)
- WCAG 2.2 Level AAA violations (Level A/AA remains blocking)
- Medium-severity security findings
- Performance regressions below advisory thresholds (P95 latency increase > 20% vs. baseline)
- Missing or incomplete inline documentation on public functions/methods
- ESLint warnings (not errors)
- PR exceeds 150-line significant-change target (document reason in `ready-for-review.md`)

---

## Design Spec Adherence (Conditional)

Applies only to stories where `design-spec.md` exists and the story modifies or creates UI components.

- **Blocking**: Component renders all interaction states defined in `design-spec.md` (default, hover, focus, active, disabled, loading, error, empty, success where applicable).
- **Blocking**: Design tokens used match the spec (no raw hex values where a token is specified).
- **Blocking**: Responsive breakpoints implemented per spec.
- **Advisory**: Minor visual deviation from spec that does not affect accessibility or usability.

If `design-spec.md` does not exist for a story, this section is skipped.

If the Product Designer has issued a `design-veto.md` on any component, the story is blocked until the veto is resolved. The veto cannot be overridden by the Scrum Master — it requires either the Designer to withdraw it or a human decision via `HITL-needed.md`.

---

## Customization via project-kickoff.md

The default thresholds above can be adjusted for a specific project by adding a `definition-of-done-overrides` section to `project-kickoff.md`. Example:

```yaml
definition-of-done-overrides:
  statement-coverage-threshold: 90    # raises default from 80
  accessibility-target: "WCAG 2.2 AA + Level AAA color contrast"
  additional-blocking-criteria:
    - "No console.log() in production code (zero tolerance)"
    - "All database queries use parameterized statements (enforced by linting rule)"
```

Overrides are additive or stricter — they cannot lower the blocking thresholds below the defaults defined here.

---

## Operator-Artifact ACs

A cross-cutting pattern that applies to any story whose acceptance criteria require a deliverable that is neither code nor prose. This section is the canonical reference. Per-agent prompts and shift-left review (`dt-story-review.md`) cite this section rather than embedding the rule.

### Definition

Classify every AC's deliverable into one of three categories:

- **(a) code / fixture / config** — implementation-side deliverable. Standard QA verification applies (tests, lint, type-check, coverage).
- **(b) prose / documentation** — text in a named file (SKILL.md, README, docs/, decision document narrative). Standard QA verification applies (review for accuracy, link integrity, placement).
- **(c) operator artifact** — a signed-off table, named PR comment, named sign-off URL, or external review citation. The artifact is *itself* the AC's deliverable. Production of the artifact requires a human PM action that the dev agent cannot self-perform.

Category-(c) ACs are the failure surface this section guards. The recurring failure mode is the dev agent treating the artifact as deferrable rework and opening the PR with a TBD placeholder where the signed-off output should be.

### Two-Stage Gate

Every category-(c) AC enforces a two-stage gate:

- **Stage 1 — BEFORE PR-open**: the dev agent populates the artifact's analysis side completely. Tables have rows, comments have content, decision documents have rationale. **Zero TBD rows / zero TBD fields at PR-open.** What is left for Stage 2 is the *PM judgment column*, not the analysis.

- **Stage 2 — BEFORE merge**: the PM reviews the populated Stage 1 output, upgrades each row's `pm-judgment` from `Proposed-Accept | Proposed-Review` to `Accepted | Defer | Rejected`, and posts the sign-off as a PR-comment URL. The PR description names that comment URL. The PR cannot merge until every row is `Accepted` (or `Defer` with explicit deferred-to-sprint annotation).

The two stages are sequential. Stage 1 is dev-agent work; Stage 2 is PM work. The gap between them is the PR review window.

### Worked Examples

The three S18 outcome shapes — battle-tested at scale across six operator-artifact ACs in five stories with zero first-pass artifact-deferral FAILs:

#### Accept-as-proposed

Most common shape. PM reviews Stage 1 and signs off without revising the proposed values.

**Example shape**: a story whose AC asks the dev agent to score historical data against a new heuristic.

The dev agent scores the sample, populates a decision table with `pm-judgment` proposals (e.g. `Proposed-Accept` on most rows, `Proposed-Review` on a marginal row), and opens the PR with zero TBDs. At Stage 2 the PM upgrades all rows to `Accepted` — no design revision, no value tuning. The heuristic ships as proposed.

#### Accept-with-revision

PM accepts the design but tunes a specific value at Stage 2. Dev follows up with a focused rework commit applying the revision; the decision document Stage 2 block records the change.

**Example shape**: a story whose AC asks the dev agent to set a retention/sizing policy value.

The dev agent proposes `rolling-window-cap: 365` with rationale and a trade-off table, opening the PR with zero TBDs. At Stage 2 the PM accepts the bounded-retention design but tunes the value: `365 → 400`. A single atomic rework commit lands the revision across config, code, and fixtures. The decision document's `pm-judgment-stage-2` block records the revised value, the rationale, and the rework commit reference. The PR merges with the PM-revised value, not the dev-proposed value.

#### Mid-flight pivot

Dev agent commits Stage 1 under documentary triangulation (the dispatched subagent lacks an MCP tool the orchestrator does have). The orchestrator runs the live evidence post-hoc; if it diverges from the triangulation, the orchestrator dispatches a focused pivot rework BEFORE Stage 2. PM reviews and accepts the pivoted state.

**Example shape**: a story that must reconcile against a project-management tool's workflow states, where the dispatched subagent lacks the MCP tools to inspect them.

The dispatched dev subagent does not have `list_issue_statuses` / `list_issue_labels` MCP tools registered. Per the documentary-triangulation escape-hatch, the subagent commits to **path (c)** — a label-only fallback. Post-hoc, the orchestrator (which does have project-management MCP access) runs the live queries and finds the assumed state already exists as a real workflow state, while the assumed label does not exist. The path commitment pivots **(c) → (a)** in a focused rework commit. At Stage 2 the PM accepts path (a) and the tool-canonical state name as-is. The PR merges on the pivoted path. Both the original triangulation commit and the pivot commit remain in PR history; the decision document captures the full chain. See `dt-run.md` § Tool-Gap Recovery Pattern (and the canonical pattern reference `context/dt-tool-gap-recovery.md`) for the full named recovery procedure.

### Bounded Fallback

Applies when Stage 2 review threatens an open-ended tuning loop. Worked example: an AC asks the dev agent to ship a detector with a quality gate, and Stage 2 rejects most of the proposed threshold rows.

> **IF >50% of rows are `Rejected` on first review** (i.e., 3 or more of 5 rows marked `Rejected`), the dev agent SHALL halt detector tuning and escalate to HITL with the recommendation to **descope the detector to documentation-only for the current sprint**:
>
> - Ship the analysis content as guidance prose in the documentation surface (already shipped in this PR).
> - Defer the live gate / threshold check to the next sprint.
> - Carry the implementation to the next sprint as a story with refined design informed by the rejection pattern.
>
> This bounds an open-ended tuning loop and prevents indefinite slip on a high-priority story. The current sprint still ships partial value (documentation reference, placeholder threshold) — partial value, no slip.

The bounded-fallback pattern is the named escape for category-(c) ACs whose Stage 2 surfaces a design problem rather than a tuning question. PM agreement on the fallback clause is captured at sprint kickoff (HITL session) or as part of the AC's Stage 2 sign-off if rejection occurs.

### Recovery Shapes

When a dispatched dev subagent commits Stage 1 under documentary triangulation because it lacks an MCP tool the orchestrator does have, the orchestrator runs the live evidence post-hoc. If the live evidence diverges from the triangulation, the orchestrator dispatches a focused pivot rework before Stage 2. The pattern is named.

See `delivery-team/commands/dt-run.md` § Tool-Gap Recovery Pattern (full reference at `delivery-team/context/dt-tool-gap-recovery.md`) for the four-step procedure (subagent triangulation → orchestrator live evidence → focused pivot rework → decision document records the chain) and the path-c → path-a worked example. The recovery shape composes with the Mid-flight pivot worked example above: recovery is the *mechanism*; mid-flight pivot is the *outcome shape* that recovery produces in the two-stage gate framework.

### Anti-Pattern — what is NOT operator-artifact

Not every AC referencing a populated field or human-touched value is category-(c). Pure observability stories — where the artifact is a runtime measurement that the dev agent reads from production data, with PM disposition recorded in the field for downstream analysis but not as a merge gate — are category-(a) or (b), not (c).

**Worked anti-pattern**: consider a pure observability story (e.g. AC-quality calibration monitoring). It populates a `pm-disposition` field in monitoring output for downstream rolled-up analysis. The field IS operator-touched, but it is NOT a merge gate — the field is populated as part of routine monitoring, not as a sign-off blocker on a specific PR. The story has no Stage 2 sign-off requirement; PRs merge on standard category-(a) blocking criteria (tests, lint, coverage). Citing this story's AC structure as category-(c) would over-fire the two-stage gate on routine observability work.

The classification rule: an AC is category-(c) only if **the artifact is the AC's deliverable AND the AC contains explicit operational sequencing language** ("PR opened only after [artifact] is populated", "PR cannot merge until [artifact] is signed off"). Pure observability fields fail the second condition; they are not gates.

### Enforcement Sites

The two-stage gate is enforced at the following points in the delivery suite. Each site reads this canonical section rather than embedding the rule:

- `delivery-team/agents/dt-frontend-dev.md`, `dt-backend-dev.md`, `dt-middleware-dev.md`, `dt-scrum-master.md` — pre-PR check at Stage 1 (dev-agent populates artifact or halts with TODO comment).
- `delivery-team/commands/dt-story-review.md` — shift-left review at story-author time (classify each AC's deliverable type; verify category-(c) ACs include sequencing-clarity language).
- `delivery-team/commands/dt-run.md` § Tool-Gap Recovery Pattern — orchestrator-side recovery when Stage 1 was committed under documentary triangulation.

---

## Story Checklist

Each `story-{id}.md` embeds a DoD checklist derived from the blocking criteria above. The QA Tester verifies against the full criteria in this file, not just the checklist.

Enforced at Gate 4→5 (see `context/dt-pipeline-stages.md`).
