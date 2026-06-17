# GitHub Practices — delivery-team

Shared GitHub workflow standards for all delivery-team agents. Dev agents read this at story start alongside `project-kickoff.md`. The Scrum Master reads this for merge and cleanup responsibilities.

These are opinionated defaults. Override any default in `project-kickoff.md` under `github-overrides:`.

---

## Branching Model

**Default: GitHub Flow** — main is always deployable. Every story gets a short-lived feature branch.

### Branch Naming

Pattern: `{type}/{story-id}-{slug}`

Examples:
- `feat/story-042-password-reset`
- `fix/story-047-token-expiry-bug`
- `refactor/story-050-auth-middleware`

Type prefixes: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

If the project uses Linear integration, prefer Linear's suggested branch name (`gitBranchName` field from Linear API) to ensure auto-linking. Fall back to the pattern above if unavailable.

### Branch Rules

- **Never commit directly to the main branch.** All changes go through feature branches + pull requests.
- **One story, one branch.** Do not combine multiple stories on a single branch.
- **Branch from main.** Always create feature branches from the latest main branch, not from other feature branches (unless explicitly stacking).
- **Short-lived.** Feature branches should merge within the sprint. Branches not associated with the current sprint folder are flagged during sprint review.

### Worktree Integration

Dev agents run in git worktrees. The sprint-run orchestrator creates the worktree and branch together:
1. `git fetch origin main`
2. Create branch from `origin/main` using naming pattern above
3. Create worktree on that branch
4. Dev agent works in the worktree
5. After merge, orchestrator removes worktree and deletes branch

---

## Commit Standards

### Message Format (Conventional Commits)

```
{type}({scope}): {description}

{optional body — explain WHY, not WHAT}

Story: {story-id}
Co-Authored-By: Claude ({agent-name}) <noreply@anthropic.com>
```

**Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`
**Scope:** Module or component name (e.g., `auth`, `password-reset-form`, `api`)
**Description:** Imperative mood, lowercase, no period. Max 72 characters.

Examples:
- `feat(auth): add password reset token generation`
- `fix(auth): handle expired token gracefully instead of 500`
- `test(auth): add integration tests for reset flow edge cases`

### Atomic Commits

- Each commit does ONE thing. If the message contains "and", it should be two commits.
- A commit should leave the codebase in a buildable, testable state.
- Separate refactoring commits from feature commits, even within the same story.

### What NOT to Commit

- `.env` files, API keys, secrets, credentials
- Build artifacts, `node_modules/`, `.next/`, `dist/`
- IDE-specific files (`.idea/`, `.vscode/settings.json` with personal settings)
- Large binary files

Verify `.gitignore` covers these before first commit on any new project.

### Pre-commit Discipline

- Run linting on changed files BEFORE committing.
- Never use `--no-verify` to skip pre-commit hooks. If hooks fail, fix the issue.
- If a hook fails, fix the issue and create a NEW commit. Do not amend the previous commit.

### CI lints the PR's virtual merge ref, not HEAD

GitHub Actions evaluates lint and test jobs against the PR's virtual merge reference (`refs/pull/N/merge`) — not against the PR head alone. This matters when a sibling PR merges into the same file before yours: a file that passes lint locally on your branch can fail CI after the merge, because the virtual merge ref combines both diffs.

Concrete recurrences (S5, S15, S19): file-size lint on `dt-run.md` failed on a PR's virtual merge ref after a sibling PR pushed bytes into the same file. The fix is to either (a) merge `origin/main` into your branch and re-trim if size-bound, or (b) extract content into a context file before pushing. Pattern is structural, not incidental — when two PRs touch the same lint-bound file in the same sprint window, sequence them or pre-extract.

Mitigation when sequencing isn't possible:
- Before pushing, check sibling PRs touching the same file: `gh pr list --search "<filename> in:title,body" --state open`
- If a sibling has merged since your branch point, run `git fetch origin && git merge origin/main` and re-validate lint locally before pushing
- For files near a lint threshold (file-size, complexity), prefer extracting to a context file proactively rather than re-trimming after a CI failure

---

## Pull Request Standards

### When to Create

Create the PR AFTER:
1. All implementation is complete
2. Tests pass locally
3. Linting passes with zero errors
4. Pre-commit hooks pass

Create the PR BEFORE:
1. Writing `ready-for-review.md`
2. Signaling completion to the Scrum Master

The PR URL goes into `ready-for-review.md` — it must exist before that artifact is written.

### PR Size

- Target: ≤ 150 lines of significant code change per PR.
- "Significant" = new/modified logic, components, types, tests.
- Excludes: auto-generated files, lock files, formatting-only changes.
- If a story naturally produces > 150 lines, this is acceptable — the 150-line target is a signal, not a hard block. Stories are already sized to produce reasonable PRs.
- If a PR is significantly over 150 lines, note it in `ready-for-review.md` and explain why splitting wasn't feasible.

### PR Title Format

`{type}({scope}): {story-title} [{story-id}]`

Example: `feat(auth): User can reset password via email link [story-042]`

### PR Description Template

Dev agents produce this description when creating the PR:

```markdown
## Summary
{2-3 sentences: what was built and why}

