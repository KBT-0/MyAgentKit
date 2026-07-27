# Review Gate — Tool-Agnostic (CANONICAL)

Risky diffs pass this gate before commit.

## Invariant

**The session that wrote a patch never reviews or approves it.** Review happens in a FRESH
session — preferably a different tool and the strongest available model, because the value
of a second opinion is that it is decorrelated. A passing compile is not a review;
`scripts/check.sh` PASS is necessary but not sufficient; implementer self-reports ("0
errors", "all tests green") are never validation.

## What counts as a risky diff

A diff is risky when a silent bug in it is expensive, hard to attribute, or slow to
surface. For this project:

{{RISKY_AREAS}}

**Always, in every project, whatever the project does:**

- **Gates, CI configuration, check scripts and review tooling.** A broken gate silently
  disables every other protection in the repository. That makes gate code the
  highest-leverage place a defect can land, and the place where nobody notices for the
  longest. The project this kit came from shipped three gates that printed PASS while
  protecting nothing.
  The observation worth keeping: **the session that wrote a gate could not validate its own
  gate.** It ran the script, saw PASS, and reported success while the gate was structurally
  incapable of failing; a fresh session found it in minutes. That is this document's
  invariant demonstrated on the review machinery itself.
  A gate diff is reviewed for one question above all others: *has this been observed going
  RED, and does an automated negative test keep it that way?*

## What the reviewer reads

Root `AGENTS.md` → `docs/ARCHITECTURE.md` → the diff → ALL callers of every changed public
member (grep them; do not assume). Design authority is `docs/PROJECT.md` — its DECIDED items
are law, and the reviewer never decides an OPEN one.

## Review priorities (in order)

1. **{{TOP_RISK_PRIORITY}}** — the project's own worst failure mode goes first. Any doubt
   here is a Reject.
2. **Boundary violations:** a forbidden dependency crossing a layer; a module reaching into
   another module's internals instead of through its contract.
3. **State and persistence correctness:** an operation that must be atomic actually is —
   state may never end up half-written, duplicated, or lost on a crash or a retry.
4. **Determinism in core logic:** no ambient clock, no static randomness, no hidden global
   state. Clock and randomness are injected, or the code cannot be tested.
5. **Test integrity:** untested changes to core logic, or tests weakened, skipped or
   deleted to make a build pass — automatic Reject.
6. **Gate integrity:** if the diff touches a gate, CI or review tooling — was it proven to
   go RED, and did it ship with a negative test?
7. **Regression blast radius:** every caller of every changed public member.
8. **Scope creep:** changes the task did not require. Flag them; do not fix them.
9. **Design conformance:** conflicts with a DECIDED item in `docs/PROJECT.md`, or work
   the current phase in `docs/PHASES.md` puts out of scope.

## Verdicts

`Accept` / `Accept with Manual Checks` / `Reject`.

Manual checks are written to `docs/STATE.md` BEFORE the commit, as full explicit sentences.
Questions of taste, feel, balance or product direction go to {{OWNER_NAME}} — the reviewer
proposes, never decides.

**A Reject is not closed by its fixes.** The fixes go through this gate too, in a fresh
session, and a risky-area diff stays risky when the diff is the remediation. This is not
ceremony: a fix is written by the party that just accepted the criticism, it lands in the
code that was already subtle enough to get wrong once, and it ships beside a document
asserting the problem is now solved — which is what the next reader trusts instead of the
code. This kit's own first remediation replaced a fail-open scanner with a differently
fail-open scanner, and wrote "enforced by construction" in two places while it was false.

For the same reason, **"enforced by construction" is a claim that needs a negative test**,
exactly like any other. Where a construction genuinely cannot be tested, say so in the
acceptance record instead of asserting the guarantee.

## Running it

`./scripts/review.sh [--uncommitted | --base <ref> | --commit <sha>]` collects the change
set with git, hands it to a read-only reviewing model carrying THIS document's priority
order, archives the report as evidence under `docs/reviews/<UTC-timestamp>-<branch>.md`
(model, reasoning effort, sandbox, scope, HEAD) and prints it. The script accepts no other
flags: read-only is enforced there rather than trusted to a CLI or to the caller's good
intentions.

**The output is unverified INPUT.** The requesting agent verifies every finding against the
code, drops what it disproves, keeps what it confirms, and owns the verdict. Relaying a
reviewer's verdict verbatim — in either direction — is a failed review. A confirmed
critical finding is a stop signal.

Reviews cost budget: {{OWNER_NAME}} must have asked for one in this session. Agents do not
spend it on their own.

## Template to paste (tools without a wrapper)

```
You are the safety diff reviewer for {{PROJECT_NAME}}. You are READ-ONLY: no file edits,
no state-changing commands.

Read AGENTS.md, docs/ARCHITECTURE.md and docs/REVIEW_GATE.md, then review the diff below
in the REVIEW_GATE.md priority order. Grep the callers of every changed public member.

Report each finding with the file, the line, why it is wrong, and how it fails concretely,
so the calling agent can verify or disprove it independently. Finish with a line
"VERDICT: Accept" / "VERDICT: Accept with Manual Checks" / "VERDICT: Reject", followed by
any manual checks written as full sentences ready to paste into docs/STATE.md.

[DIFF HERE]
```
