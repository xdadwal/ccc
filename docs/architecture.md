# ccc architecture

Why this repo is shaped the way it is. Grounded in an adversarial review of Anthropic's official
Claude Code docs (25 claims, all confirmed) plus the community "ralph loop" pattern.

## Goals

1. **Modular** — every concern is one file you can add or remove without touching the rest.
2. **Lean context** — only load what's relevant to the work at hand.
3. **Real enforcement** — guardrails that hold during unattended/autonomous runs.
4. **Reusable & extensible** — seed into any repo; improve in one place; resync everywhere.

## The five load-bearing decisions

### 1. Source-of-truth template + bootstrap
`ccc` holds the canonical bundle under `template/`. `bootstrap.sh` copies it into target repos,
stamps the `VERSION`, and records the source path so `/sync-config` can re-pull later. Updates
flow from one place. (We chose a template over a plugin for simplicity, but laid files out
plugin-ready — see "Graduating to a plugin".)

### 2. Guidance vs. enforcement
The most important distinction in Claude Code config:
- **Guidance** — `CLAUDE.md`, `rules/`, skills. Claude *reads* these; it may not follow them.
- **Enforcement** — `permissions` and `hooks`. Applied *regardless* of what Claude decides.

So anything that must always hold (no `rm -rf /`, no editing `.env`, format on save) is a hook +
a `permissions.deny` rule — never a sentence in `CLAUDE.md`. Verified specifics that make this
work:
- A `PreToolUse` hook returning a block (exit `2`, or `permissionDecision: deny` on exit `0`)
  **fires before any permission-mode check** — so it holds even under
  `--dangerously-skip-permissions`, the mode autonomous loops use.
- Hooks can *tighten* but never *loosen* past `permissions.deny`.
- Permission rules **merge across scopes** (deny > ask > allow, first match wins); other settings
  override key-by-key. `settings.local.json` is auto-gitignored.

### 3. Layered, lean context
A short root `CLAUDE.md` (< ~200 lines) `@import`s always-on rules (fundamentals, git, testing).
Stack rules (`typescript.md`, `python.md`) carry `paths:` frontmatter so they load only when a
matching file is in play. Extension = drop in a `rules/<topic>.md` (+ at most one `@import`).
Note: path-scoped `rules/` have open bugs (may not load at user scope / only on Read), so
must-load content is `@import`ed explicitly rather than relying on `paths:` matching.

### 4. Skills + subagents for capability and context economy
- **Skills** (`skills/<name>/SKILL.md`) are the unit of reusable workflow. Commands and skills are
  the same mechanism now; skills are preferred (a directory with progressive disclosure; body
  kept < 500 lines; the `description` drives auto-invocation; dir name = `/command`).
- **Subagents** (`agents/*.md`) run in isolated context windows. `explorer`/`reviewer`/
  `test-runner` let the main thread delegate reading, reviewing, and testing without bloating its
  own context — essential for long autonomous runs.

### 5. Autonomy-forward, safely
`autoloop` codifies the ralph pattern (single process, one repo, one task per iteration toward a
goal) with a `PROMPT.md` + `specs/` contract and **mandatory stop conditions** (done / no-progress
/ blocked / budget / ambiguity). The guardrail hooks are the safety floor; a human review + merge
gate is required. It composes with the installed `ralph-loop` plugin and `verify`/`code-review`
skills rather than reimplementing them. Caveat from the research: ralph loops underperform on
security-critical code and dependency churn — keep humans in those loops.

## Graduating to a plugin (future)
Add `.claude-plugin/plugin.json` + a `marketplace.json` catalog and install via `/plugin` instead
of copying. Migration is mechanical: `skills/`, `agents/`, `commands/` move as-is; hooks move from
`settings.json` into `hooks/hooks.json` (same format); skills become namespaced (`ccc:autoloop`).
Caveat: a plugin's own `settings.json` currently honors only `agent` + `subagentStatusLine`, so
permissions/hooks ride along via the other files. The layout already matches plugin structure, so
this is purely additive.

## Sources
Anthropic docs: claude-directory, settings, permissions, hooks-guide, hooks, skills, sub-agents,
plugins, plugin-marketplaces (code.claude.com/docs). Ralph loop: ghuntley.com/ralph,
ghuntley.com/loop, github.com/snarktank/ralph.