## Story
- **Linear**: {Linear-ID}
- **Story file**: story-{id}.md

## Changes
{Bulleted list of key changes, grouped by area}

## Testing
- {How to verify: test commands, manual steps}
- {Edge cases covered}

## Screenshots
{For UI changes: before/after. For API-only changes: omit this section.}

## Notes for Reviewers
{Complex decisions, known trade-offs, areas needing extra scrutiny}

---
Co-Authored-By: Claude ({agent-name}) <noreply@anthropic.com>
```

### Self-Review

Before creating the PR, the dev agent MUST review its own diff:
1. `git diff main...HEAD` — read the full diff
2. Check for: debug statements, TODO comments, console.log, hardcoded values, commented-out code
3. Verify all changed files are intentional (no accidental modifications)
4. If issues found, fix them before creating the PR

### CI Verification

After creating the PR:
1. Push the branch
2. Check CI status via `gh pr checks`
3. If CI fails, fix the issue and push again
4. CI must be green before writing `ready-for-review.md`

---

## Merge Strategy

**Default: Squash and Merge** — collapses all story commits into one clean commit on main.

Squash commit message format:
`{type}({scope}): {story-title} (#{pr-number})`

This produces a clean, linear history on main where each commit = one story.

### Alternative Strategies (set in project-kickoff.md)

- **Rebase and Merge**: Preserves individual commits. Use when atomic commit history matters (e.g., expand-contract migrations that must be separable).
- **Merge Commit**: Creates a merge commit. Use when branch history visualization is important.

### Post-Merge Cleanup

After a PR is merged:
1. Delete the remote feature branch
2. Remove the local worktree (sprint-run orchestrator handles this)
3. The Scrum Master verifies merge completed before updating story status to `done`

---

## GitHub Organization

- **Personal projects**: `your-org`
- **Work projects**: Per employer's GitHub org (set in `project-kickoff.md`)

### Repository Setup Expectations

New repositories should have:
- `.gitignore` appropriate for the stack (verify during project-kickoff)
- Branch protection on main (require PR reviews, require CI to pass)
- GitHub Actions CI workflow (lint, type-check, test)

These are human setup tasks — agents flag if missing but do not configure them.

---

## Task Tracking Integration

The delivery-team uses **Linear** for task tracking, not GitHub Issues.
- Do not create GitHub Issues for story tracking.
- Reference Linear ticket IDs in PR titles and descriptions.
- If the project has GitHub-Linear integration, branch names auto-link PRs to tickets.
- The Scrum Master is the sole Linear writer — dev agents reference Linear IDs but never call Linear MCP tools.

---

## Parallel Work: Scope Awareness

When multiple agents work in parallel on different stories:
- Each agent works in its own worktree on its own branch.
- Agents do NOT rebase on each other's in-progress branches. Each branch tracks `origin/main` only.
- After a story's PR merges, the SM checks if in-progress stories need rebasing onto the updated main.
- During planning, the SM should note file-scope overlap between parallel stories in `dependency-map.md`. If overlap is high, sequence the stories rather than running them in parallel.

---

## Agent Responsibility Matrix

| Action | Responsible Agent |
|--------|------------------|
| Create feature branch | Dev agent (at story start) |
| Make atomic commits | Dev agent (during implementation) |
| Run pre-commit hooks | Dev agent (before each commit) |
| Lint before commit | Dev agent (before each commit) |
| Run local checks (lint, type-check, test) | Dev agent (after implementation) |
| Self-review diff | Dev agent (before PR creation) |
| Create PR with description | Dev agent (after local checks pass) |
| Verify CI passes on PR | Dev agent (after PR creation) |
| Write ready-for-review.md | Dev agent (after CI green) |
| Verify PR exists and CI green | QA tester (step 0 of qa-gate) |
| Review code quality | QA tester (during qa-gate) |
| Merge PR (squash default) | Scrum Master (after qa-gate PASS) |
| Delete feature branch | Scrum Master (after merge) |
| Verify merge before marking done | Scrum Master (before story → done) |
| Clean up worktree | Sprint-run orchestrator (after story done) |
| Flag orphaned branches | Scrum Master (during sprint review) |

---

## Overrides via project-kickoff.md

```yaml
github-overrides:
  org: "custom-org"
  branch-naming: "{linear-branch-name}"
  commit-format: "conventional"    # conventional | freeform
  merge-strategy: "squash"         # squash | rebase | merge
  pr-size-target: 200              # lines of significant change
  main-branch: "main"              # or "latest", "develop", etc.
  ci-required: true
  draft-pr-default: false          # true = always create as draft PR
```
