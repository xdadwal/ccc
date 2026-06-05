# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`ccc` ("Claude Code configs") is the **single source of truth** for a personal, modular Claude
Code configuration. It is a **template/starter**: `template/` holds a canonical `.claude/`
bundle, and `bootstrap.sh` seeds (and re-syncs) that bundle into other repositories.

`ccc` itself is not configured by its own `template/` — editing files under `template/` defines
what gets **shipped to other repos**, not how Claude behaves while working *in* `ccc`.

## Layout

```
VERSION                 # bumped on changes; stamped into seeded repos' CLAUDE.md
bootstrap.sh            # seed/sync the bundle into a target repo (idempotent; --dry-run)
docs/architecture.md    # the design rationale (read this for the "why")
template/
  CLAUDE.md             # lean root context shipped to target repos (uses @import)
  gitignore.snippet     # appended to a target repo's .gitignore
  .claude/
    settings.json                  # permissions (allow/ask/deny) + hook wiring
    settings.local.json.example    # personal overrides (gitignored in target)
    rules/*.md                     # modular context; stack files use `paths:` frontmatter
    skills/<name>/SKILL.md         # autoloop, ship, sync-config
    agents/*.md                    # explorer, reviewer, test-runner, debugger (task-based, model-tiered)
    hooks/*.sh                     # guard-bash, protect-paths, format-on-write, session-context
    .mcp.json.example              # optional MCP servers
```

## Core principles (keep these intact when extending)

- **Guidance vs. enforcement.** `CLAUDE.md` and `rules/` are *guidance* Claude may not follow;
  `permissions` and `hooks` are *enforced*. Anything that must always hold → a hook +
  `permissions.deny`, never just prose. (Verified: `PreToolUse` deny fires before permission-mode
  checks, so hooks hold even under `--dangerously-skip-permissions`.)
- **File-per-concern.** One rule/skill/agent/hook per file, so each can be added or removed
  independently.
- **Lean context.** Always-on rules are `@import`ed from `template/CLAUDE.md`; stack rules use
  `paths:` frontmatter to load only when a matching file is touched.
- **Plugin-ready.** The `skills/ agents/ hooks/` layout matches a plugin's, so this can graduate
  to a distributable plugin later with no restructuring.
- **Skills over commands.** Commands and skills are the same mechanism now; prefer `skills/`.

## How to extend

- **Add a rule:** create `template/.claude/rules/<topic>.md`. If always-on, add one `@import`
  line to `template/CLAUDE.md`; if path-specific, give it `paths:` frontmatter instead.
- **Add a skill:** create `template/.claude/skills/<name>/SKILL.md` (frontmatter: `name`,
  `description`; keep the body < 500 lines; bundle supporting files beside it).
- **Add an agent:** create `template/.claude/agents/<name>.md` (frontmatter: `name`,
  `description`, optional `tools`, `model`). Agents are **task-based** (one verb each:
  explore/review/test/debug) and **domain-aware** via the rules layer — not role personas. Give a
  task-scoped `description` so delegation routes correctly, and pick a model tier (`haiku` for
  high-volume read/run agents, `opus` for judgment-heavy review/debug). The **tech-lead role is the
  main session**, encoded in `template/CLAUDE.md` — not a subagent.
- **Add a guardrail hook:** add `template/.claude/hooks/<name>.sh` and wire it in
  `template/.claude/settings.json` under the right event/matcher. Exit `2` + stderr reason to
  block; keep it dependency-light (these scripts use `python3` to parse stdin JSON).
- After any change, **bump `VERSION`** so seeded repos can tell they're behind.

## Commands

```bash
./bootstrap.sh --dry-run <target-repo>   # preview what would change
./bootstrap.sh <target-repo>             # seed or update a repo's config
```

There is no build/test/lint tooling in this repo. Validate changes by bootstrapping into a
scratch repo and exercising the hooks/skills there.

## Don't reinvent globally-installed tools

This setup intentionally leans on already-installed skills/plugins (`ralph-loop`, `verify`,
`code-review`, `simplify`, `commit-commands`, `feature-dev`, `pr-review-toolkit`) instead of
duplicating them. The template adds repo-local context, guardrails, and project workflows that
wire those together.
