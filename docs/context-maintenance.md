# Context maintenance (standard flow)

Long-running seats accumulate context, which makes every turn slower and costlier. Run this flow when a seat crosses
the compact threshold (`rig compact-plan` flags it; `rig usage top` shows who burns the most).

The orchestrator owns the pass and works **one seat at a time**:

1. **Pause + checkpoint.** Ask the seat to stop taking new work and send back its current state: what it is doing, open
   items, decisions, files/branches touched, next steps. Wait for the reply; don't poll-capture in a loop.
2. **Record the restore packet** durably (file or qitem the orchestrator owns).
3. **Compact.** `rig compact-plan`, then `rig compact <session>` (prep -> /compact -> restore -> audit). If the seat isn't
   safely compactable (stale/unknown context, not ready), stop and report the blocker. Use `rig handover` only if compact fails.
4. **Verify continuity** (the seat can restate its state from the packet), then resume it.
5. **Next seat.** When all are done or blocked, report to the human: per seat, outcome and anything lost.

`rig compact-plan` is read-only and compaction needs explicit operator authorization, so the human approves each pass.
A `context-usage-threshold` watchdog (`rig watchdog register --help`) can trigger the request.
