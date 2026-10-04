#!/usr/bin/env bash
# Add this template's Claude Code permission rules to a PROJECT's .claude/settings.json.
#
#   scripts/apply-deny-rules.sh PROJECT_DIR [--posture standard|permissive] [--dry-run] [--replace]
#
# Why: the orchestrator and builder are agents shipped with OpenRig, so their settings cannot carry these rules.
# Claude Code reads PROJECT_DIR/.claude/settings.json for every seat launched in that project, so this covers all of
# them. It merges (adds rules, never removes yours) and is idempotent. --replace first removes every rule this template
# could have added, so going from permissive back to standard really narrows the file (your own rules stay). Back up first if you hand-edit that file.
# Commit the result: a settings file that lives in the repo is reviewed like code.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
project="${1:?usage: $0 PROJECT_DIR [--posture standard|permissive] [--dry-run]}"; shift
posture=standard; dry=0; replace=""
while [ $# -gt 0 ]; do
  case "$1" in
    --posture) posture="${2:?}"; shift 2 ;;
    --dry-run) dry=1; shift ;;
    --replace) replace="--replace"; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ -d "$project" ] || { echo "no such directory: $project" >&2; exit 1; }
target="$project/.claude/settings.json"
if [ "$dry" = 1 ]; then
  tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
  [ -f "$target" ] && cp "$target" "$tmp" || echo '{}' > "$tmp"
  python3 "$HERE/scripts/compose-settings.py" --merge-into "$tmp" dev "$posture" $replace
  diff -u "$target" "$tmp" 2>/dev/null || cat "$tmp"
  exit 0
fi
python3 "$HERE/scripts/compose-settings.py" --merge-into "$target" dev "$posture" $replace
echo "Rules merged into $target ($posture). Restart running seats for them to load; check with /permissions in each."
