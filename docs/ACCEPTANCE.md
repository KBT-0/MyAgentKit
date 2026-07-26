# What was verified in v0.1, and how

A kit whose central rule is "a gate you have only seen pass has not been tested" cannot ship
on the strength of its author's assurance. This page records what was actually executed, and
— more usefully — what was not.

Anything not listed here was not verified. If a claim elsewhere in this repository is not
backed by something below, that claim is unproven and should be read that way.

## The cross-model review, and what it found

v0.1 was written end to end in a single session by one model. That is exactly the situation
`docs/decorrelated-review.md` says cannot self-validate, so it was reviewed read-only by a
different model (Codex CLI, gpt-5.6-sol, high effort) on 2026-07-26. Report:
[`docs/reviews/20260726T141411Z-master.md`](reviews/20260726T141411Z-master.md).

**Verdict: Reject. Seventeen findings.** Five were fail-open paths in the gates themselves —
in the kit written to prevent fail-open gates:

| What it found | Status |
|---|---|
| A bootstrapped project could NEVER go green: `setup/` and the module template carry markers by design, and the placeholder scan flagged them | fixed — those two paths are exempt, and a case proves the exemption |
| A failed file-listing became "no matches", so the scanners went green having scanned nothing | fixed — the list is collected once into a file and its failure is fatal |
| A missing `boundary_checks.sh` was silently skipped | fixed — missing is now FAIL |
| An unconfigured build/test command was a warning | fixed — now FAIL |
| A missing or renamed `## Active work` heading disabled the rot gate entirely | fixed — both are now FAIL |
| The Unity gate died with `Illegal number` before reaching its zero-test check, and counted skipped tests as executed | fixed — counts validated, skipped excluded, document shape checked |
| `review.sh` exited 0 on an empty diff — the founding project's own bug | fixed — exits 3 |
| `review.sh` ignored failures to write its own report | fixed — unwritable or empty report is FAIL |
| Retrofit could finish "successfully" while leaving an existing no-op gate in place | fixed — bootstrap stops with exit 1 |
| `--self-test` claimed more than it proved | fixed — the message now states what is NOT covered |
| The tool-neutrality framing was false for the shipped automation | fixed — `.claude/` is an overlay; README and `review.sh` say what they target |
| "Local PASS == CI PASS" is disproved by this repo's own trap log | fixed — reworded everywhere it appeared |
| `ARCHITECTURE.md` demanded every boundary be enforced while also permitting "not enforced" | fixed |
| Filenames with newlines, or shaped like options, were skipped by the scanner | fixed — `git ls-files -z`, `--`, `-e` |
| `sync-kit.sh` word-split its file list on spaces | fixed |
| The acceptance numbers here were wrong (27 vs 29 files, 33 vs 34 markers) | fixed — see below |
| POSIX claim broader than the implementation | acknowledged, see "Not verified" |

Every finding was checked against the code before being accepted; none was relayed on the
reviewer's authority. Two were confirmed by reproducing them in a scratch shell rather than
by reading: the pipeline-status one and the `Illegal number` crash.

## Verified by execution

**`bootstrap.sh` produces a working skeleton in an empty directory.** 20 files from `core/`
plus 2 from `setup/`, `docs/` subdirectories created, executable bits set,
`docs/kit/.kit-version` written from the changelog. With `--overlay claude-code --overlay
unity`, both overlays land in the right places.

**The gate FAILS in a freshly bootstrapped project** — unfilled markers, and no build
command configured. Exit 1. An unconfigured project is not a green project.

**The gate PASSES once the placeholders are filled**, with `setup/` still present. The
earlier run that "proved" this had deleted `setup/` first, which is how the blocker above
went unnoticed; the current run does not.

**`check.sh --self-test` — ten cases, all observed:**

```
ok — placeholder gate rejects an unfilled marker
ok — placeholder gate ignores setup/ and the module template
ok — rot gate rejects a long file nobody pruned after the work closed
ok — rot gate stays quiet while a real bullet is under 'Active work'
ok — rot gate rejects a MISSING state file
ok — rot gate rejects a renamed 'Active work' heading
ok — boundary checks missing is a FAILURE, not a skip
ok — an unconfigured build/test command is a FAILURE, not a warning
ok — a failing build/test command fails the gate
ok — src/tests boundary gate rejects a forbidden import
```

