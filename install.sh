#!/usr/bin/env bash
#
# Install the flow and delivery-team skill suites into Claude Code.
#
# Layout produced (matches how the suites reference each other):
#   commands  -> ~/.claude/commands/
#   context   -> ~/.claude/commands/context/
#   agents    -> ~/.claude/commands/agents/  AND  ~/.claude/agents/
#
# Agents are linked in both places: ~/.claude/agents/ is Claude Code's native
# subagent location (enables Agent({subagent_type: "name"})), and
# ~/.claude/commands/agents/ is where the command files expect to find them.
#
# Usage:
#   ./install.sh            # symlink (default — repo edits propagate live)
#   ./install.sh --copy     # copy files instead of symlinking
#   ./install.sh --suite flow            # install only one suite
#   ./install.sh --suite delivery-team   # (shared/ context is always installed)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_CMDS="$HOME/.claude/commands"
CLAUDE_AGENTS="$HOME/.claude/agents"

MODE="symlink"
SUITES=(flow delivery-team)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy) MODE="copy"; shift ;;
    --suite) SUITES=("$2"); shift 2 ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

mkdir -p "$CLAUDE_CMDS" "$CLAUDE_CMDS/context" "$CLAUDE_CMDS/agents" "$CLAUDE_AGENTS"

place() {
  # place <src> <dest>
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ "$MODE" == "copy" ]]; then
    cp "$src" "$dest"
  else
    ln -sf "$src" "$dest"
  fi
}

count=0
install_dir() {
  # install_dir <dir> <dest-dir>; no-op if dir absent or empty
  local dir="$1" destdir="$2"
  [[ -d "$dir" ]] || return 0
  shopt -s nullglob
  for f in "$dir"/*.md; do
    place "$f" "$destdir/$(basename "$f")"
    count=$((count + 1))
  done
  shopt -u nullglob
}

for suite in "${SUITES[@]}"; do
  echo "Installing suite: $suite"
  install_dir "$REPO_ROOT/$suite/commands" "$CLAUDE_CMDS"
  install_dir "$REPO_ROOT/$suite/context"  "$CLAUDE_CMDS/context"
  # Agents: dual-linked
  install_dir "$REPO_ROOT/$suite/agents"   "$CLAUDE_CMDS/agents"
  install_dir "$REPO_ROOT/$suite/agents"   "$CLAUDE_AGENTS"
done

# Shared context (required by both suites: vault-access, spec-writing-guide)
echo "Installing shared context"
install_dir "$REPO_ROOT/shared/context" "$CLAUDE_CMDS/context"

echo "Done — $count files installed (mode: $MODE) into ~/.claude/"
echo "Restart Claude Code (or reload skills) to pick up the new commands."
