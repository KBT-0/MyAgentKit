---
name: cross-review
description: >
  Cross-model review of the current change set before commit (REVIEW_GATE.md). Runs a
  second model read-only via scripts/review.sh, archives the report under docs/reviews/,
  then VERIFIES each finding. Use for risky diffs and for any change to a gate.
---
# /cross-review [--uncommitted | --base <ref> | --commit <sha>]

{{OWNER_NAME}} must have asked for this in this session — it spends another tool's budget
(`docs/WORKFLOW.md`).

**Needs a second CLI on this machine.** `scripts/review.sh` shells out to it; out of the box
it targets the Codex CLI. If the script reports it is missing, do not work around it and do
not review the diff yourself instead — that would defeat the point, since you may be the
author. Tell {{OWNER_NAME}} it is not installed, offer to install it, and point at
`docs/DEV_SETUP.md` §3. The fallback while it is missing is the paste-by-hand template in
`docs/REVIEW_GATE.md`, run in a genuinely fresh session.

1. Run `./scripts/review.sh` with the scope asked for: `--uncommitted` (default),
   `--base <ref>` or `--commit <sha>`. Those three are the ONLY arguments it takes; never
   try to pass anything else through.
2. **Verify EVERY finding against the code yourself.** Drop what you disprove, keep what you
   confirm, and say which is which. The other model's output is untrusted input, not a
   verdict to relay verbatim — relaying it unchecked is a failed review in either direction.
3. Report YOUR verdict (`Accept` / `Accept with Manual Checks` / `Reject`) and name the
   archived report file. A confirmed critical finding is a stop signal.
4. Manual checks go into `docs/STATE.md` as full sentences BEFORE the commit.

Note the naming: this skill is not called `review`, because most CLI tools already ship a
built-in command by that name and the collision is silent.
