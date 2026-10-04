# Architecture

## workshop (the development rig)
| Pod | Seat | Agent | Runtime |
|---|---|---|---|
| orchestration | orchestrator | shipped `orchestration/orchestrator` | claude-code |
| implementation | builder | shipped `development/implementer` | claude-code |
| implementation | qa | local `agents/qa` | claude-code |
| delivery | pr-watcher | local `agents/pr-watcher` | claude-code (haiku 4.5) |
| security | reviewer | local `agents/security-reviewer` | claude-code (opus 5.5) |

| Seat | Rig policy (recorded) | Claude Code rules (enforced by the harness) |
|---|---|---|
| orchestrator, builder | `builtin:standard` | project `.claude/settings.json` from `scripts/apply-deny-rules.sh` (they ship with OpenRig) |
| qa | `builtin:standard` | role `dev`: deny list, rig verbs and read-only git allowed, edits inside the project |
| pr-watcher | `builtin:locked` | role `watch`: read PRs and CI; merging asks (standard) or is allowed (permissive); no edits, no pushes, no `gh api` |
| security reviewer | `builtin:locked` | role `review`: read-only, no commits, pushes or merges |
| oversight monitor | `builtin:locked` | role `monitor`: read rig state and send messages only, no edits, no `gh` |

Work flows orchestrator -> builder -> QA -> pr-watcher; the pr-watcher routes failures back to the builder. The security reviewer is consulted by the orchestrator or builder on trust-boundary changes and is not a gate on routine work.
Handoffs are durable queue rows, not chat (see `rigs/workshop/CULTURE.md`).

## oversight (standing monitor)
One cheap-model seat (`monitor`) that watches other rigs for loops, drift and token burn, nudges the owning
orchestrator, and escalates to the human. One oversight rig serves all project rigs.

## Not included
The always-on `kernel` rig ships with OpenRig. Project-specific rigs and ad-hoc seats (e.g. a design seat) are intentionally left out. The agent-file rules in `rigs/workshop/agents/AUTHORING.md` explain how to add one.
