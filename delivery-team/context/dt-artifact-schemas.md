# Artifact Schemas — delivery-team

Canonical schemas for all handoff artifacts. Use these as authoritative templates. Field names are exact — do not rename fields in implementations.

All artifacts use `schema-version: "1.0"` in their front matter until a breaking change increments the major version.

## Sprint Artifact Directory

Sprints are namespaced by **effort** — a named body of work that may span multiple sprints and branches. The directory structure is:

```
sprints/
  efforts.yaml              ← effort registry (maps effort names to metadata)
  {effort}/                 ← effort namespace (kebab-case slug)
    sprint-{N}/             ← individual sprint directory
      sprint-status.yaml
      ...all sprint artifacts
```

Create `sprints/`, `sprints/{effort}/`, and `sprints/{effort}/sprint-{N}/` if they do not exist before writing any artifact.

The `sprints/` directory must be gitignored — add `sprints/` to the project's `.gitignore` if not already present. These are working artifacts, not source code.

### Effort Resolution

When a skill needs to locate the current effort:

1. **Explicit argument** — if the user passes an effort name, use it directly.
2. **`efforts.yaml` lookup** — read `sprints/efforts.yaml` and find the effort with `active: true`. If exactly one is active, use it.
3. **Branch fallback** — run `git branch --show-current`, slugify the result (lowercase, replace `/` and spaces with `-`), and use that as the effort name.
4. **Ambiguity** — if multiple efforts are active and no argument was provided, list them and ask the user to specify.

### efforts.yaml Schema

```yaml
efforts:
  - name: auth-overhaul           # kebab-case slug, used as directory name
    description: "Auth middleware rewrite for compliance"
    active: true                  # only active efforts are candidates for auto-resolution
    created: "2026-03-18"
    branches:                     # informational — branches associated with this effort
      - feat/auth-overhaul
      - feat/session-tokens
  - name: billing-v2
    description: "Billing system migration"
    active: true
    created: "2026-03-20"
    branches:
      - feat/billing-v2
```

### Sprint Path Convention

The canonical sprint path is: **`sprints/{effort}/sprint-{N}/`**

**Project-level files** (stay at project root):
- `.codebase-index/` — codebase index

**Sprint-scoped files** (written to `sprints/{effort}/sprint-{N}/`):
- `project-kickoff.md` — project context for this sprint
- `sprint-status.yaml`, `sprint-plan.md`, `sprint-notes.md`, `dependency-map.md`
- `story-{id}.md`, `story-review-{id}.md`, `story-review-sprint-{N}.md`
- `design-spec.md`, `ux-research-brief.md`, `api-contract.yaml`
- `qa-gate.md` / `qa-gate-{id}.md`, `ready-for-review.md`
- `HITL-needed.md`, `blocker.md`, `design-veto.md`
- `sprint-{N}-summary.md`, `sprint-{N}-retro.md`
- `gate-review-{stage}.md`, `cross-functional-readiness.md`
- `gtm-readiness.md`, `marketing-readiness.md`, `support-readiness.md`
- `launch-tier.md`, `sprint-memory.md`, `prompt-improvements.md`
- `release-plan.md`, `deployment-status.md`, `release-comms.md`
- `release-health-brief.md`, `release-retro.md`

**Effort-scoped files** (written to `sprints/{effort}/`):
- `sprint-memory.md` — cross-sprint memory persists at the effort level, not per-sprint

When reading sprint artifacts, look in `sprints/{effort}/sprint-{N}/`. When writing, always write to `sprints/{effort}/sprint-{N}/`.
