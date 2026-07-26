# RESEARCH LOG

Two kinds of entry live here, and they are kept apart on purpose.

**Ecosystem findings** come from `setup/RESEARCH_PROTOCOL.md`, which runs at every
bootstrap and at every project's periodic audit. Each finding is recorded with its date,
what it would change, what it costs, and a verdict — **including rejections**, so the next
pass does not spend budget re-litigating a decision that was already made. A research pass
asks "what changed since the last dated entry below?", so the dates are load-bearing.

**Backflow findings** come from projects USING the kit (`setup/INTERVIEW.md` Phase 5,
and the audit question in `docs/UPDATING.md`). A project learns something the hard way, and
the lesson belongs in the kit rather than in that one project. This section is why the kit
is not a static template.

Nothing is written here as a summary of something else. If a finding changed the kit, the
change is in `CHANGELOG.md` and the rule is in the file it governs; this log records **why**,
which is the part that gets lost.

---

## Last ecosystem research pass

**Never run.** The kit was extracted from a working project on 2026-07-26 without a
research pass of its own. The first `bootstrap.sh` run must therefore treat every
ecosystem claim in these files as unverified and run `setup/RESEARCH_PROTOCOL.md` from
scratch.

---

## Ecosystem findings

_(none yet — the first entries arrive with the first research pass)_

---

## Backflow findings

### 2026-07-26 — from the founding project (the codebase this kit was extracted from)

A Unity + .NET multiplayer game written almost entirely by CLI agents (Claude Code and
Codex). The findings below are what it paid for in real budget and real broken gates. They
are the kit's founding content, not later additions.

#### 1. Gates tend to fail OPEN, and a fail-open gate is worse than no gate — ACCEPTED

Three of that project's three gates were fail-open when first written, and every one of
them printed PASS while protecting nothing:

- The cross-model review script exited 0 when `git` produced no change set, so "nothing to
  review" and "the diff could not be collected" looked identical.
- The engine test gate wrote its results file to a path resolved against the ENGINE's
  working directory, not the shell's. The file landed where nobody looked, the engine
  exited 0 for a run that executed zero tests, and the gate reported PASS.
- The state-file rot gate counted every non-blank line under a heading as "active work",
  including the heading's own placeholder hint, so its condition could never be true.

The failure mode is identical in all three: the gate was verified GREEN and never verified
RED. Nobody had ever seen it fail. A gate that has only been observed passing is an
untested branch that runs in production on every commit.

What went into the kit: the rule that **a gate is not finished until it has been proven to
go RED**, and — because a one-off manual proof rots the moment the script changes — the
requirement that every gate ships with an automated NEGATIVE TEST that constructs the
failure condition and asserts the gate rejects it. `core/scripts/check.sh --self-test` is
the worked example.

#### 2. Gates, CI and review tooling are themselves a high-risk area — ACCEPTED

A broken gate disables every other protection SILENTLY. That makes gate code the single
highest-leverage place a defect can land: one wrong line there costs more than a wrong line
almost anywhere else, and it costs it invisibly, for as long as nobody looks.

The observation that proved it: **the session that wrote a gate could not validate its own
gate.** It ran the script, saw PASS, and reported the gate as working — while the gate was
structurally incapable of failing. A fresh reviewing session found it in minutes. That is
the review-gate invariant ("the author of a change never reviews it") demonstrated on the
review machinery itself.

What went into the kit: `core/docs/REVIEW_GATE.md` lists **gates, CI configuration, check
scripts and review tooling** as a PERMANENT risky area, present in every project regardless
of what that project does. It is the one entry in that list that is not a placeholder.

#### 3. The cross-session state file bloats, and pruning it destroys permanent knowledge — ACCEPTED

That project's `STATE.md` reached 906 lines / roughly 18K tokens — a bill paid at the start
of every session, in every tool. Two independent causes:

- **Completed work accumulated as a diary.** Items were marked DONE instead of deleted, so
  the file grew monotonically and the reader had to skim history to find the present.
- **Permanent lessons had nowhere else to live.** This is the dangerous one. Pruning a
  transient file buries permanent knowledge in the git history, where nobody looks for it.
  Git is an audit trail, not a knowledge base: "why is this rule here" is not a question
  anyone answers with `git log -p`.

What went into the kit, as four separate mechanisms because they fail separately:

- **The routing rule.** Before deleting a line, ask: *is this still true next month?* If
  yes, it must have a permanent home BEFORE it leaves. Homes: a design decision → the
  design document; a module or boundary → the architecture map; a process or gate
  constraint → the workflow doc; an environment or tooling trap → `GOTCHAS.md`. Permanent
  knowledge is never written INTO the state file; it passes THROUGH it.
