# Git & version control

## Branches
- Never commit or push directly to `main`/`master` — a hook blocks it. Branch first:
  `feat/<short-desc>`, `fix/<short-desc>`, `chore/<short-desc>`, `docs/<short-desc>`.
  (Rare legit case, e.g. a fresh repo's first commit: `CCC_ALLOW_MAIN=1`.)
- Keep branches focused on one logical change.

## Commits
- Conventional Commits: `type(scope): summary` in the imperative mood, ≤ ~72 chars.
  Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `build`, `ci`.
- One logical change per commit. The body explains *why*, not *what* (the diff shows what).
- Only commit when the user asks. Don't `git add -A` blindly — stage intended files.
- Never commit secrets, large binaries, or generated artifacts. A hook scans staged changes
  and blocks commits containing likely secrets (`CCC_ALLOW_SECRET=1` overrides a false positive).

## Pushing & PRs
- Pushing prompts for confirmation (configured in settings). Force-pushes with `-f`/`--force`
  are blocked by a hook — use `--force-with-lease`, and not on shared branches.
- Open PRs against `main`. Keep the description focused: what changed and why, plus how it was
  verified. Don't include unrelated changes.

## Hygiene
- Pull/rebase onto the latest base before opening a PR.
- Resolve conflicts deliberately; never blindly accept one side.
