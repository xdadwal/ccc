# ccc — Claude Code configs

A personal, modular **Claude Code configuration starter**. `ccc` is the single source of truth
for the `.claude/` setup I seed into new repositories — context, rules, skills, subagents, and
guardrail hooks — built to start minimal and grow over time.

## Use it

```bash
# preview what would change in a target repo
./bootstrap.sh --dry-run /path/to/your/repo

# seed (or re-sync) the config into that repo
./bootstrap.sh /path/to/your/repo
```

`bootstrap.sh` copies `template/.claude/` into the target, stamps `CLAUDE.md` with the current
`VERSION`, makes the hooks executable, appends a `.gitignore` snippet, and remembers where `ccc`
lives so the seeded repo's `/sync-config` skill can pull future updates. It never overwrites your
personal `settings.local.json`, and re-running it is safe (idempotent).

## What's in the bundle (`template/.claude/`)

| Piece | What it does |
|-------|--------------|
| `CLAUDE.md` + `rules/` | Layered, `@import`ed context: language-agnostic fundamentals + git/testing + TS/Python stack rules (path-scoped). **Guidance.** |
| `settings.json` | Permissions (allow/ask/deny) and hook wiring. **Enforced.** |
| `hooks/` | Guardrails: block destructive bash & secret/lockfile edits, auto-format on save, inject git status at session start. **Enforced** — they hold even in autonomous runs. |
| `skills/` | `autoloop` (ralph-style autonomy loop with stop conditions), `ship` (plan→verify→commit), `sync-config` (pull updates from ccc). |
| `agents/` | `explorer`, `reviewer`, `test-runner`, `debugger` — task-based, model-tiered subagents (Haiku for read/run, Opus for review/debug) that keep the main context lean. The main session acts as tech lead and delegates to them. |
| `.mcp.json.example` | Optional MCP servers, opt-in per repo. |

## Design in one line

Guidance (`CLAUDE.md`/`rules/`) shapes behavior; **enforcement (`hooks`/`permissions`) guarantees
it** — so autonomy-forward workflows stay safe. See [`docs/architecture.md`](docs/architecture.md)
and `CLAUDE.md` for the full rationale.

## License

MIT — see [`LICENSE`](LICENSE).
