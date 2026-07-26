# A gate you have only seen pass has not been tested

This is the kit's signature rule, and it exists because the project it was extracted from
shipped three gates and **all three were fail-open**. Every one of them printed `PASS` while
protecting nothing:

- A review script exited 0 when git produced no change set, so "nothing to review" and "the
  diff could not be collected" were indistinguishable.
- A test gate wrote its results to a path the test runner resolved against its OWN working
  directory. The file landed where nobody looked, the runner exited 0 for a run that
  executed zero tests, and the gate reported success.
- A rot check counted every non-blank line under a heading as "active work" — including the
  heading's own placeholder hint. Its condition could never be true.

Three different authors' worth of care, three different mechanisms, one shared property:
**each had been verified green and never verified red.** Nobody had ever seen one fail.

A gate is a conditional that runs on every commit. The branch you have exercised is the one
where nothing is wrong. The branch that matters — the one that fires — has never executed.
In any other code you would call that untested and you would be right.

## Why this is worse than an ordinary bug

An ordinary bug makes something break. A broken gate makes something **stop breaking**. The
signal you would use to detect the problem is the thing that is broken, so the failure is
not merely undetected — it is undetectable by the normal means. It also invalidates
everything downstream: a green build stops being evidence, and so does every "tests pass"
report written while the gate was dead.

That is why `docs/REVIEW_GATE.md` lists gates, CI and check scripts as a permanent risky
area in every project regardless of domain. It is the highest-leverage place a defect can
land.

## The rule

1. **Build the failure condition. Watch the gate reject it. Undo it.** Before you call the
   gate done, once, by hand.
2. **Ship an automated negative test.** A manual proof is true on the day it is performed
   and rots at the next edit. `./scripts/check.sh --self-test` constructs each failure and
   asserts the rejection.
3. **Test both directions** where false positives are possible. A gate that always fails is
   as useless as one that never does — worse, actually, because it gets deleted by the first
   person it blocks unfairly, taking the real protection with it.
4. **Fail on absent evidence.** No results file, an empty diff, a tool that did not run:
   FAIL. An exit code is not evidence that work happened.
5. **Re-prove on a schedule.** The periodic audit runs the self-test. Gates rot like
   anything else.

## The observation worth keeping

**The session that wrote a gate could not validate its own gate.** It ran the script, saw
PASS, and reported success — while the gate was structurally incapable of failing. A fresh
session found it in minutes.

That is the review-gate invariant demonstrated on the review machinery itself, and it is the
cleanest evidence for it anyone could ask for. The author is not careless; the author is
inside the assumption.

## The failure mode it prevents

The illusion of protection. A team that believes it has boundary enforcement, test
enforcement and review enforcement, and has none of them — which is strictly more dangerous
than a team that knows it has none, because the second one is still watching.
