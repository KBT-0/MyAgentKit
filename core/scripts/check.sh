#!/usr/bin/env sh
# {{PROJECT_NAME}} quality gate — EVERY agent runs this before finishing a task.
# CI runs the SAME script, so a local PASS means a CI PASS. There is no second definition
# of "green" anywhere in this repository.
#
# Usage: check.sh [--self-test]
#   default      run the gates
#   --self-test  prove the gates actually go RED (the block at the bottom)
#
# ADDING A GATE: add the check, AND add a case to self_test(). A gate without a negative
# test has not been proven to fail — it has only been seen passing, which is not the same
# thing and never was. Three gates shipped fail-open in the project this kit came from;
# all three printed PASS while protecting nothing.
set -u
cd "$(dirname "$0")/.."
fail=0

# Overridable so the self-test can point the rot gate at a synthetic file instead of
# mutating the real one. Nothing else sets it.
STATE_FILE="${STATE_FILE:-docs/STATE.md}"

# Toolchains are commonly installed per-user and then missing from the PATH of git hooks
# and other non-login shells; without this the gate fails for the wrong reason. A VALUE,
# not a line of code — see the note above section 3 about why that distinction matters.
# Example: "$HOME/.dotnet". Leave empty if nothing extra is needed.
toolchain_path="{{TOOLCHAIN_PATH_SETUP}}"
case "$toolchain_path" in
  ""|*"{{"*) ;;
  *) PATH="$toolchain_path:$PATH"; export PATH ;;
esac

# Files worth scanning: tracked plus untracked-but-not-ignored. Falls back to find when
# this is not a git repository yet (a freshly bootstrapped directory, for instance).
files_to_scan() {
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git ls-files --cached --others --exclude-standard
  else
    find . -path ./.git -prune -o -type f -print
  fi
}

# grep over that list. /dev/null is a guaranteed first argument so grep never falls back
# to reading stdin on an empty list, and always prints filenames.
scan_grep() {
  files_to_scan | tr '\n' '\0' | xargs -0 grep -InE "$1" /dev/null 2>/dev/null || true
}

# ===========================================================================
# NEGATIVE TESTS — the gates must be proven to REJECT, not merely to accept.
# Run: ./scripts/check.sh --self-test   (deliberately NOT part of pre-commit;
# it invokes the whole gate several times.)
# ===========================================================================
self_test() {
  st_fail=0
  tmpdir=$(mktemp -d)
  inj=".check-selftest-injected.md"
  trap 'rm -rf "$tmpdir"; rm -f "$inj"' EXIT INT TERM

  # A red tree cannot prove that a gate turns red: everything would "fail correctly".
  if ! sh "$0" >/dev/null 2>&1; then
    echo "SELF-TEST INCONCLUSIVE: the gate is already FAILING on this tree."
    echo "  Get it green first, then re-run — otherwise every case below passes for the"
    echo "  wrong reason, which is the exact bug this script exists to catch."
    return 2
  fi
  echo "self-test: baseline is green; injecting failures..."

  # --- placeholder gate -----------------------------------------------------
  # The token is assembled at runtime on purpose: written literally, it would sit in this
  # file and the placeholder gate would flag its own source forever.
  printf 'injected by check.sh --self-test: %s%s\n' '{{SELF_TEST' '_TOKEN}}' > "$inj"
  if sh "$0" >/dev/null 2>&1; then
    echo "  FAIL — placeholder gate stayed green with an unfilled marker in the tree."
    st_fail=1
  else
    echo "  ok   — placeholder gate rejects an unfilled marker"
  fi
  rm -f "$inj"

  # --- STATE.md rot gate, BOTH directions -----------------------------------
  # One direction is not enough: a gate that always fails is as useless as one that never
  # does, and the false-positive case is what a naive line-count limit gets wrong.
  rot="$tmpdir/rot.md"
  live="$tmpdir/live.md"
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

  if STATE_FILE="$rot" sh "$0" >/dev/null 2>&1; then
    echo "  FAIL — rot gate stayed green on a long file whose 'Active work' is empty."
    st_fail=1
  else
    echo "  ok   — rot gate rejects a long file nobody pruned after the work closed"
  fi
  if STATE_FILE="$live" sh "$0" >/dev/null 2>&1; then
    echo "  ok   — rot gate stays quiet while a real bullet is under 'Active work'"
  else
    echo "  FAIL — rot gate fired on a file with active work: it is counting prose, not"
    echo "         bullets, and will now block honest work until someone deletes it."
    st_fail=1
  fi

  # --- project boundary self-tests ------------------------------------------
  # One case per check in scripts/boundary_checks.sh. Sourced, so it can set st_fail.
  if [ -f scripts/boundary_selftests.sh ]; then
    . ./scripts/boundary_selftests.sh
  fi

  if [ "$st_fail" -eq 0 ]; then
    echo "SELF-TEST: PASS — every gate above was observed rejecting its failure case."
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
# 1) Setup completeness — unfilled placeholders
# ---------------------------------------------------------------------------
# The kit ships double-brace markers for everything the setup interview must decide. While
# any survive, this project has not been set up and every rule below is a half-written
# sentence. That is a FAIL, not a warning: a constitution with holes in it gets skimmed
# once and ignored thereafter.
hits=$(scan_grep '\{\{[A-Z0-9_]+\}\}')
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
# and history belongs in git — once the permanent parts have been harvested into their
# real homes (AGENTS.md, "STATE.md discipline").
if [ -f "$STATE_FILE" ] && grep -q "^## Active work" "$STATE_FILE"; then
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
# scripts/boundary_checks.sh is sourced, not executed, so it can set `fail=1` and use
# scan_grep. Every check in it gets a matching case in scripts/boundary_selftests.sh.
if [ -f scripts/boundary_checks.sh ]; then
  . ./scripts/boundary_checks.sh
fi

# ---------------------------------------------------------------------------
# 4) Build & tests
# ---------------------------------------------------------------------------
build_test_cmd="{{BUILD_TEST_COMMAND}}"
case "$build_test_cmd" in
  *"{{"*)
    echo "FAIL [setup]: no build/test command was configured in scripts/check.sh."
    fail=1 ;;
  "")
    echo "WARN [build]: no build or test command configured. Acceptable only before the"
    echo "              first code lands — a FAIL after that." ;;
  *)
    sh -c "$build_test_cmd" || fail=1 ;;
esac

if [ "$fail" -eq 0 ]; then echo "CHECK: PASS"; else echo "CHECK: FAIL"; exit 1; fi
