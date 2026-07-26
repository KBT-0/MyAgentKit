#!/usr/bin/env sh
# {{PROJECT_NAME}} quality gate — EVERY agent runs this before finishing a task.
# CI runs the SAME script. There is one definition of "green" in this repository, and it is
# here — which is NOT the same as a promise that local and CI always agree. Same script,
# different machine: file modes, installed tools and locale can all differ (docs/GOTCHAS.md
# has the exit-126 case that kept a pipeline red for weeks). Check the pipeline after
# pushing; do not infer it from a local pass.
#
# Usage: check.sh [--self-test]
#   default      run the gates
#   --self-test  prove the gates actually go RED (the block near the bottom)
#
# ADDING A GATE: add the check, AND add a case to self_test(). A gate without a negative
# test has not been proven to fail — it has only been seen passing, which is not the same
# thing and never was.
#
# EVERY CHECK BELOW MUST FAIL ON ABSENT EVIDENCE. A missing input file, a scanner that could
# not run, a command that was never configured: all FAIL. Silence is not success. Five
# separate paths in an earlier version of this script violated that rule and reported PASS
# while enforcing nothing; a cross-model review found them.
set -u
cd "$(dirname "$0")/.."
fail=0

# Overridable so the self-test can point the rot gate at a synthetic file instead of
# mutating the real one. Nothing else sets it.
STATE_FILE="${STATE_FILE:-docs/STATE.md}"

# Toolchains are commonly installed per-user and then missing from the PATH of git hooks
# and other non-login shells; without this the gate fails for the wrong reason. A VALUE, not
# a line of code — a placeholder that has to be replaced INSIDE a comment is a trap, because
# a half-finished edit leaves the code commented out and the gate silently toothless.
# Example: "$HOME/.dotnet". Leave empty if nothing extra is needed.
toolchain_path="{{TOOLCHAIN_PATH_SETUP}}"
case "$toolchain_path" in
  ""|*"{{"*) ;;
  *) PATH="$toolchain_path:$PATH"; export PATH ;;
esac

# Overridable so the self-test can prove these branches without mutating the repository.
# Nothing else sets them.
BOUNDARY_CHECKS_FILE="${BOUNDARY_CHECKS_FILE:-scripts/boundary_checks.sh}"
BOUNDARY_SELFTESTS_FILE="${BOUNDARY_SELFTESTS_FILE:-scripts/boundary_selftests.sh}"

work=$(mktemp -d) || { echo "FAIL [gate]: cannot create a temp dir; refusing to run blind."; exit 1; }
trap 'rm -rf "$work"' EXIT INT TERM
filelist="$work/files"

