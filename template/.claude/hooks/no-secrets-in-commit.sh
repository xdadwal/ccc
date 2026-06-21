#!/usr/bin/env bash
#
# PreToolUse(Bash) guardrail — block `git commit` when staged changes contain likely secrets.
# Reads the hook JSON on stdin. Exit 2 with a reason on stderr = block (Claude sees the reason).
# This fires BEFORE permission-mode checks, so it holds even under --dangerously-skip-permissions.
#
# Scans only ADDED lines in the staged diff against a set of high-precision patterns, so a
# real key/token can't slip into history. False positive on a test fixture? CCC_ALLOW_SECRET=1.
#
set -uo pipefail

input="$(cat)"
cmd="$(printf '%s' "$input" | python3 -c 'import sys,json
try:
    print(json.load(sys.stdin).get("tool_input",{}).get("command","") or "")
except Exception:
    pass' 2>/dev/null || true)"
[[ -z "$cmd" ]] && exit 0

c="$(printf '%s' "$cmd" | tr '\n\t' '  ' | tr -s ' ')"

# only on an actual commit; skip inspection-only invocations
printf '%s' "$c" | grep -Eq '\bgit\b.*\bcommit\b' || exit 0
printf '%s' "$c" | grep -Eq '(--dry-run|--help)\b' && exit 0

[[ "${CCC_ALLOW_SECRET:-}" == "1" ]] && exit 0

dir="${CLAUDE_PROJECT_DIR:-.}"
staged="$(git -C "$dir" diff --cached --no-color -U0 2>/dev/null || true)"
[[ -z "$staged" ]] && exit 0

findings="$(printf '%s' "$staged" | python3 -c '
import sys, re

# (label, compiled pattern) — high precision to avoid noisy false positives
PATTERNS = [
    ("private key block",       re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("AWS access key id",       re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("GitHub token",            re.compile(r"\bgh[pousr]_[0-9A-Za-z]{36}\b")),
    ("Slack token",             re.compile(r"\bxox[baprs]-[0-9A-Za-z-]{10,}")),
    ("Google API key",          re.compile(r"\bAIza[0-9A-Za-z_\-]{35}\b")),
    ("Stripe secret key",       re.compile(r"\bsk_live_[0-9A-Za-z]{24,}\b")),
    ("OpenAI/Anthropic key",    re.compile(r"\bsk-(ant-)?[0-9A-Za-z_\-]{20,}\b")),
    ("private key/token assignment",
        re.compile(r"(?i)(api[_-]?key|secret|token|password|passwd|access[_-]?key)"
                   r"\s*[:=]\s*[\"'\''][^\"'\'']{12,}[\"'\'']")),
]
# obvious placeholders that should not trip the generic assignment rule
PLACEHOLDER = re.compile(r"(?i)(your[_-]?|example|changeme|placeholder|xxxx|<[^>]+>|\$\{?[A-Z_]+\}?|env\(|process\.env)")

hits = []
for raw in sys.stdin:
    if not raw.startswith("+") or raw.startswith("+++"):
        continue
    line = raw[1:]
    for label, pat in PATTERNS:
        m = pat.search(line)
        if not m:
            continue
        if label.startswith("private key/token assignment") and PLACEHOLDER.search(line):
            continue
        hits.append(label)
        break

for label in sorted(set(hits)):
    print(label)
' 2>/dev/null || true)"

if [[ -n "$findings" ]]; then
  echo "Blocked by ccc no-secrets-in-commit: staged changes look like they contain a secret:" >&2
  while IFS= read -r f; do [[ -n "$f" ]] && echo "  - $f" >&2; done <<< "$findings"
  echo "Remove it (read secrets from the environment), unstage the file, or set CCC_ALLOW_SECRET=1 if this is a false positive." >&2
  exit 2
fi

exit 0
