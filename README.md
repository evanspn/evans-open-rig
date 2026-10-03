# evans-open-rig

My [OpenRig](https://www.openrig.dev) development setup: rig spec templates, agent definitions, culture, and the docs to stand it up.

- `rigs/workshop`: orchestrator + builder + QA + PR watcher
- `rigs/oversight`: standing monitor for token burn / drift
- `docs/`: [setup](docs/setup.md), [architecture](docs/architecture.md), [context maintenance flow](docs/context-maintenance.md)
- `scripts/install.sh`: renders templates and adds them to your spec library

Quick start: `./scripts/install.sh && rig up workshop`
Requires OpenRig CLI (tested on 0.6.4).
