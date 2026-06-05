#!/usr/bin/env bash
#
# bootstrap.sh — seed or update a repository's Claude Code config from this ccc checkout.
#
# Usage:
#   ./bootstrap.sh [--dry-run] <target-repo-dir>
#
# What it does (idempotent — safe to re-run to pull in newer ccc config):
#   - copies template/.claude/ into <target>/.claude/   (never clobbers settings.local.json)
#   - writes <target>/CLAUDE.md from template/CLAUDE.md, stamped with this ccc VERSION
#     (an existing, non-ccc CLAUDE.md is backed up to CLAUDE.md.bak first)
#   - makes the hook scripts executable
#   - appends gitignore.snippet to <target>/.gitignore (once)
#   - records this ccc checkout path in <target>/.claude/.ccc-source so /sync-config can find it
#
set -euo pipefail

DRY_RUN=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) grep '^#' "$0" | sed 's/^#\{1,\} \{0,1\}//'; exit 0 ;;
    -*) echo "error: unknown flag '$arg'" >&2; exit 1 ;;
    *) TARGET="$arg" ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "error: target repo dir required.  usage: $0 [--dry-run] <target-repo-dir>" >&2
  exit 1
fi
if [[ ! -d "$TARGET" ]]; then
  echo "error: target '$TARGET' is not a directory" >&2
  exit 1
fi

CCC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$CCC_ROOT/template"
TARGET="$(cd "$TARGET" && pwd)"
VERSION="$(cat "$CCC_ROOT/VERSION" 2>/dev/null || echo unknown)"

if [[ ! -d "$SRC/.claude" ]]; then
  echo "error: $SRC/.claude not found — run this from a complete ccc checkout" >&2
  exit 1
fi

run() {
  if [[ "$DRY_RUN" == 1 ]]; then
    printf 'DRY: '; printf '%q ' "$@"; printf '\n'
  else
    "$@"
  fi
}

echo "ccc bootstrap v$VERSION  →  $TARGET"

# 1. Copy template/.claude/ (skip the real settings.local.json so personal overrides survive)
while IFS= read -r -d '' f; do
  rel="${f#"$SRC/.claude/"}"
  [[ "$rel" == "settings.local.json" ]] && continue
  dest="$TARGET/.claude/$rel"
  run mkdir -p "$(dirname "$dest")"
  run cp "$f" "$dest"
done < <(find "$SRC/.claude" -type f -print0)

# 2. CLAUDE.md — stamp VERSION; back up a pre-existing non-ccc file
DEST_CLAUDE="$TARGET/CLAUDE.md"
if [[ -f "$DEST_CLAUDE" ]] && ! grep -qF 'Seeded from `ccc`' "$DEST_CLAUDE"; then
  run cp "$DEST_CLAUDE" "$DEST_CLAUDE.bak"
  echo "note: existing CLAUDE.md backed up → CLAUDE.md.bak"
fi
if [[ "$DRY_RUN" == 1 ]]; then
  echo "DRY: write $DEST_CLAUDE (stamped v$VERSION)"
else
  sed "s/vX\.Y/v$VERSION/g" "$SRC/CLAUDE.md" > "$DEST_CLAUDE"
fi

# 3. Make hooks executable
if [[ "$DRY_RUN" == 1 ]]; then
  echo "DRY: chmod +x $TARGET/.claude/hooks/*.sh"
else
  chmod +x "$TARGET"/.claude/hooks/*.sh 2>/dev/null || true
fi

# 4. Append gitignore snippet once
GI="$TARGET/.gitignore"
if [[ -f "$SRC/gitignore.snippet" ]]; then
  if [[ ! -f "$GI" ]] || ! grep -qF 'managed by ccc' "$GI"; then
    if [[ "$DRY_RUN" == 1 ]]; then
      echo "DRY: append gitignore.snippet → .gitignore"
    else
      { [[ -f "$GI" ]] && printf '\n'; cat "$SRC/gitignore.snippet"; } >> "$GI"
    fi
  fi
fi

# 5. Record the source checkout for /sync-config
if [[ "$DRY_RUN" == 1 ]]; then
  echo "DRY: write .claude/.ccc-source = $CCC_ROOT"
else
  printf '%s\n' "$CCC_ROOT" > "$TARGET/.claude/.ccc-source"
fi

echo "done."
echo "next:"
echo "  - cp $TARGET/.claude/settings.local.json.example $TARGET/.claude/settings.local.json   # personal overrides (optional)"
echo "  - trim stack @imports you don't need in $TARGET/CLAUDE.md"
echo "  - review $TARGET/.claude/settings.json permissions"
