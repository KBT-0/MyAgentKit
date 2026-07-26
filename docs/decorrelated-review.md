# The author of a change never reviews it

An agent that has just written a patch is the worst possible reviewer of it. Not because it
is careless — because it is inside the assumption. The reasoning that produced the bug is
still in its context, still looking correct, and asking it to check its own work mostly
produces a confident restatement of the same reasoning.

So: **review happens in a FRESH session, and preferably a different model.**

Fresh matters because a new session reads the diff as evidence rather than as a memory.
Different model matters more than most people expect: two agents of the same model share
their blind spots. Running three of them does not give you three opinions, it gives you one
opinion with error bars. The value of a second model is that its mistakes are uncorrelated
with the first's.

## The cleanest evidence for this rule

While building this kit, a session wrote a quality gate, ran it, saw `PASS`, and reported
the gate as working. The gate was structurally incapable of failing — its condition could
never be true. A fresh session found it in minutes.

The author was not sloppy. The author was verifying against the same mental model that
produced the defect, and that model said the gate was fine. No amount of care fixes that,
because care is applied through the model.

## What does not count as review

- **A passing compile.** It proves the code is well-formed.
- **Green tests.** Necessary, not sufficient — and if the diff touched the tests, they are
  part of what needs reviewing, not evidence about it.
- **The implementer's self-report.** "Done, 0 errors, all checks pass" is a claim. The whole
  point of the gate is to not take claims.
- **Relaying another model's verdict.** This one catches people out, because it *feels* like
  review. Another agent's output is unverified INPUT to a decision the calling agent owns:
  verify each finding against the code, drop what you disprove, keep what you confirm, and
  say which is which. Passing a verdict through unchecked is a failed review in either
  direction — and the false clean is the expensive one.

## Never report a verification you did not run

The rule that holds the rest together. If a check could not be executed, the words are "not
run" — not "should pass", not silence.

The temptation is strongest exactly where it is most damaging: at the end of a long task,
with everything else green, when the missing check is the slow one. A single fabricated
"verified" makes every other report in the file worthless, because the reader can no longer
tell which ones were real.

## Keeping it affordable

Review costs budget, so it is scoped rather than universal. Risky diffs get it: the areas
the owner named, plus gates, CI and check scripts in every project. Everything else relies
on the automated gate. And no agent spends the review budget on its own initiative — the
owner asks for it in the session, or it does not happen.

## The failure mode it prevents

A defect that passes every check because the same reasoning wrote the code and the check —
and a review process that produces confident approvals which mean nothing, so the first real
failure arrives with no warning and a paper trail full of green ticks.
