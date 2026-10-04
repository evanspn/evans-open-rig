# Setup

1. Install OpenRig: `npm i -g @openrig/cli`, then `rig daemon start`. Authenticate Claude Code (and Codex if you use it).
2. `git clone <this repo> && cd evans-open-rig && ./scripts/install.sh`
   - Renders every `*.tmpl` under `rigs/` (rig specs and agent specs) for your machine, composes each seat's Claude Code permission
     fragment from `policies/claude/rules.json`, validates the result with `rig spec validate`, and adds it to the spec library
     (`~/.openrig/specs`, override with `OPENRIG_SPEC_DIR`).
   - Why templates: shipped agents are referenced by relative path to your global install, which differs per machine.
   - `--posture permissive` records `builtin:open` and widens builders and QA for local work (see [SECURITY.md](../SECURITY.md)). Add
     `--no-register` to render and validate into a scratch `OPENRIG_SPEC_DIR` without touching your library.
3. Apply the deny rules to the project the rig will work in (the orchestrator and builder ship with OpenRig and cannot carry them):
   `./scripts/apply-deny-rules.sh <project>` and commit `<project>/.claude/settings.json`. Add `--dry-run` to preview.
4. Launch: `rig up workshop --cwd <project>` (and `rig up oversight`). Check with `rig ps` and `rig policy current --spec ~/.openrig/specs/workshop/rig.yaml`.
5. Confirm enforcement: in a seat run `/permissions`, then try a harmless denied command such as `cat ~/.ssh/config`; it must be refused.
6. Optional: `git config core.hooksPath scripts/hooks` so every push runs `scripts/scan-secrets.sh`.

Customize: edit `rigs/<rig>/rig.yaml.tmpl`, `CULTURE.md`, `agents/*/guidance/role.md`, or `policies/claude/rules.json`, then re-run the installer.
Spec format reference: `rig specs preview workshop` and `rig requirements <spec>`.