# ===========================================================================
# NEGATIVE TESTS — the gates must be proven to REJECT, not merely to accept.
# Run: ./scripts/check.sh --self-test   (deliberately NOT part of pre-commit;
# it invokes the whole gate a dozen times.)
#
# Read the final message carefully: it states what was PROVEN, and what it does not cover.
# An earlier version claimed "every gate was observed rejecting its failure case" while
# several gates had no case at all.
# ===========================================================================
self_test() {
  st_fail=0
  inj=".check-selftest-injected.md"
  trap 'rm -rf "$work"; rm -f "$inj"' EXIT INT TERM

  # A red tree cannot prove that a gate turns red: everything would "fail correctly".
  if ! baseline=$(sh "$0" 2>&1); then
    echo "SELF-TEST INCONCLUSIVE: the baseline gate run exited nonzero on this tree."
    echo "  Every case below would then pass for the wrong reason. Note that this only"
    echo "  tells you the command failed, not why — the output was:"
    printf '%s\n' "$baseline" | sed 's/^/    /' | tail -12
    return 2
  fi
  echo "self-test: baseline is green; injecting failures..."

  # helper: run the gate with an injected condition, expect FAILURE.
  # usage: expect_fail "<label>" env=val ... -- (command run via env)
  expect_fail() {
    label="$1"; shift
    if env "$@" sh "$0" >/dev/null 2>&1; then
      echo "  FAIL — $label: the gate stayed GREEN with its failure condition present."
      st_fail=1
    else
      echo "  ok   — $label"
    fi
  }
  expect_pass() {
    label="$1"; shift
    if env "$@" sh "$0" >/dev/null 2>&1; then
      echo "  ok   — $label"
    else
      echo "  FAIL — $label: the gate fired when it should have stayed quiet (false positive)."
      st_fail=1
    fi
  }

  # --- placeholder gate -----------------------------------------------------
  # The token is assembled at runtime on purpose: written literally, it would sit in this
  # file and the placeholder gate would flag its own source forever.
  printf 'injected by check.sh --self-test: %s%s\n' '{{SELF_TEST' '_TOKEN}}' > "$inj"
  expect_fail "placeholder gate rejects an unfilled marker"
  rm -f "$inj"

  # ...and does NOT fire on the two paths that carry markers forever by design.
  expect_pass "placeholder gate ignores setup/ and the module template"

  # --- STATE.md rot gate, all four branches ---------------------------------
  rot="$work/rot.md"; live="$work/live.md"; noheading="$work/noheading.md"
  {
    echo "# STATE"; echo; echo "## Active work"
    echo "(nothing in flight — this hint line must NOT be counted as work)"; echo
    echo "## History"
    i=0; while [ "$i" -lt 250 ]; do echo "stale line $i"; i=$((i + 1)); done
  } > "$rot"
  {
    echo "# STATE"; echo; echo "## Active work"
    echo "(nothing in flight — this hint line must NOT be counted as work)"
    echo "- a genuine bullet: one task is in flight right now"; echo
    echo "## History"
    i=0; while [ "$i" -lt 250 ]; do echo "stale line $i"; i=$((i + 1)); done
  } > "$live"
  sed 's/^## Active work/## Current things/' "$rot" > "$noheading"

  expect_fail "rot gate rejects a long file nobody pruned after the work closed" STATE_FILE="$rot"
  expect_pass "rot gate stays quiet while a real bullet is under 'Active work'" STATE_FILE="$live"
  expect_fail "rot gate rejects a MISSING state file"        STATE_FILE="$work/absent.md"
  expect_fail "rot gate rejects a renamed 'Active work' heading" STATE_FILE="$noheading"

  # --- the gates that used to be skippable ----------------------------------
  expect_fail "boundary checks missing is a FAILURE, not a skip" \
    BOUNDARY_CHECKS_FILE="$work/absent.sh"
  expect_fail "an unconfigured build/test command is a FAILURE, not a warning" \
    GATE_BUILD_CMD_OVERRIDE=" "
  expect_fail "a failing build/test command fails the gate" \
    GATE_BUILD_CMD_OVERRIDE="false"

  # --- project boundary self-tests ------------------------------------------
  # One case per check in the boundary checks file. Sourced, so it can set st_fail.
  # Its ABSENCE is a failure: a boundary check with no negative test has not been tested.
  if [ -f "$BOUNDARY_SELFTESTS_FILE" ]; then
    . "./$BOUNDARY_SELFTESTS_FILE"
  else
    echo "  FAIL — $BOUNDARY_SELFTESTS_FILE is missing: the project's boundary checks have"
    echo "         no negative tests, so they have never been observed rejecting anything."
    st_fail=1
  fi

  echo
  if [ "$st_fail" -eq 0 ]; then
    echo "SELF-TEST: PASS — each case above was observed making the gate exit nonzero."
    echo "  NOT proven by this: that a nonzero exit came from the INTENDED check rather than"
    echo "  from another one firing on the same injection; and nothing here exercises the"
    echo "  scanner-failure path, which is enforced by construction (see scan_or_die)."
    return 0
  fi
  echo "SELF-TEST: FAIL — a gate did not behave as claimed. It is protecting nothing."
  return 1
}

