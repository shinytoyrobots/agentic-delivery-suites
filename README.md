# Agentic Delivery Suites

Most tools for building software with AI keep the process we already have — the Scrum sprint, with its stories, gates, and fixed roles — and accelerate it. These two [Claude Code](https://claude.com/claude-code) skill suites take opposite answers to a sharper question: once the people in the loop are agents, is the sprint worth keeping at all?

| Suite | Premise | In one line |
|-------|---------|-------------|
| [**`delivery-team`**](./delivery-team/) | *AI acceleration of a human sprint* | 13 sub-agents acting as a complete product-delivery team, orchestrated through an 11-skill sprint lifecycle. |
| [**`flow`**](./flow/) | *AI-first from the ground up* | The spec is the source of truth; code is regenerated output. Parallel generators, multi-objective Pareto evaluation, convergence instead of calendar. |

`delivery-team` keeps the shape of a Scrum sprint — stories, gates, retros, fixed roles — and makes every seat faster. `flow` discards that scaffolding and rebuilds the pipeline around what LLM agents are uniquely good at (parallel reading, structured scoring, deterministic projection) and bad at (parallel writes, free-form coordination, drifting prose).

**[delivery-team-vs-flow.md](./delivery-team-vs-flow.md)** is the full side-by-side comparison and the best place to start if you're deciding which to use.

## What's here

```
flow/                 # AI-first delivery suite
  commands/           #   slash-command skills (flow-init, flow-spec, flow-generate, …)
  agents/             #   function-shaped sub-agents (orchestrator, evaluator, generator, …)
  context/            #   shared reference docs the skills load
  README.md           #   suite overview
  USAGE.md            #   practitioner's guide
delivery-team/        # Sprint-accelerator delivery suite
  commands/           #   sprint lifecycle skills (dt-start, dt-run, dt-close, …)
  agents/             #   role-shaped sub-agents (scrum-master, devs, QA, PMs, …)
  context/            #   pipeline stages, schemas, definition of done, …
  README.md           #   suite overview
shared/
  context/            # context files both suites depend on (vault-access, spec-writing-guide)
install.sh            # installs the suites into ~/.claude/
```

## Install

Requires [Claude Code](https://claude.com/claude-code).

```bash
git clone https://github.com/shinytoyrobots/agentic-delivery-suites.git
cd agentic-delivery-suites
./install.sh            # symlinks the suites into ~/.claude/ (edits propagate live)
```

Options:

```bash
./install.sh --copy                  # copy instead of symlink
./install.sh --suite flow            # install just one suite
./install.sh --suite delivery-team
```

The installer places commands in `~/.claude/commands/`, context in `~/.claude/commands/context/`, and agents in both `~/.claude/agents/` (native subagents) and `~/.claude/commands/agents/`. Restart Claude Code afterward. Invoke skills as slash commands, e.g. `/flow-init` or `/dt-start`.

## Optional integrations

The suites run standalone on the local filesystem. Several agents can *optionally* use MCP servers if you have them connected — referenced in agent frontmatter and prose by generic names you can map to your own servers:

| Generic name | What it's used for |
|--------------|--------------------|
| `linear` | Issue / cycle tracking (Scrum Master sync) |
| `notion`, `slack` | Status, comms, and coordination surfaces |
| `design-system` | Design-token / component lookup (frontend & design agents) |
| `notes` | A notes / knowledge-base store for research and bookmarks |
| `figma`, `github`, `hubspot` | Design, repo, and CRM context |

None are required. Where an integration is absent, the agents fall back to local files (see `shared/context/vault-access.md`). Durable artifacts are written to a local `docs/` directory by default — configurable to any folder you like.

## Status

These are experimental research artifacts, shared as-is. They encode a specific point of view about agentic delivery; treat them as a starting point to adapt, not a finished product. Issues and forks welcome.

## License

MIT — see [LICENSE](./LICENSE).
