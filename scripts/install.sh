#!/usr/bin/env bash
# Render rig templates for this machine and add them to the OpenRig spec library.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$(npm root -g)/@openrig/cli"
[ -d "$PKG/daemon/specs/agents" ] || { echo "OpenRig CLI not found at $PKG (npm i -g @openrig/cli)"; exit 1; }
DEST="${OPENRIG_SPEC_DIR:-$HOME/.openrig/specs}"
for rig in workshop oversight; do
  mkdir -p "$DEST/$rig"
  cp -R "$HERE/rigs/$rig/." "$DEST/$rig/"
  # agent_ref paths resolve relative to the spec file, so compute the relative path to the shipped agents
  REL="$(python3 -c "import os,sys;print(os.path.relpath(sys.argv[1],sys.argv[2]))" "$PKG/daemon/specs/agents" "$DEST/$rig")"
  sed "s#\${OPENRIG_AGENTS}#$REL#g" "$HERE/rigs/$rig/rig.yaml.tmpl" > "$DEST/$rig/rig.yaml"
  rm -f "$DEST/$rig/rig.yaml.tmpl"
  rig specs add "$DEST/$rig" || true
done
rig specs sync
echo "Installed. Launch with: rig up workshop"