case "${1:-}" in
  "")           ;;
  --self-test)  self_test; exit $? ;;
  *)            echo "usage: check.sh [--self-test]"; exit 2 ;;
esac

# ---------------------------------------------------------------------------
# The scanners' shared input: every tracked file plus every untracked one git does not
# ignore, NUL-separated so that newlines and spaces in names survive.
#
# Collected ONCE, into a file, and its failure is FATAL. An earlier version ran the
# producer inside a pipeline ending in `|| true`, so a failed `git ls-files` was
# indistinguishable from "no matches" and the gate went green while scanning nothing.
# ---------------------------------------------------------------------------
if git rev-parse --git-dir >/dev/null 2>&1; then
  if ! git ls-files -z --cached --others --exclude-standard > "$filelist"; then
    echo "FAIL [scan]: git ls-files failed — the scanners below cannot see the tree,"
    echo "             so their silence would mean nothing. Fix this first."
    exit 1
  fi
else
  if ! find . -path ./.git -prune -o -type f -print0 > "$filelist"; then
    echo "FAIL [scan]: find failed — the scanners below cannot see the tree."
    exit 1
  fi
fi
if [ ! -s "$filelist" ]; then
  echo "FAIL [scan]: the file list is EMPTY. A scan over nothing always passes, which is"
  echo "             exactly the failure this gate exists to prevent."
  exit 1
fi

# scan_grep <extended-regex> — prints path:line:text for every match.
# Returns 0 on match, 1 on no match, 2 when grep itself failed. A caller that ignores 2 is
# reintroducing the bug above, so callers use scan_or_die.
scan_grep() {
  # -e keeps a pattern starting with "-" from being read as an option; -- ends the option
  # list so a file literally named "-v" is scanned instead of parsed. /dev/null guarantees
  # at least one file argument, so grep never falls back to stdin and always prints names.
  xargs -0 grep -InE -e "$1" -- /dev/null < "$filelist" 2>/dev/null
  st=$?
  [ "$st" -le 1 ] && return "$st"
  return 2
}

scan_or_die() {
  out=$(scan_grep "$1")
  case $? in
    0|1) printf '%s' "$out" ;;
    *)   echo "FAIL [scan]: the scanner failed to run (pattern: $1). Refusing to report a" >&2
         echo "             clean result from a scan that did not happen." >&2
         exit 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# 1) Setup completeness — unfilled placeholders
# ---------------------------------------------------------------------------
# The kit ships double-brace markers for everything the setup interview must decide. While
# any survive, this project has not been set up and every rule below is a half-written
# sentence. That is a FAIL, not a warning.
#
# Two paths are EXEMPT because they carry markers on purpose, forever:
#   setup/                       the interview documents every marker by name
#   MODULE_AGENTS_TEMPLATE.md    a template that is COPIED per module, never filled in place
# Without these exemptions a correctly configured project can never go green — which is
# exactly what happened, and neither file is something the owner may simply delete, because
# sync-kit.sh restores both.
hits=$(scan_or_die '\{\{[A-Z0-9_]+\}\}' | grep -Ev '^(setup/|MODULE_AGENTS_TEMPLATE\.md:)' || true)
if [ -n "$hits" ]; then
  echo "FAIL [setup]: unfilled placeholder markers remain — run setup/INTERVIEW.md:"
  echo "$hits" | head -30
  [ "$(echo "$hits" | wc -l)" -gt 30 ] && echo "              ... and more"
  fail=1
fi

