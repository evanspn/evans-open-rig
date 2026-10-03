# evans-open-rig

My [OpenRig](https://www.openrig.dev) development setup: rig spec templates, agent definitions, culture, and the docs to stand it up.

## Design paradigm

This rig follows the design thinking from the OpenRig creator's talk on agent populations ("agents are forming civilizations"; link/title: _TODO: add video URL_). The core idea: a fleet of agents behaves like a civilization, so its failures look like human coordination failures, and the fixes are borrowed from how humans solved them.

**Structure**
- **Seat:** a chair with an address (`builder@workshop`). The agent sits in it; the seat holds a stable role/config, a stable address, and wisdom inherited by future occupants.
- **Pod -> rig:** seats that work closely share a pod; pods make a team, the rig. Arrangement lives in YAML plus a `CULTURE.md` for how to work together. Good arrangements get saved as templates (this repo).
- **Intent hierarchy:** project -> mission -> slice (spec, build, test, with proof recorded). Work is described at each altitude so any change traces back to why it exists.
- **Terminal is the wire:** separate harness sessions message each other directly. Not one agent with hidden subagents, not another SDK: a harness for the harnesses.

**Failure modes to design against** (coordination pathologies, not "rogue AI")
- **Bureaucracy / ceremony:** a check is added after a mistake, then checks on the check, until completing the process is the goal. Includes the *recursive proof loop*: polishing proof after the task is done.
- **Doghouse to moonbase:** each step is locally defensible within one context window, yet the sum is something nobody asked for. Ask "does the thing actually need this?" and "how big is the dog?"
- **Just following orders:** approval from an agent that lacks the context to decide. The one near the work has the details, the one above has the big picture, and the decision needs both.
- **Memetic spread:** a bad idea written into a note gets learned and taught onward. Treat it like epidemiology: contact-trace the source, then vaccinate.

**Countermeasures**
- **Distributed context engineering:** give each specialist only the context for its domain, plus a map, a compass, and a way to discover what it doesn't know. Context is a diff against what the model already knows.
- **Refocus:** at intervals or after compaction, replay the chain of intent from slice up to project and ask whether current work still serves it.
- **Instrument it (agent productivity monitoring):** watch queue activity against real progress. Rising ceremony with falling movement is the alarm; route it to an agent that has the context to analyze it. This is what the `oversight` rig is for.
- **Automate the map (workflows):** a background process tracks plan position and tells the orchestrator where to go next, like GPS for a self-driving car, so it needn't hold the whole sequence in its head.
- **Dedicated rigs for systemic problems:** when a problem recurs, have an agent design a rig to solve it (e.g. an epidemiology rig).

**Takeaway:** the warning is not that swarms go rogue; it is that running agent populations is a new family of software-engineering problems, and the tooling (topology, queues, health views) exists to tackle them.

## Contents

- `rigs/workshop`: orchestrator + builder + QA + PR watcher
- `rigs/oversight`: standing monitor for token burn / drift
- `docs/`: [setup](docs/setup.md), [architecture](docs/architecture.md), [context maintenance flow](docs/context-maintenance.md)
- `scripts/install.sh`: renders templates and adds them to your spec library

Quick start: `./scripts/install.sh && rig up workshop`
Requires OpenRig CLI (tested on 0.6.4).
