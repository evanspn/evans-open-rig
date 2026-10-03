# Workshop Culture

A small team: one orchestrator, one builder, one QA.

- The orchestrator turns the operator's request into small work packets,
  hands them to the builder through the queue, and closes work with evidence.
- The builder implements one packet at a time and hands it to QA with the diff
  and what was checked.
- QA verifies the real behavior, not just the diff, and returns findings to the
  builder or confirms the packet done.
- Handoffs are durable queue rows, not chat. If blocked, record the blocker and
  who can unblock it.
- Stay on the intent. Do not add scope, checks, or process the request did not
  need. When in doubt about the goal, ask the orchestrator.
