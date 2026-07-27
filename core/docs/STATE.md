# STATE.md — Cross-Session Work State ({{PROJECT_NAME}})

**The one rule: if it is not written here, it did not happen.** Chat memory does not
transfer between sessions or between tools. Updating this file at the end of any session
with meaningful progress is the AGENT'S job, not {{OWNER_NAME}}'s.

This file is TRANSIENT and stays SMALL — current state only. It is read at the start of
every session, in every tool, so its length is a bill paid every session.

**Permanent knowledge is never stored here. It passes THROUGH here into a real home:**

| What you learned | Where it goes |
|---|---|
| A product or design decision | `docs/PROJECT.md`, as a numbered item |
| Something true only until this phase ends | `docs/PHASES.md` |
| A module, boundary or contract | `docs/ARCHITECTURE.md` |
| A process rule or gate constraint | `docs/WORKFLOW.md` |
| An environment or tooling trap | `docs/GOTCHAS.md` |

Before deleting any line, ask: **is this still true next month?** If yes, it must reach its
home BEFORE it leaves this file. Pruning without harvesting buries the lesson in the git
history, and nobody looks there — git is an audit trail, not a knowledge base.

**Tag as you write.** A line worth keeping after this operation is prefixed `[LESSON]`
(process or architecture insight) or `[GOTCHA]` (environment or tooling trap). Harvesting
is then a grep, not a re-read — and a tagged line may not be deleted until it has a home.

**Completed work is DELETED, not marked DONE.** The dates live in git
(`git log -p -- docs/STATE.md`). A multi-item operation tracks its progress in its OWN file
with checkboxes, not as a growing list here; the last acceptance item of every such
operation is "STATE.md harvested and pruned".

Write full, explicit sentences with a tool+model trace per entry. Compressed chat styles do
not apply to this file: the next tool reading it knows nothing about your plugins.

---

## Active work

(task + module + status; delete when done — an EMPTY section means nothing is in flight,
and `check.sh` reads it that way, so never park closed work here)

## Blocked / waiting on {{OWNER_NAME}}

## Next tasks (priority order)

## Deferred / parked

## Known issues / watch out

Environment and tooling traps have a permanent home: **`docs/GOTCHAS.md`**. Read it when
something behaves unexpectedly. What belongs here instead is a check that is outstanding
RIGHT NOW — a manual verification owed before the next commit, a claim that has not been
observed yet.

## Last session summary
