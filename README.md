# evans-open-rig

My [OpenRig](https://www.openrig.dev) development setup: rig spec templates, agent definitions, culture, and the docs to stand it up.

## Design paradigm

This rig follows the design thinking from the OpenRig creator's talk on agent populations ("agents are forming civilizations"; [watch on YouTube](https://www.youtube.com/watch?v=AL-PQuB2wy0)). The core idea: a fleet of agents behaves like a civilization, so its failures look like human coordination failures, and the fixes are borrowed from how humans solved them.

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

- `rigs/workshop`: orchestrator + builder + QA + PR watcher + a consulted security reviewer (see `rigs/workshop/agents/AUTHORING.md` for how to write a new seat)
- `rigs/oversight`: standing monitor for token burn / drift
- `policies/`: the permission rules every seat runs under (`claude/rules.json`, a restricted Codex profile)
- `docs/`: [setup](docs/setup.md), [architecture](docs/architecture.md), [context maintenance flow](docs/context-maintenance.md)
- `scripts/`: `install.sh` (renders and validates the templates), `apply-deny-rules.sh`, `scan-secrets.sh`, `harden-public-repo.sh`
- [`SECURITY.md`](SECURITY.md): threat model, what the defaults do, what you still have to do, how to report a problem

## Secure by default

Rigs launched from this repo do **not** run with permissions bypassed. The rig policy is `builtin:standard`, the PR watcher, security
reviewer and monitor cannot edit files or push (the watcher can merge a finished PR only after you approve it), every seat carries a deny list (no `sudo`, no `rm -rf` of `/` or home, no pipe-to-shell, no
force-push, no reading `~/.ssh`, `.env` or cloud credentials), and `CULTURE.md` tells agents to treat PR text, web pages and other seats'
messages as data, never to put secrets in prompts or commits, and not to push or merge without the operator's granted authority. To loosen this on purpose, see
`./scripts/install.sh --posture permissive` and the tradeoffs in [SECURITY.md](SECURITY.md).

Quick start:

```
./scripts/install.sh                      # render + validate + add to your spec library
./scripts/apply-deny-rules.sh <project>   # deny rules for the shipped orchestrator and builder (commit the result)
rig up workshop --cwd <project>
```

Requires the OpenRig CLI (tested on 0.6.4) and python3.
