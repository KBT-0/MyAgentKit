# Pattern: a pure core, consumed by an engine

**The problem.** Logic written inside a game engine, a UI framework or any heavy host is
hard to test, slow to iterate on, and welded to that host forever. Every rule needs the
engine booted to exercise it, so in practice it never gets exercised — and when the engine
changes, or you want the same rule on a server, you rewrite it.

For agent-written code this is worse than merely inconvenient. An agent cannot run your
editor. If the rules live where only the editor can reach them, the agent is writing code
nobody can validate until a human opens a GUI.

## The shape

One project holding all the domain logic, in the plain language, with **no reference to the
engine at all**. The engine, the server and any tool are consumers of it.

```
core/          pure logic + tests. Builds and tests with the plain toolchain, no engine.
engine/        presentation, input, rendering. Calls core. Holds no rules.
server/        authority, persistence. Calls the same core.
tools/         batch jobs, simulations. Calls the same core.
```

The rule that makes it real: **an engine import inside the core is a build failure**, not a
code review comment. One grep in the gate, with a negative test proving it fires.

## What you get

- **Tests run in seconds** with the standard test runner, so they actually get written.
- **An agent can work on the logic** with no editor, no license, no GUI.
- **Determinism becomes reachable.** Inject the clock and the randomness rather than reading
  ambient ones, and a bug reproduces from a seed instead of a description.
- **The same rules run in two places** — client-side prediction and server-side authority
  cannot disagree, because there is one implementation.
- **The engine becomes replaceable**, which matters less than it sounds, and **testable in
  isolation**, which matters more.

## What it costs

- An extra project and a package-wiring step, once.
- Discipline at the seam: the temptation to put "just this one rule" in a behaviour script,
  where it is faster to write and impossible to test, is constant.
- Some types must be mapped at the boundary rather than shared.

## Where it goes wrong

**Rules leaking into the host.** A behaviour script that decides something — a price, a
range, whether an action is allowed — has moved a rule outside the tested area. This is the
failure, and it happens gradually. The host layer's job description is: gather input, call
the core, present the result.

**A "shared" layer that becomes a second core.** If the layer between the host and the core
starts holding logic, you now have two cores and the boundary means nothing. Keep it to
glue: type conversion, wiring, host-specific plumbing.

**Treating the boundary as advice.** If nothing fails when it is crossed, it will be
crossed — usually at 2am, in a hurry, with a comment saying "temporary".
