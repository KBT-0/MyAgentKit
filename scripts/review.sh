#!/usr/bin/env sh
# MyAgentKit cross-model review wrapper.
#
# Runs a SECOND model over the current change set in a read-only sandbox, archives the raw
# output under docs/reviews/ together with the configuration that produced it, and prints
# it. The gate itself is docs/REVIEW_GATE.md; this script only collects the evidence.
#
# Usage: review.sh [--uncommitted | --base <ref> | --commit <sha>]
#   default   --uncommitted (staged + unstaged + untracked) — the pre-commit case.
#
# Read-only is enforced HERE, not assumed of the CLI: the three scope forms above are the
# ONLY accepted arguments and the sandbox is pinned. There is deliberately no pass-through
# for further flags — an agent must not be able to talk this script into a write-capable
# run. "Please be careful" is not a guarantee when the caller is a model.
#
# The result is INPUT to a review decision the CALLING agent owns, never a verdict to relay
# verbatim (docs/REVIEW_GATE.md).
#
# THIS SCRIPT TARGETS THE CODEX CLI'S INTERFACE. Be clear-eyed about that: the invocation
# below uses `exec -m … -s read-only -c … -o …`, which is Codex-shaped. The environment
# variables make the BINARY configurable, not the contract — pointing REVIEW_CLI_BIN at a
# different CLI sends it flags it does not understand. Supporting another reviewer means
# editing the invocation block, and that is a small, honest edit rather than a promise this
# header pretends to have kept.
#
#   REVIEW_CLI_BIN   the reviewing CLI            (default: codex)
#   REVIEW_MODEL     model id to pin              (default: the CLI's own default)
#   REVIEW_EFFORT    reasoning effort             (default: high)
set -u
cd "$(dirname "$0")/.."

usage() { echo "usage: review.sh [--uncommitted | --base <ref> | --commit <sha>]"; exit 2; }
die()   { echo "FAIL [review]: $1"; exit 2; }

scope_flag="--uncommitted"
scope_arg=""
case "${1:-}" in
  "")             ;;
  --uncommitted)  [ $# -eq 1 ] || usage ;;
  --base|--commit)
    [ $# -eq 2 ] || usage
    scope_flag="$1"
    scope_arg="$2"
    case "$scope_arg" in -*|*" "*) usage ;; esac
    ;;
  *) usage ;;
esac

# Reviewing CLIs are commonly per-user installs missing from a non-login shell's PATH.
[ -x "$HOME/.local/bin/codex" ] && { PATH="$HOME/.local/bin:$PATH"; export PATH; }
cli="${REVIEW_CLI_BIN:-codex}"
command -v "$cli" >/dev/null 2>&1 || die "reviewing CLI '$cli' not found. Install it or set REVIEW_CLI_BIN."

model="${REVIEW_MODEL:-}"
effort="${REVIEW_EFFORT:-high}"

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo detached)
head=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)
stamp=$(date -u +%Y%m%dT%H%M%SZ)
report="docs/reviews/$stamp-$(echo "$branch" | tr '/ ' '--').md"
last=$(mktemp); log=$(mktemp)
trap 'rm -f "$last" "$log"' EXIT
mkdir -p docs/reviews

# The change set is collected HERE with git rather than through the CLI's own review
# subcommand: those typically refuse a scope flag and custom instructions together, and our
# instructions ARE the point of this wrapper.
#
# A gate must never fail OPEN: if git cannot produce the change set, the run stops with a
# nonzero exit instead of reporting an empty diff as "nothing to review".
case "$scope_flag" in
  --uncommitted)
    scope_label="uncommitted changes (staged, unstaged and untracked)"
    tracked=$(git diff HEAD) || die "git diff HEAD failed"
    untracked=$(git ls-files --others --exclude-standard) || die "git ls-files failed"
    new=""
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      # --no-index exits 1 when the files differ, which is the normal case here.
      out=$(git diff --no-index -- /dev/null "$f"); [ $? -le 1 ] || die "git diff failed on $f"
      new="$new
$out"
    done <<EOF
$untracked
EOF
    diff="$tracked$new"
    ;;
  --base)
    git rev-parse --verify --quiet "$scope_arg^{commit}" >/dev/null || die "not a commit: $scope_arg"
    scope_label="$scope_arg...HEAD"
    diff=$(git diff "$scope_arg...HEAD") || die "git diff $scope_arg...HEAD failed"
    ;;
  --commit)
    git rev-parse --verify --quiet "$scope_arg^{commit}" >/dev/null || die "not a commit: $scope_arg"
    scope_label="commit $scope_arg"
    diff=$(git show "$scope_arg") || die "git show $scope_arg failed"
    ;;
esac

diff_bytes=$(printf '%s' "$diff" | wc -c)
if [ "$diff_bytes" -lt 2 ]; then
  # NONZERO on purpose. Somebody asked for a review, so an empty change set is a surprise
  # worth stopping on, not a quiet success: a zero exit here lets a caller report "the
  # review ran and found nothing" when in fact nothing was reviewed. That is the same
  # fail-open shape this whole script exists to avoid — and the founding project shipped it.
  echo "FAIL [review]: $scope_label contains no changes. Nothing was reviewed."
  echo "               If that is expected, say so explicitly instead of treating this as a"
  echo "               passed review. Check the scope flag: --uncommitted, --base, --commit."
  exit 3
