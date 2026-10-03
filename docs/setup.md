# Setup

1. Install OpenRig: `npm i -g @openrig/cli`, then `rig daemon start`. Authenticate Claude Code (and Codex if you use it).
2. `git clone <this repo> && cd evans-open-rig && ./scripts/install.sh`
   - Renders each `rigs/*/rig.yaml.tmpl` for your machine and adds it to the spec library (`~/.openrig/specs`, override with `OPENRIG_SPEC_DIR`).
   - Why templates: shipped agents are referenced by relative path to your global install, which differs per machine.
3. Launch: `rig up workshop` (and `rig up oversight`). Check with `rig ps`.

Customize: edit `rigs/<rig>/rig.yaml.tmpl`, `CULTURE.md`, or `agents/*/guidance/role.md`, then re-run the installer.
Spec format reference: `rig specs preview workshop` and `rig requirements <spec>`.
