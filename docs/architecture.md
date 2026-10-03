# Architecture

## workshop (the development rig)
| Pod | Seat | Agent | Runtime |
|---|---|---|---|
| orchestration | orchestrator | shipped `orchestration/orchestrator` | claude-code |
| implementation | builder | shipped `development/implementer` | claude-code |
| implementation | qa | shipped `development/qa` | claude-code |
| delivery | pr-watcher | local `agents/pr-watcher` | claude-code (haiku 4.5) |

Work flows orchestrator -> builder -> QA -> pr-watcher; the pr-watcher routes failures back to the builder.
Handoffs are durable queue rows, not chat (see `rigs/workshop/CULTURE.md`).

## oversight (standing monitor)
One cheap-model seat (`monitor`) that watches other rigs for loops, drift and token burn, nudges the owning
orchestrator, and escalates to the human. One oversight rig serves all project rigs.

## Not included
The always-on `kernel` rig ships with OpenRig. Project-specific rigs and ad-hoc seats (e.g. a design seat) are intentionally left out.