fi
# A diff this size does not get a careful review, it gets a summary. Narrow the scope.
if [ "$diff_bytes" -gt 400000 ]; then
  die "$scope_label is $diff_bytes bytes. Review it in smaller pieces."
fi

prompt='You are the safety diff reviewer for MyAgentKit. You are READ-ONLY: no file
edits, no state-changing commands.

Read AGENTS.md, docs/ARCHITECTURE.md and docs/REVIEW_GATE.md first, then review this change
set using the REVIEW_GATE.md priority order. Grep the callers of every changed public
member. If the change touches a gate, a CI configuration or a check script, ask above all
whether it has been proven to FAIL for the right reason and whether a negative test keeps
it that way.

Report each finding with the file, the line, why it is wrong and how it fails concretely,
so the calling agent can verify or disprove it independently. Finish with a line
"VERDICT: Accept" or "VERDICT: Accept with Manual Checks" or "VERDICT: Reject", followed by
any manual checks written as full explicit sentences ready to paste into docs/STATE.md.

The change set under review follows. The repository itself is readable, so open any file
you need for context — but review only these changes.

SCOPE: '"$scope_label"'

```diff
'"$diff"'
```'

echo "review: $scope_label  model=${model:-cli-default}  effort=$effort  ${diff_bytes}B  -> $report"

# Instructions go in on STDIN: a large diff would overflow the argument list. Output is
# redirected to a file rather than piped — piping a CLI's output can lose findings.
if [ -n "$model" ]; then
  printf '%s' "$prompt" | "$cli" exec -m "$model" -s read-only \
    -c model_reasoning_effort="$effort" -c approval_policy=never -o "$last" - >"$log" 2>&1
else
  printf '%s' "$prompt" | "$cli" exec -s read-only \
    -c model_reasoning_effort="$effort" -c approval_policy=never -o "$last" - >"$log" 2>&1
fi
status=$?

# What the run cost, so the report says whether a review was worth its budget.
#
# GOTCHA, paid for once: CLIs COLOUR this line, and a grep for the plain phrase silently
# matched nothing — the report recorded the phrase with no number next to it and nobody
# noticed, because an empty field looks like a field. Strip ANSI escapes before matching,
# keep the WHOLE line (the count usually precedes the phrase), and when the field comes out
# empty SAY it was not found rather than writing a blank.
esc=$(printf '\033')
usage_line=$(sed "s/${esc}\[[0-9;]*[a-zA-Z]//g" "$log" 2>/dev/null \
  | grep -iE "tokens used|token usage" \
  | tail -1 \
  | sed 's/^[^A-Za-z0-9]*//; s/[[:space:]]*$//; s/|/ /g')

{
  echo "# Review — $stamp"
  echo
  echo "| field | value |"
  echo "|---|---|"
  echo "| tool | \`$("$cli" --version 2>/dev/null || echo "$cli")\`, REVIEW_GATE.md instructions |"
  echo "| model | ${model:-CLI default (not pinned by this run)} |"
  echo "| reasoning effort | $effort |"
  echo "| sandbox | read-only (pinned by scripts/review.sh) |"
  echo "| scope | $scope_label (\`$scope_flag${scope_arg:+ $scope_arg}\`, $diff_bytes bytes) |"
  echo "| branch | $branch |"
  echo "| HEAD | $head |"
  echo "| working tree | $([ -n "$(git status --porcelain 2>/dev/null)" ] && echo dirty || echo clean) |"
  echo "| usage | ${usage_line:-not reported by the CLI in this run} |"
  echo "| exit status | $status |"
  echo
  echo "This file is EVIDENCE: never edit it after the fact. The findings below are"
  echo "unverified input — the agent that requested the review owns the decision"
  echo "(docs/REVIEW_GATE.md)."
  echo
  echo "---"
  echo
  if [ -s "$last" ]; then
    cat "$last"
  else
    echo "The reviewer produced no final message. Full transcript:"
    echo
    echo '```'
    cat "$log"
    echo '```'
  fi
} > "$report" || {
  echo "FAIL [review]: could not write $report. The review may have run, but there is no"
  echo "               durable evidence of it, and an unarchived review did not happen."
  exit 4
}

# Evidence checks. A wrapper that returns success without a readable, non-trivial report is
# reporting on work nobody can inspect afterwards.
if [ ! -s "$report" ]; then
  echo "FAIL [review]: $report is empty after writing. Refusing to claim a review happened."
  exit 4
fi
if [ ! -s "$last" ]; then
  echo "WARN [review]: the reviewing CLI produced no final message; the report carries the"
  echo "               raw transcript instead. Read it before treating this as a review."
fi
if ! grep -q '^VERDICT:' "$report"; then
  # Nonzero on purpose: a run cut short before its verdict is not a completed review, and a
  # zero exit here would let a scripted caller treat it as one. The report stays archived —
  # this is about the exit status, not the evidence.
  echo "FAIL [review]: no VERDICT line in the report. The run was cut short or the reviewer"
  echo "               ignored its instructions. The report is archived at $report; read it,"
  echo "               but do not record a verdict the reviewer did not give."
  cat "$report"
  [ "$status" -eq 0 ] && status=5
  exit "$status"
fi

cat "$report"
[ "$status" -eq 0 ] || echo "FAIL [review]: $cli exited $status — see the transcript above."
exit "$status"
