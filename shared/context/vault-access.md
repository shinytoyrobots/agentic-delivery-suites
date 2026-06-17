# Artifact Output — Local Docs Directory

Both suites persist their durable artifacts (sprint summaries, release plans, retros, research briefs, content briefs) to a local **docs directory** so that later skill runs — and you — can read them back. Throughout the suites this directory is referred to as the "vault"; it is just a folder of markdown you control.

## The docs directory

- **Default path**: `docs/` at the project root.
- Override it by pointing the suites at any directory you prefer (e.g. an Obsidian vault, a `notes/` folder, a docs site source tree). Keep it consistent across runs so artifacts accumulate in one place.

## Reading and writing

- **Read**: Use `Read`, `Glob`, `Grep` against the docs directory directly.
- **Write**: Use `Write` to save artifacts under the docs directory.
- **List / find latest**: Use `Glob` patterns (e.g. `docs/**/*release-retro*`) and take the most recently modified match.

## Layout convention

Artifacts are namespaced by suite and dated so they are easy to retrieve:

```
docs/
  Delivery-Team/{YYYY-MM-DD}/sprint-{N}-summary.md
  Delivery-Team/{YYYY-MM-DD}/release-plan.md
  ...
```

This is a convention, not a requirement — adjust the structure to fit your own knowledge base. The only thing the suites rely on is that they can `Glob` for prior artifacts and `Read` them back.

## Optional: a notes MCP

If you connect a notes/knowledge-base MCP server, agents can call its tools (e.g. `mcp__notes__write-file`, `mcp__notes__search-notes`) as an alternative to local file I/O. This is entirely optional — the local docs directory is the default and needs no setup.