- **Tagging at write time.** A line worth keeping is prefixed `[LESSON]` or `[GOTCHA]` the
  moment it is written. Harvesting is then a `grep`, not a re-read of the whole file — and
  the tag doubles as a flag meaning "this line may not be deleted until it has a home".
- **The template rule.** Completed work is DELETED, not marked DONE; the dates live in git.
  A multi-item operation tracks its progress in its OWN file with checkboxes, not as a
  growing list in the state file.
- **The gate, deliberately WITHOUT a fixed line limit.** Length alone is the wrong signal:
  1000 lines is healthy in the middle of a long operation and rot the day after it closes.
  The script can tell the two apart — it FAILS when the "Active work" section is empty
  while the file is still long, and stays quiet (or emits an informational note) while work
  is genuinely in flight. Note that this very parser was finding #1's third fail-open gate:
  it must count STRUCTURAL MARKERS (bullets), never lines, and must ignore placeholder and
  hint prose. It ships with a negative test.
- **The ritual.** The last acceptance item of every multi-item operation is *"the state
  file has been harvested and pruned"*.

#### 4. Parsing CLI output: strip ANSI, and never pass an empty field silently — ACCEPTED

The review wrapper extracted the run's token usage by grepping the CLI transcript. It
silently produced nothing, because the CLI wraps that phrase in ANSI colour codes — the
archived report recorded `tokens used<ESC>[0m` with no number, and nobody noticed, because
an empty field looks like a field.

What went into the kit: `core/scripts/review.sh` strips ANSI escapes before matching, and
an extracted field that comes out empty is REPORTED as not found rather than written as
blank. Same shape as finding #1 — absent evidence must be visible, not silent.

#### 5. A placeholder inside a comment is a fail-open gate waiting to happen — ACCEPTED

Found by the kit's own first end-to-end run, not by a project using it. `scripts/check.sh`
carried a `# {{BOUNDARY_CHECKS}}` line meant to be replaced in place. The first fill
substituted the marker but left the leading `#` on the first line, so the entire boundary
check sat inside a comment. The gate reported `CHECK: PASS`, enforcing nothing — finding #1
reproduced, in the very script written to prevent it, within an hour of writing it.

That is the useful part: the trap is not a lapse of care, it is a property of the design.
Any "replace this marked line with code" instruction can be half-followed, and a half-
followed edit to a gate fails silently by default.

What went into the kit: the checks and their negative tests live in their own sourced files
(`scripts/boundary_checks.sh`, `scripts/boundary_selftests.sh`), replaced WHOLE. When the
unit of replacement is a file rather than a line, the mistake is not available. Where a
placeholder must stay inline it is now a VALUE in a quoted string, never a statement.

#### 6. A gate's author cannot find its fail-open paths — ACCEPTED

The strongest evidence in this log, because it happened to this kit rather than to the
project it came from. v0.1 was written in one session, its gates were exercised, its
negative tests passed, and it was published with an acceptance record. A cross-model review
then returned **Reject** with seventeen findings, five of which were fail-open paths in the
gates themselves.

The two that matter most were invisible from the inside:

- **A bootstrapped project could never go green.** The placeholder scan flagged markers in
  `setup/INTERVIEW.md` and the module template — two files that carry them on purpose,
  forever, and that `sync-kit.sh` restores if deleted. The author's own acceptance test had
  missed it because that test deleted `setup/` before running the gate. **The verification
  was shaped by the same assumption as the defect.**
- **A failing file-listing became "no matches".** The producer sat on the non-final side of
  a pipeline ending in `|| true`, so a failed `git ls-files` was indistinguishable from a
  clean scan, and the gate went green having scanned nothing. This is finding #1 of this log
  reappearing inside the script written to prevent finding #1.

What went into the kit: the fixes, each with a negative test; `docs/ACCEPTANCE.md` rewritten
to separate what was executed from what was not; and the review report archived under
`docs/reviews/` as evidence rather than summarised.

What is worth keeping beyond the fixes: **an author's negative tests inherit the author's
blind spot.** They prove the failures you thought of. A second model is not a formality on
top of them — it is the only thing that finds the failure mode you designed your test
around. Reviewing gate code by a fresh session is now a permanent, non-placeholder entry in
`core/docs/REVIEW_GATE.md`; this is the third time in two repositories that the rule has
been earned rather than assumed.

#### 7. A review's FIXES are unreviewed code, and they fail the same way — ACCEPTED

Finding #6 ended with seventeen findings fixed and the kit published. A third model then
reviewed the FIXED tree and returned Reject again — eleven findings, two critical. The one
that matters:

