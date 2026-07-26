#!/usr/bin/env sh
# Stop hook (one tool only): if the turn left the gated paths dirty, run the project gate
# before the agent is allowed to finish. Early feedback, not the rule — .githooks/pre-commit
# is the gate that actually holds, for every tool.
#
# Costs nothing when it passes: no model tokens, a silent exit. On failure it returns the
# last lines of the gate output (exit 2 = blocking), which is the only case where the agent
# spends tokens on it.
set -u

input=$(cat)

# The tool sets stop_hook_active when the turn was already continued by this hook. Without
# this guard the session loops forever.
case "$input" in
  *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;;
esac

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0

# Only work in these paths needs the gate; documentation and tooling turns skip it, which is
# why the hook is cheap in practice. Untracked files count — `git status` reports them where
# `git diff` would not.
gated_paths="{{GATED_PATHS}}"
gated_pattern="{{GATED_FILE_PATTERN}}"

# shellcheck disable=SC2086
if [ -z "$(git status --porcelain -- $gated_paths 2>/dev/null | grep -E "$gated_pattern" || true)" ]; then
  exit 0
fi

# No result caching, on purpose: a cache that says PASS for a tree that has since changed is
# worse than a ten-second gate.
if out=$(./scripts/check.sh 2>&1); then
  exit 0
fi

printf '%s\n' "$out" | tail -20 >&2
echo "" >&2
echo "GATE FAILED (Stop hook): the gated paths have uncommitted changes and ./scripts/check.sh is red." >&2
echo "Fix the cause before finishing the task (AGENTS.md). Do not report the gate as passing." >&2
exit 2
