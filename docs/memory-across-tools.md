# If it is not in the state file, it did not happen

Chat history does not survive a session, and it certainly does not cross tools. Whatever the
last session worked out — why that approach was abandoned, which check was run, what the
owner decided — is gone unless someone wrote it down in a place the next tool reads.

So there is one file, read at the start of every session by every tool, that says what is
true right now. `docs/STATE.md`. Writing it at session end is the agent's job, not the
owner's; an owner who has to summarise their agent's work is doing the agent's filing.

## Tool-specific memory is scratch, never canonical

Every tool now ships a memory feature: auto-memory, goals, persistent session notes,
project knowledge. Use them if you like, but **none of them is the record**, because the
next tool cannot read them. A cross-tool workflow whose memory is per-tool forgets at every
boundary, and worse, it forgets *selectively* — each tool remembers its own half.

The same reasoning rejects vector and semantic memory layers, and it is worth stating
plainly because they are tempting:

- **Recall is non-deterministic.** Rules must ALWAYS load, not usually be retrieved. A
  constitution that is 90% likely to be in context is not a constitution.
- **It lives outside git**, so it cannot be diffed, reviewed, rolled back, or blamed.
- **It diverges** from the canonical file, and then you have two memories that disagree with
  no mechanism to notice.

Reopen that decision if a setup genuinely needs cross-PROJECT recall. Within one repository,
git plus one small file wins on every axis that matters.

## The hard part: it must stay small

A state file read every session is a bill paid every session. The founding project's reached
906 lines — about 18,000 tokens, per session, per tool — from two causes that need different
fixes.

**Completed work accumulated as a diary.** Items were marked DONE instead of deleted. Fix:
*completed work is DELETED, not marked DONE.* The dates live in git. A multi-item operation
tracks progress in its own file with checkboxes, not as a growing list here.

**Permanent lessons had nowhere else to live.** This is the dangerous one, because the
obvious fix makes it worse: prune the file and the lesson is buried in the git history,
where nobody looks. Git is an audit trail, not a knowledge base — "why is this rule here" is
not a question anyone answers with `git log -p`.

The fix is a routing rule plus a tag:

- **Before deleting a line, ask: is this still true next month?** If yes, it must reach a
  permanent home BEFORE it leaves — `PROJECT.md`, the architecture map, the workflow,
  or the trap log. Permanent knowledge is never stored in the state file; it passes THROUGH
  it.
- **Tag it when you write it.** `[LESSON]` or `[GOTCHA]`. Harvesting is then a grep rather
  than a re-read of everything, and the tag doubles as a flag: a tagged line may not be
  deleted until it has a home.
- **The last acceptance item of every multi-item operation is "state file harvested and
  pruned"**, or it does not happen.

## The gate, and why it is not a line limit

A fixed line limit is the wrong signal. A thousand lines is healthy in the middle of a long
operation and rot the day after it closes — same length, opposite meaning. The gate keys on
something that can tell them apart: an EMPTY "Active work" section on a long file means the
operation closed and nobody pruned. While work is genuinely in flight, length is free.

That parser was itself fail-open once: it counted lines, so the section's own hint text read
as work and the gate could never fire. It counts structural markers now — bullets — and
ignores prose, and it ships with a negative test. See
[gates-must-be-proven-red](gates-must-be-proven-red.md).

## The failure mode it prevents

The second session rediscovering what the first one already learned, at full token price,
and then reaching a different conclusion. Multiplied across tools and weeks, that is most of
what makes long agent-driven projects feel like they are going backwards.
