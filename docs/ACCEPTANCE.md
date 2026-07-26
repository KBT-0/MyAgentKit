# What was verified in v0.1, and how

A kit whose central rule is "a gate you have only seen pass has not been tested" cannot ship
on the strength of its author's assurance. This page records what was actually executed on
2026-07-26, and — more usefully — what was not.

Anything not listed here was not verified. If you find a claim elsewhere in this repository
that is not backed by something below, that claim is unproven and should be treated that
way.

## Verified by execution

**`bootstrap.sh` produces a working skeleton in an empty directory.** Run into a fresh
`mktemp -d`: 27 files copied, `docs/` subdirectories created, executable bits set,
`docs/kit/.kit-version` written from the changelog.

**The gate FAILS in a freshly bootstrapped project.** Two independent checks fire: the
placeholder scan lists every unfilled marker, and the build/test guard reports that no
command was configured. Exit status 1. This is the intended behaviour — an unconfigured
project is not a green project.

**The gate PASSES once the placeholders are filled.** A scripted fill of all 33 placeholders
plus hand-written boundary check files reaches `CHECK: PASS`.

**`check.sh --self-test` proves each gate goes red.** Four cases, all observed:

```
ok — placeholder gate rejects an unfilled marker
ok — rot gate rejects a long file nobody pruned after the work closed
ok — rot gate stays quiet while a real bullet is under 'Active work'
ok — src/tests boundary gate rejects a forbidden import
```

The third case is the false-positive direction, and it is not decoration: a gate that always
fires is deleted by the first person it blocks unfairly.

**The self-test itself catches a broken gate.** The rot parser was sabotaged in exactly the
way it broke originally — counting non-blank lines instead of bullets, so the section's own
hint text reads as work. The self-test reported `FAIL — rot gate stayed green on a long file
whose 'Active work' is empty`, exit 1. A negative test that cannot detect the historical bug
is not a negative test.

**The self-test refuses to run on a red tree.** Reports `SELF-TEST INCONCLUSIVE` rather than
passing every case for the wrong reason.

**The Unity gate rejects absent evidence — without Unity installed.** A stub editor that
exits 0 and writes no results file is rejected: `SELF-TEST: PASS — the gate rejects a
successful-looking run with no evidence`. That is the precise scenario in which the original
gate reported success for weeks without executing a single test.

**`bootstrap.sh` is safe to re-run.** A second run into the same directory skipped 27
existing files and clobbered nothing.

**`--note` writes `docs/kit/BOOTSTRAP_NOTE.md`,** and `setup/INTERVIEW.md` reads it in
Phase 0.

**`sync-kit.sh` respects both ownership tiers.** With a project pinned to an older version:
a local edit to project-owned `AGENTS.md` survived; a local edit to kit-owned
`.githooks/pre-commit` was overwritten; the changelog since the recorded version was
printed; `--dry-run` wrote nothing.

**Every shipped script parses.** `sh -n` on all shell scripts, `ast.parse` on the Python
hook, `json.load` on the settings file.

**No Layer 1 file names a domain.** Grepped for the founding project's nouns and for engine
and vendor names across `core/` and `setup/`. The worked examples are deliberately
framework-neutral.

**`setup/` is self-contained.** Neither setup document references the kit repository's own
layout — an agent reading them inside an installed project has everything it needs.

## NOT verified — read this part

**No second project has been set up with it.** The setup interview has never been run by an
agent with a real owner answering real questions. That is the single biggest unknown, and it
is where the placeholders and the phase ordering will show their rough edges.

**The ecosystem notes are unresearched.** The kit was extracted without a research pass of
its own. Everything it says about specific tools, plugins, MCP servers and model routing is
inherited from one project's experience over about two months and may already be stale. The
first `bootstrap.sh` run is supposed to fix this by running
`setup/RESEARCH_PROTOCOL.md` from scratch; `RESEARCH_LOG.md` records the baseline as
"never run".

**`scripts/review.sh` has never been run against a live reviewing CLI from this
repository.** It is a port of a script that was proven in the founding project, including
its live-run fix — but a port is not a run. The kit's own trap log has an entry about
exactly this mistake: a stub validates your argument handling, only a live run validates the
contract. Budget one real invocation before trusting it.

**The Unity overlay's asmdef layout has not been applied from these files.** It is a
transcription of a working layout, not a fresh execution of these instructions.

**The editor-side hooks have never been observed firing at a real turn end.** They were
proven by direct invocation with fabricated hook input. That the host tool actually calls
them on a real turn is recorded, not claimed.

**Windows and macOS are untested.** Everything above was run on Linux under WSL. The scripts
are POSIX `sh` and avoid GNU-only flags deliberately, but that is an intention, not a
result.

## How to re-run this

```sh
tmp=$(mktemp -d) && ./bootstrap.sh "$tmp" && cd "$tmp" && git init -q && git add -A
./scripts/check.sh          # expect FAIL: placeholders remain
# fill the placeholders, then:
./scripts/check.sh          # expect PASS
./scripts/check.sh --self-test   # expect every gate to be observed going red
```
