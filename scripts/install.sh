#!/usr/bin/env bash
# Render the rig templates for this machine, validate them, and add them to the OpenRig spec library.
#
#   scripts/install.sh [--posture standard|permissive] [--no-register]
#
#   --posture standard      (default) rig policy builtin:standard; builders and QA get the deny list and prompts for
#                           anything not allow-listed.
#   --posture permissive    rig policy builtin:open and a wider allow list for builders and QA, for attended or unattended
#                           local work. The deny list stays. Read-only seats are never widened. Read SECURITY.md first.
#   --no-register           render and validate into $OPENRIG_SPEC_DIR only; do not run `rig specs add/sync`
#                           (use this to test against a scratch directory).
#
# Environment: OPENRIG_SPEC_DIR (default ~/.openrig/specs) is where rendered specs are written.
# This script never installs builtin:yolo and never edits a running rig.
set -euo pipefail

posture=standard
register=1
while [ $# -gt 0 ]; do
  case "$1" in
    --posture) posture="${2:?--posture needs standard or permissive}"; shift 2 ;;
    --no-register) register=0; shift ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
case "$posture" in
  standard)   RIG_POLICY="builtin:standard" ;;
  permissive) RIG_POLICY="builtin:open" ;;
  *) echo "--posture must be standard or permissive" >&2; exit 2 ;;
esac

HERE="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$(npm root -g)/@openrig/cli"
AGENTS_DIR="$PKG/daemon/specs/agents"
[ -d "$AGENTS_DIR" ] || { echo "OpenRig CLI not found at $PKG (npm i -g @openrig/cli)" >&2; exit 1; }
DEST="${OPENRIG_SPEC_DIR:-$HOME/.openrig/specs}"

relpath() { python3 -c "import os,sys;print(os.path.relpath(sys.argv[1],sys.argv[2]))" "$1" "$2"; }

# Fill a template: the shipped-agents path is relative to the file's own directory, because agent_ref and
# imports resolve relative to the spec file and differ per machine.
render() {
  local src="$1" out="$2" dir agents shared
  dir="$(cd "$(dirname "$out")" && pwd -P)"
  agents="$(relpath "$(cd "$AGENTS_DIR" && pwd -P)" "$dir")"
  shared="$agents/shared"
  sed -e "s#\${OPENRIG_AGENTS}#$agents#g" -e "s#\${OPENRIG_SHARED}#$shared#g" -e "s#\${RIG_POLICY}#$RIG_POLICY#g" "$src" > "$out"
}

for rig in workshop oversight; do
  src="$HERE/rigs/$rig"
  out="$DEST/$rig"
  # never silently overwrite a spec you already have: keep a copy outside the library first
  if [ -f "$out/rig.yaml" ]; then
    backup="$DEST/.backups/$rig.$(date +%Y%m%d%H%M%S)"
    mkdir -p "$DEST/.backups" && cp -R "$out" "$backup" && echo "backed up the existing $rig spec to $backup"
  fi
  mkdir -p "$out"
  # copy everything that is not a template
  (cd "$src" && find . -type f ! -name '*.tmpl' -print) | while read -r f; do
    mkdir -p "$out/$(dirname "$f")"
    cp "$src/$f" "$out/$f"
  done
  # render the templates
  (cd "$src" && find . -type f -name '*.tmpl' -print) | while read -r f; do
    target="$out/${f%.tmpl}"
    mkdir -p "$(dirname "$target")"
    render "$src/$f" "$target"
    # an agent template names its Claude Code permission role; compose its settings fragment from the canonical rules
    role="$(sed -n 's/^# settings-role: *//p' "$src/$f" | head -1)"
    if [ -n "$role" ]; then
      mkdir -p "$(dirname "$target")/runtime"
      python3 "$HERE/scripts/compose-settings.py" "$role" "$posture" > "$(dirname "$target")/runtime/claude-settings.fragment.json"
    fi
  done
  # catch a bad render before it reaches the library
  rig spec validate "$out/rig.yaml"
  if [ "$register" = 1 ]; then
    rig specs add "$out" || echo "note: 'rig specs add $rig' reported an error (already added?); continuing" >&2
  fi
done
if [ "$register" = 1 ]; then
  rig specs sync
  echo "Installed ($posture posture). Launch with: rig up workshop --cwd <your project>"
  echo "Next: scripts/apply-deny-rules.sh <your project>  (covers the orchestrator and builder, which ship with OpenRig)"
else
  echo "Rendered and validated into $DEST ($posture posture); nothing was registered."
fi
