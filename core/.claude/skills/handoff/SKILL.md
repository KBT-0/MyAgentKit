---
name: handoff
description: >
  Produce ONE self-contained implementation prompt to hand current work to another tool,
  model or session. Use at the end of research when the work will be done elsewhere.
  Input: target tool + task summary.
---
<!-- KIT-OWNED: do not edit locally; change it in the kit and re-sync. -->
# /handoff <target> <task summary>

Follow `docs/HANDOFF.md` (canonical) exactly: task and non-goals, file paths verified to
exist right now, restated constraints, acceptance criteria, routing check, a verifiable
Definition of Done, and the "if ambiguous, STOP and ask" rule.

Verify every path and member name with grep or a read before writing it down. A path from
memory sends the implementer to the wrong place and the diff comes back there.

End with the reminder that updating `docs/STATE.md` at session end is the implementer's job.
Full sentences only — the target has no chat memory and no idea what you were doing.