# ---------------------------------------------------------------------------
# 2) STATE.md rot
# ---------------------------------------------------------------------------
# Length alone is NOT the signal. A long state file is healthy in the middle of a long
# operation and rot the day after it closes; a fixed line limit cannot tell those apart.
# This can: an EMPTY "Active work" section means everything left in the file is history,
# and history belongs in git — once the permanent parts have been harvested into their real
# homes (AGENTS.md, "STATE.md discipline").
#
# A missing file or a renamed heading is a FAILURE, not a skip. Skipping there meant the
# whole gate could be disabled by deleting one file or editing one line.
if [ ! -f "$STATE_FILE" ]; then
  echo "FAIL [state]: $STATE_FILE does not exist. It is the cross-session memory and the"
  echo "              rot gate's only input; without it this check proves nothing."
  fail=1
elif ! grep -q "^## Active work" "$STATE_FILE"; then
  echo "FAIL [state]: $STATE_FILE has no '## Active work' heading, so the rot gate cannot"
  echo "              run. Restore the heading rather than removing the check."
  fail=1
else
  lines=$(wc -l < "$STATE_FILE")
  # Count BULLETS, never lines. Prose under the heading is the section's own hint text and
  # must not read as work — it wraps, so any "skip the first line" filter silently counts
  # the second one and defeats the gate. That precise bug shipped once; hence the case in
  # self_test().
  active=$(awk '/^## Active work/{f=1;next} /^## /{f=0} f' "$STATE_FILE" \
    | grep -c "^[[:space:]]*[-*][[:space:]]")
  if [ "$active" -eq 0 ] && [ "$lines" -gt 200 ]; then
    echo "FAIL [state]: $STATE_FILE is $lines lines with an EMPTY 'Active work' section —"
    echo "              the operation closed but the file was never pruned. Harvest the"
    echo "              permanent parts (grep for [LESSON] / [GOTCHA]) into their homes,"
    echo "              then delete the rest: it is in git."
    fail=1
  elif [ "$lines" -gt 400 ]; then
    echo "NOTE [state]: $STATE_FILE is $lines lines with work still active. Not a problem"
    echo "              by itself — but harvest as you go, so the prune is small later."
  fi
fi

# ---------------------------------------------------------------------------
# 3) PROJECT BOUNDARY CHECKS
# ---------------------------------------------------------------------------
# The checks live in their OWN FILE, sourced here, and that is deliberate. An earlier
# version had a commented-out placeholder line to be replaced in place — and the first
# person to fill it left the leading "#" on the first line, so the whole check sat inside a
# comment and the gate silently enforced nothing. When the unit of replacement is a whole
# file, that mistake is not available.
#
# A MISSING file is a FAIL. It used to be skipped, which meant deleting one file removed
# every boundary check without a word.
if [ -f "$BOUNDARY_CHECKS_FILE" ]; then
  . "./$BOUNDARY_CHECKS_FILE"
else
  echo "FAIL [boundary]: $BOUNDARY_CHECKS_FILE is missing. Boundary enforcement is not"
  echo "                 optional; if this project genuinely has no enforceable boundary,"
  echo "                 say so IN that file rather than deleting it."
  fail=1
fi

# ---------------------------------------------------------------------------
# 4) Build & tests
# ---------------------------------------------------------------------------
# An unconfigured command is a FAIL, not a warning. "No build or test command" is the
# absent-evidence case: the gate would be reporting that nothing failed, having run nothing.
build_test_cmd="{{BUILD_TEST_COMMAND}}"
[ -n "${GATE_BUILD_CMD_OVERRIDE:-}" ] && build_test_cmd="$GATE_BUILD_CMD_OVERRIDE"
case "$build_test_cmd" in
  *"{{"*|""|" ")
    echo "FAIL [build]: no build/test command is configured in scripts/check.sh. Set one —"
    echo "              use 'true' explicitly if this project genuinely has nothing to run,"
    echo "              so that the choice is visible in the diff instead of implied."
    fail=1 ;;
  *)
    sh -c "$build_test_cmd" || fail=1 ;;
esac

if [ "$fail" -eq 0 ]; then echo "CHECK: PASS"; else echo "CHECK: FAIL"; exit 1; fi
