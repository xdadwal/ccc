#!/usr/bin/env bash
#
# PreToolUse(Bash) guardrail — block committing/pushing directly to main/master.
# Reads the hook JSON on stdin. Exit 2 with a reason on stderr = block (Claude sees the reason).
# This fires BEFORE permission-mode checks, so it holds even under --dangerously-skip-permissions.
#
# Enforces the git rule "branch first, never commit to main". Escape hatch for the rare
# legitimate case (e.g. a fresh repo's first commit): CCC_ALLOW_MAIN=1.
#
set -uo pipefail

input="$(cat)"
cmd="$(printf '%s' "$input" | python3 -c 'import sys,json
try:
    print(json.load(sys.stdin).get("tool_input",{}).get("command","") or "")
except Exception:
    pass' 2>/dev/null || true)"
[[ -z "$cmd" ]] && exit 0

# collapse whitespace for matching
c="$(printf '%s' "$cmd" | tr '\n\t' '  ' | tr -s ' ')"

# only relevant to git commit / git push
printf '%s' "$c" | grep -Eq '\bgit\b.*\b(commit|push)\b' || exit 0
# allow inspection-only invocations
printf '%s' "$c" | grep -Eq '(--dry-run|--help)\b' && exit 0

[[ "${CCC_ALLOW_MAIN:-}" == "1" ]] && exit 0

block() { echo "Blocked by ccc block-main-commit: $1. Branch first (feat/fix/chore/...), or set CCC_ALLOW_MAIN=1 if this is intentional." >&2; exit 2; }

dir="${CLAUDE_PROJECT_DIR:-.}"
branch="$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null || true)"
# detached HEAD or non-repo → nothing to enforce
[[ -z "$branch" ]] && exit 0

is_protected() { [[ "$1" == "main" || "$1" == "master" ]]; }

# git commit while on a protected branch
if printf '%s' "$c" | grep -Eq '\bgit\b.*\bcommit\b' && is_protected "$branch"; then
  block "committing directly to '$branch'"
fi

# git push that explicitly publishes to a protected branch ref (e.g. `git push origin HEAD:main`)
if printf '%s' "$c" | grep -Eq '\bgit\b.*\bpush\b' \
   && printf '%s' "$c" | grep -Eq ':(refs/heads/)?(main|master)\b'; then
  block "pushing directly to a protected branch ref"
fi

exit 0
