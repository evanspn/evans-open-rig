# Rules for creating agent files

Distilled from the OpenRig "agents form civilizations" talk (see the README). An agent file is a
seat's standing role. The seat outlives any occupant, so the file must carry
what a fresh occupant needs and nothing it should not.

1. **One context domain per seat.** Create a seat only where a distinct body of
   knowledge or rules recurs (security threat-modeling, a design system, a
   production host). If two roles would carry the same context, they are one seat.
   Never create a seat whose only job is watching other seats.
2. **Start from the intent, not the task list.** Open the role with who it
   serves and what "done" means. Say what is out of scope. A narrow script gets
   exactly what was written; intent lets a capable agent decide how.
3. **Give the map, not the territory.** Point at where to read (workspace
   SPEC.md, the slice SPEC, repo paths, docs) and how to discover the rest. Do
   not paste facts that go stale; say how to re-derive them.
4. **Write the failure modes in.** Each role names how it drifts and the stop:
   - doghouse to moonbase: do not add what the request did not need; ask
     "does the thing actually need this?" and "how big is the dog?"
   - ceremony: no checks on checks; hand off as done or record an honest blocker
   - proof polishing: stop once the proof is good enough
   - approvals without context: read at the source and say what you did not check
5. **Be a consultee or an owner, say which.** Owners ship an outcome. Consultees
   return a verdict on a queue row. A consultee never becomes a gate on routine work.
6. **Handoffs are queue rows, not chat.** State what the seat takes in, what it
   returns, and who it hands to. Evidence goes on the row.
7. **Authority is explicit.** List what needs the operator's go-ahead (push,
   merge, deploy, remote hosts, destructive or hard-to-reverse edits) and what
   is always safe (read-only inspection).
8. **Carry the operator's standing rules** for that domain, quoted from their own
   words where possible, so they are never re-asked.
9. **Pick the runtime for the tools.** A seat that needs an MCP server or model
   the operator prefers runs on the runtime that actually has it.
10. **Keep it short.** Under about 100 lines. Skills hold procedure; the role
    holds judgment. Do not copy CULTURE.md into it.
11. **Plan for compaction.** Name the files that hold the seat's durable state
    so a successor can rebuild from them (restore map, queue rows, the model's
    own saved versions).
12. **Learned wisdom is vetted before it spreads.** Anything a seat writes into
    notes that future occupants will read must be true and sourced. Correct bad
    notes at the source, not just in the current chat.
13. **Add it to the rig deliberately.** Validate the file, add the pod to the
    template, and record in the relevant slice SPEC when the seat is consulted.
