#!/usr/bin/env sh
# Unity Test Framework gate — EditMode + PlayMode in batchmode.
#
# Separate from scripts/check.sh on purpose: that one runs on every commit and must stay
# fast, and a batchmode run takes minutes per platform. Run this when Unity-side work is
# finished, and on a schedule if CI can host it.
#
# Usage: unity_gate.sh [--self-test]
#   UNITY_PATH   the editor executable, if `unity` is not on PATH
#   UNITY_PROJECT the project folder (default: unity)
#
# CLOSE THE EDITOR FIRST. Batchmode cannot open a project that already holds a lock file.
set -u
cd "$(dirname "$0")/.."

project_dir="${UNITY_PROJECT:-unity}"
unity_bin="${UNITY_PATH:-unity}"
fail=0

run_gate() {
  if ! command -v "$unity_bin" >/dev/null 2>&1; then
    echo "FAIL [unity]: Unity not found. Set UNITY_PATH to the editor executable."
    return 1
  fi

  mkdir -p "$project_dir/Logs"

  # Unity resolves a relative -testResults path against ITS OWN working directory, not this
  # shell's. The file then lands somewhere nobody looks, Unity still exits 0, and a gate
  # that trusts the exit code reports PASS for a run that executed nothing. So: absolute
  # paths, translated when a Windows .exe is driven from a POSIX shell. (docs/GOTCHAS.md)
  proj=$(cd "$project_dir" && pwd)
  logs="$proj/Logs"
  case "$unity_bin" in
    *.exe)
      if ! command -v wslpath >/dev/null 2>&1; then
        echo "FAIL [unity]: a Windows Unity.exe needs wslpath to translate paths."
        return 1
      fi
      proj=$(wslpath -w "$proj" 2>/dev/null || echo "$proj")
      logs=$(wslpath -w "$logs" 2>/dev/null || echo "$logs")
      ;;
  esac

  cases=0
  for platform in EditMode PlayMode; do
    echo "unity: running $platform tests..."
    results="$project_dir/Logs/test-results-$platform.xml"
    rm -f "$results"
    # -nographics is required on a headless machine; drop it if a test needs a real device.
    "$unity_bin" -batchmode -nographics -runTests -projectPath "$proj" \
      -testPlatform "$platform" \
      -testResults "$logs/test-results-$platform.xml" \
      -logFile - || {
        echo "FAIL [unity]: $platform tests failed — see $results"
        fail=1
      }

    # A gate must not pass on ABSENT evidence. Unity exits 0 for a run that executed
    # nothing, so the results file has to exist and its cases have to be counted.
    if [ ! -f "$results" ]; then
      echo "FAIL [unity]: $platform produced no results file at $results — the run proved nothing."
      fail=1
    else
      n=$(grep -c "<test-case " "$results" 2>/dev/null || echo 0)
      echo "unity: $platform executed $n test(s)."
      cases=$((cases + n))
    fi
  done

  # Zero tests on ONE platform is normal early on. Zero across BOTH means the tests stopped
  # running and nobody noticed, which is exactly what this catches.
  if [ "$cases" -eq 0 ]; then
    echo "FAIL [unity]: no test executed on either platform — check the test assembly and its constraints."
    fail=1
  fi

  return "$fail"
}

# --- negative test --------------------------------------------------------------------
# The interesting failure is not "Unity returned an error" — it is "Unity returned SUCCESS
# and produced nothing", which is how this gate silently passed for weeks once. That case
# needs no Unity install to reproduce: a stub that exits 0 and writes no results file.
self_test() {
  stub=$(mktemp -d)/unity
  printf '#!/bin/sh\nexit 0\n' > "$stub"
  chmod +x "$stub"

  out=$(UNITY_PATH="$stub" UNITY_PROJECT="$project_dir" sh "$0" 2>&1)
  status=$?
  rm -rf "$(dirname "$stub")"

  if [ "$status" -eq 0 ]; then
    echo "SELF-TEST: FAIL — the gate passed a run that executed nothing and wrote no results."
    echo "$out" | tail -5
    return 1
  fi
  case "$out" in
    *"no results file"*|*"no test executed"*)
      echo "SELF-TEST: PASS — the gate rejects a successful-looking run with no evidence."
      return 0 ;;
    *)
      echo "SELF-TEST: FAIL — the gate failed, but not for the absent-evidence reason:"
      echo "$out" | tail -5
      return 1 ;;
  esac
}

case "${1:-}" in
  "")          ;;
  --self-test) self_test; exit $? ;;
  *)           echo "usage: unity_gate.sh [--self-test]"; exit 2 ;;
esac

if run_gate; then
  echo "UNITY GATE: PASS"
else
  echo "UNITY GATE: FAIL"
  exit 1
fi