**The self-test catches a broken gate.** The rot parser was sabotaged the way it broke
originally — counting non-blank lines instead of bullets, so the section's own hint text
reads as work — and the self-test reported FAIL, exit 1. A negative test that cannot detect
the historical bug is not a negative test.

**The self-test refuses to run on a red tree**, and prints the baseline output rather than
asserting why it was red.

**`unity_gate.sh --self-test` — three cases, no Unity installed:** rejects a clean exit that
wrote nothing; rejects a results file that is not an NUnit document; rejects a run in which
every test was skipped. The last two came from the review.

**`review.sh` exits 3 on an empty change set** instead of reporting a silent success.

**`bootstrap.sh` refuses a dangerous retrofit.** Into a repository whose `scripts/check.sh`
was a `exit 0` stub: exit 1, with instructions for both choices.

**`bootstrap.sh` is safe to re-run.** A second run skips existing files and clobbers nothing.

**`--note` writes `docs/kit/BOOTSTRAP_NOTE.md`,** and `setup/INTERVIEW.md` reads it in Phase 0.

**`sync-kit.sh` respects both ownership tiers.** A local edit to project-owned `AGENTS.md`
survived; a local edit to kit-owned `.githooks/pre-commit` was overwritten; the changelog
since the recorded version was printed; `--dry-run` wrote nothing.

**Every shipped script parses.** `sh -n` on all shell scripts, `ast.parse` on the Python
hook, `json.load` on the settings file.

**No Layer 1 file names a tool or a domain.** `core/` mentions no engine, no vendor and none
of the founding project's nouns. The one exception is documented and deliberate:
`scripts/review.sh` names the Codex CLI, because it targets its flags and says so.

**`setup/` is self-contained.** Neither setup document references the kit repository's own
layout.

## NOT verified — read this part

**No second project has been set up with it.** The interview has never been run by an agent
with a real owner answering. That is the biggest unknown, and it is where the placeholders
and the phase ordering will show their edges.

**The ecosystem notes are unresearched.** The kit was extracted without a research pass of
its own; everything it says about specific tools, plugins and model routing is inherited
from one project over about two months and may already be stale. `RESEARCH_LOG.md` records
the baseline as "never run".

**`scripts/review.sh` has never completed a live run from this repository.** Its empty-diff
and argument paths were exercised; a full review through it was not. The report above was
produced by invoking the CLI directly with the same instructions. The kit's own trap log has
the entry for exactly this: a stub validates your argument handling, only a live run
validates the contract.

**The self-test does not prove attribution.** It proves each injection made the gate exit
nonzero, not that the INTENDED check fired rather than a different one reacting to the same
injection. The final message says so.

**The scanner-failure path has no negative test.** It is enforced by construction —
`scan_or_die` exits rather than returning — but nothing injects a broken `git ls-files`.

**The Unity overlay's asmdef layout has not been applied from these files**, and no real
Unity run has gone through `unity_gate.sh`. Only its rejection paths were exercised.

**The editor-side hooks have never been observed firing at a real turn end.** They were
proven by direct invocation with fabricated input.

**POSIX portability is an intention, not a result.** The scripts parse under `dash` and
avoid obvious bashisms, but they rely on `xargs -0`, `grep -r`, `mktemp` and `trap ... EXIT`,
which are common but not guaranteed by POSIX. Only Linux under WSL was tested — no macOS,
no BSD, no Windows.

## How to re-run this

```sh
tmp=$(mktemp -d) && ./bootstrap.sh "$tmp" && cd "$tmp" && git init -q && git add -A
./scripts/check.sh                # expect FAIL: markers remain, no build command
# fill the placeholders and write the two boundary files, then:
./scripts/check.sh                # expect PASS
./scripts/check.sh --self-test    # expect every case observed going red
```
