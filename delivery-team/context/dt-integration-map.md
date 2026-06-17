# Integration Map — delivery-team

Documents how delivery-team's skills connect to each other, and the pattern for connecting delivery-team to any upstream/downstream skill suites you run alongside it.

The governing principle is the **seam rule**: skills integrate through durable artifacts in the docs directory, never through direct cross-suite invocation. An agent writes to its designated path; the next skill (or you) reads from that path. This keeps each suite's context boundary clean and prevents circular dependencies.

---

## The Seam Rule

> No direct cross-suite skill invocations. Only artifact reads at defined paths.

Agents within delivery-team may invoke other delivery-team agents (e.g., the Scrum Master spawns the Frontend Dev as a subagent). They do **not** reach into other suites. Instead:

1. delivery-team agents `Glob`/`Read` artifact paths written by other suites.
2. Other suites `Glob`/`Read` artifact paths written by delivery-team.
3. The user bridges suites by running skills in sequence.

---

## Artifacts delivery-team writes

These are the durable outputs delivery-team produces. Anything you build downstream (status reporting, release-readiness tracking, launch/content workflows) can consume them by Globbing these paths.

| Output | Path | Produced by | Stage |
|--------|------|-------------|-------|
| Sprint completion summary | `docs/Delivery-Team/{date}/sprint-{N}-summary.md` | Scrum Master | 7 |
| QA gate history | `docs/Delivery-Team/{date}/qa-gate-history.md` | Scrum Master (appends per sprint) | 7 |
| Release plan | `docs/Delivery-Team/{date}/release-plan.md` | `/dt-release-plan` | 4.5 |
| Deployment status | `docs/Delivery-Team/{date}/deployment-status.md` | `/dt-release` | 6 |
| Release retrospective | `docs/Delivery-Team/{date}/release-retro.md` | `/dt-release-retro` | 7 |
| Content brief (Tier 1/2 launches) | `docs/Delivery-Team/{date}/content-brief-{sprint}-{slug}.md` | Marketing Agent | 5–6 |
| Changelog draft | `docs/Delivery-Team/{date}/changelog-{sprint}.md` | Marketing Agent | 5–6 |

**Launch tier gating**: Not every sprint produces a content brief. The Marketing Agent assigns a launch tier at Stage 2 (stored in `launch-tier.md`). Only Tier 1 (major feature) and Tier 2 (notable improvement) produce content-brief artifacts. Tier 3 (incremental) and Tier 4 (internal/patch) are handled entirely within the sprint.

---

## Artifacts delivery-team reads (optional upstream)

delivery-team runs fully standalone. If you also run upstream product/strategy skills that write artifacts into the docs directory, the Scrum Master will opportunistically read them to enrich planning. This is **optional** — if no file is found, the Scrum Master proceeds without it and notes the gap in `sprint-plan.md`.

| Upstream artifact (example) | Glob pattern | Consumed by | Stage |
|-----------------------------|--------------|-------------|-------|
| Delivery / velocity health | `docs/**/*delivery-health*` | Scrum Master — velocity context | 3 |
| Risk scan | `docs/**/*risk-scan*` | Scrum Master — blocker awareness | 3 |
| Cycle / capacity plan | `docs/**/*cycle-plan*` | Scrum Master — scope validation | 3 |
| Backlog health | `docs/**/*backlog-health*` | Scrum Master — story quality baseline | 3 |
| Customer insights | `docs/**/*customer-insights*` | User Researcher, Scrum Master — scope framing | 1 |
| Competitive scan | `docs/**/*competitive-scan*` | GTM/Sales Agent, Aggressive PM | 2, 5 |
| Messaging source | `docs/**/*messaging*` | Marketing Agent — content-brief positioning | 5 |

**How the Scrum Master reads these**: at `/dt-start`, it resolves the current effort (see `context/dt-artifact-schemas.md`), Globs for the most recent file matching each pattern, and reads it before producing the sprint plan.

---

## Release Skills Internal Chain

This chain is fully self-contained within delivery-team:

```
/dt-release-plan ─── dt-release-scorer agent ──> release-plan.md
       ↓
/dt-readiness-gate (reads release-plan.md)
       ↓
/dt-release ─── dt-release-communicator agent ──> release-comms.md
    │  │                                           deployment-status.md
    │  └── /dt-release-monitor ──────────────────> release-health-brief.md
    │        (at each ring stage)
    └── /dt-release-comms (standalone or per-ring)
       ↓
/dt-close
    └── /dt-release-retro ───────────────────────> release-retro.md
```

---

## Path Conventions

All artifact paths are relative to the docs directory (default `docs/`, configurable — see `context/vault-access.md`).

- **delivery-team writes**: `docs/Delivery-Team/{date}/`
- **Filename pattern**: `{YYYY-MM-DD}/{skill}-{topic}.md`
- **Glob for latest**: `**/*{topic}*` sorted by modification time — always take the most recent match.

---

## What delivery-team Does NOT Do

- Does not invoke skills from other suites directly — it only reads their artifacts at defined paths.
- Does not write outside `docs/Delivery-Team/`.
- Does not push content to external tools (Notion, etc.) autonomously.
- Does not call Linear from dev agents — only the Scrum Master integrates with Linear, and only via MCP.

See `context/dt-pipeline-stages.md` for which agents are active at each stage.