Round 1's most serious finding was a scanner whose failure was indistinguishable from a
clean scan, because the producer sat in a pipeline ending `|| true`. The fix introduced
`scan_or_die`, which printed a diagnostic and called `exit 1` on a failed scan. It was
called as `hits=$(scan_or_die … | grep -Ev … || true)`.

`exit` inside a command substitution terminates the SUBSHELL. The diagnostic printed, the
subshell died, the main script carried on and reached `CHECK: PASS`. The fix for the
fail-open scanner was a fail-open scanner. Worse, the repository had by then written the
claim down in two places — the self-test's closing message and the acceptance record both
said the path was "enforced by construction" — so the false belief was now documented,
which is how it survives.

The general shape, and the reason this is a finding rather than a bug report:

- **A fix is written under time pressure, by the party who just accepted the criticism, and
  it is the least reviewed code in the repository.** Everyone's attention is on whether the
  original finding was real. Nobody asks whether the patch is.
- **Fixes cluster in exactly the code that was already subtle enough to get wrong once.**
  The second attempt is not safer than the first; it is written in the same place, by the
  same author, against the same blind spot.
- **A remediation commit tends to be self-certifying.** It ships alongside a document
  asserting the problem is now solved, and that document is what the next reader trusts
  instead of the code.

What went into the kit: `core/docs/REVIEW_GATE.md` states that **fixes made in response to a
review are themselves subject to the gate** — a Reject is not closed by the fixes, only by a
fresh pass over them — and that a claim of "enforced by construction" is a claim requiring a
negative test like any other. Where a construction genuinely cannot be tested, the acceptance
record says so instead of asserting the guarantee.

The mechanical lesson is worth its own line, because it is invisible and general: **in POSIX
shell, a failure signal that must escape a command substitution cannot be an `exit` or a
variable — it has to be a side effect on the filesystem.** The kit's scanner now drops a flag
file, checked by the main shell after every scan has run.

#### 8. A gate aimed at a path that does not exist is worse than no gate — ACCEPTED

Found by applying this kit's own review findings back to the project it came from, which is
the backflow loop working as intended — though in the wrong order: the fix landed in the
project first and reached the kit afterwards, which is exactly the drift `docs/UPDATING.md`
warns against.

That project's highest-risk check guards its money modules against floating-point
arithmetic:

```sh
hits=$(grep -rn --include="*.cs" -E "float|double" \
  shared/Core.Economy shared/Core.Trade 2>/dev/null | grep -v "// non-monetary:" || true)
```

Neither directory exists yet — that work is scheduled, not started. `grep` exits 2,
`2>/dev/null` hides the reason, `|| true` converts the failure into success, `hits` is
empty, and the most important gate in a project about a player-driven economy had been
printing PASS without reading one line, for its entire existence. Confirmed directly before
anything was changed: exit status 2, no output.

Two distinct traps, and the second is the one worth carrying:

- **A scanner pointed at a missing path is indistinguishable from a scanner that found
  nothing.** Only the exit status separates them, and `|| true` throws it away. This is
  finding #1's shape once more, arriving through a construct that reads as defensive.
- **A gate written ahead of the code it guards accrues the CREDIBILITY of a gate while
  doing nothing.** Everyone can see the check in the script, so nobody re-derives whether
  it fires. When the module finally lands — quite possibly under a slightly different name,
  because names change between planning and building — nothing announces that the gate
  missed it. The gate's silence is identical before and after.

What went into the kit: `core/scripts/boundary_checks.sh` tells the author to declare the
guarded paths in a variable, to check that at least one of them EXISTS, and to print an
explicit dormant notice when none do, rather than scanning nothing quietly. Absent evidence
must be visible — the same rule as finding #1, applied to the target of a scan rather than
to its result. The periodic-audit checklist gained the matching question: *does any gate
guard a path that no longer exists?*

#### 9. Every-session files are a recurring bill, not a style preference — ACCEPTED

Cached input tokens are discounted heavily, which makes the always-loaded prefix — the
constitution, the architecture map, the state file — the largest single cost lever in a
repeated-session workflow. Size there is money, and editing one of those files mid-session
invalidates the cache for every session after it.

What went into the kit: `core/docs/WORKFLOW.md` states the rule (keep always-loaded docs
small and stable, batch documentation edits into their own session, volatile state goes in
the on-demand state file), and the kit's own core files are kept short for the same reason.
`GOTCHAS.md` is explicitly NOT a session-start file — it is referenced from the
constitution in one line and read only when something behaves unexpectedly.
