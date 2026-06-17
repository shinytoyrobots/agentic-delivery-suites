# Delivery Team

A collective of 13 Claude Code sub-agents that function as a complete product delivery team, orchestrated through an 11-skill sprint lifecycle.

## Why these exist

The delivery-team suite was designed from three structured research programs. The core architecture draws on a strategic assessment of multi-agent delivery teams, studying MetaGPT (ICLR 2024), the MASFT failure taxonomy (UC Berkeley, ICLR 2025), BMAD's story-sharding methodology, and Team Topologies (IT Revolution). The research examined how structured artifact handoffs, phase-based agent activation, and architectural enforcement patterns produce reliable multi-agent systems — and why prompt engineering alone falls short (40-60% reliability vs. 80%+ with architectural mitigations).

A second research program studied GitHub workflow practices across AI coding agents (Claude Code, Copilot, Devin, OpenHands) and 50,000+ PRs to establish branching, commit, and PR standards for agent-driven development. A third studied retrospective methodology — comparing DAKI, Start/Stop/Continue, and AAR formats — to design a closed-loop retro skill that tracks prior action follow-through (the single biggest lever for retro effectiveness, jumping completion rates from ~45% to ~65%).

Key architectural decisions from the research:

- **Document-based coordination over conversational** — every agent-to-agent handoff uses a canonical artifact with a defined schema, not free-form messaging (MetaGPT, BMAD convergence)
- **Team Topologies as the organizing framework** — agents classified as stream-aligned, enabling, platform, complicated-subsystem, or orchestrator, each with distinct interaction protocols
- **Structural enforcement over prompt instructions** — tool restrictions (QA cannot Write/Edit), mandatory output schemas, and hooks-based quality gates enforce correctness architecturally
- **Phase-based activation** — 3-5 agents active at a time, not all 13 simultaneously. Discovery activates researcher + designer; implementation activates devs in parallel worktrees; review activates QA
- **Worldview-first agent design** — agent methodology files written as character "masks" (commedia dell'arte principle) rather than rule lists, generating correct behavior across novel situations
- **Domain veto authority** — QA has ship/no-ship authority via `qa-gate.md`; designer has accessibility veto (NASA Mission Control pattern, enforced structurally)

## Skills

| Skill | Description | When |
|-------|-------------|------|
| `dt-project-kickoff` | Initialize a new project — gather stack, conventions, HITL level, launch tier | Project start |
| `dt-start` | Discovery + Planning — consume specs, invoke enabling agents, shard stories, create sprint plan | Sprint start |
| `dt-run` | Implementation — orchestrate story execution with parallel dev agents, QA gates, blocker management | Sprint execution |
| `dt-status` | Read-only sprint status report — stories by status, blockers, velocity projection | On-demand |
| `dt-blocker` | Register a blocker against a story — update sprint state, create HITL escalation | On-demand |
| `dt-gate-review` | Adversarial PM gate review — launch Conservative and Aggressive PM subagents, synthesize divergence | Before stage transitions |
| `dt-readiness-gate` | Cross-functional readiness check — launch GTM, Marketing, and CX/Support agents in parallel | Pre-launch |
| `dt-story-review` | QA shift-left story review — flag untestable ACs, ambiguous specs, missing edge cases | Before implementation |
| `dt-close` | Sprint review — validate qa-gate, produce sprint summary, update velocity, close Linear cycle | Sprint end |
| `dt-retro` | ~~Deprecated~~ — amalgamated into `dt-close` | — |
| `dt-codebase-index` | Run the codebase indexer to produce or refresh structured context files | On-demand |

## Agent roles

| TT Type | Agent | Role |
|---------|-------|------|
| Orchestrator | `dt-scrum-master` | Controls which agents are active per phase; enforces interaction modes and gates |
| Stream-aligned | `dt-frontend-dev` | UI components, WCAG 2.2 AA accessibility, React patterns, design system adherence |
| Stream-aligned | `dt-backend-dev` | Server architecture, APIs, database schemas, business logic, security-first defaults |
| Stream-aligned | `dt-middleware-dev` | Data flow, API composition, protocol translation, auth orchestration, resilience |
| Enabling | `dt-product-designer` | Component-level design specs, accessibility annotations, interaction state matrices |
| Enabling | `dt-user-researcher` | Desk research, JTBD frameworks, evidence quality assessment, persona identification |
| Complicated-subsystem | `dt-qa-tester` | Acceptance criteria verification, accessibility audits, code review, ship/no-ship gate |
| Platform | `dt-codebase-indexer` | Produces structured context files (architecture, API surface, data model, components) |
| Stakeholder | `dt-aggressive-pm` | Challenges inaction, quantifies cost of delay, defends MVP scope |
| Stakeholder | `dt-conservative-pm` | Identifies risks, readiness gaps, regression exposure with evidence-grounded skepticism |
| Stakeholder | `dt-marketing` | Launch tier, content briefs, changelog drafts, marketing readiness |
| Stakeholder | `dt-gtm-sales` | Deal impact, sales briefs, battlecard updates, GTM readiness |
| Stakeholder | `dt-cx-support` | Documentation impact, help articles, support readiness |

## Supporting files

- `context/dt-pipeline-stages.md` — 7-stage delivery pipeline with gate criteria
- `context/dt-artifact-schemas.md` — Canonical schemas for story files, sprint status, and all agent artifacts
- `context/dt-definition-of-done.md` — Quality criteria enforced at Gate 4→5
- `context/dt-github-practices.md` — Branching model, commit standards, PR conventions, merge strategy
- `context/dt-hitl-protocol.md` — Human-in-the-loop calibration levels and escalation rules
- `context/dt-integration-map.md` — How upstream and downstream skill artifacts integrate with delivery-team

## Design principles

1. **Artifacts, not conversations.** Every handoff has a defined schema. Agents read and write files, never free-form messages.
2. **Architectural enforcement.** Tool restrictions, hooks, and file-based gates enforce correctness — prompts alone achieve 40-60% reliability.
3. **Phase-based activation.** 3-5 active agents per phase. The Scrum Master controls the topology.
4. **Conway's Law as deliberate tool.** Agent communication topology shapes the software architecture.
5. **Structural veto authority.** QA's `qa-gate.md` and Designer's `design-veto.md` are mandatory reads, not advisory opinions.
6. **Persistent memory.** Agents accumulate institutional knowledge — deprecated components, failure patterns, velocity data.

## Research background

| Research | What it covers |
|----------|---------------|
| `2026-03-21-agent-collective` | Two-tier hybrid architecture, Team Topologies mapping, MASFT failure taxonomy, 15-field agent format, document-based coordination |
| `2026-03-21-delivery-team-github-practices` | GitHub workflow for agent-driven development, branching model, PR size data, git as multi-agent coordination protocol |
| `2026-03-21-sprint-retro-skill` | DAKI vs SSC vs AAR comparison, closed-loop action tracking, five-dimension retrospective analysis |

Research files at `docs/Deep-Research/`.

## Data sources

- **Linear** — cycles, issues, projects, story tracking, velocity data
- **GitHub** — branches, PRs, CI status, code review
- **Slack** — standup threads, blocker mentions, team discussions
- **Notion** — project docs, sprint artifacts, persistence
- **Vault** — prior sprint outputs, retro actions, velocity history
- **Design-system MCP** — design system components (via product-designer agent)
