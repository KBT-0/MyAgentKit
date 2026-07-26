# Project boundary checks — SOURCED by scripts/check.sh, never executed on its own.
#
# Available to you here: `scan_grep <extended-regex>` (searches tracked and
# untracked-but-not-ignored files, printing path:line:text) and the `fail` variable.
# Set `fail=1` to fail the build. If the scanner itself fails mid-scan, check.sh fails the
# whole gate at the end — you do not need to handle that case, and `$(scan_grep …)` is safe.
#
# REPLACE THIS WHOLE FILE with your project's checks. Do not edit around the comments —
# the file is the unit of replacement precisely so that a half-edit cannot leave a check
# sitting inside a comment, which is how a gate ends up enforcing nothing.
#
# Every check here needs a matching case in scripts/boundary_selftests.sh. A check that has
# never been observed rejecting anything has not been tested.
#
# Worked example — a domain layer that must not depend on the delivery layer:
#
#   hits=$(scan_grep 'from myapp\.web' | grep '^src/domain/')
#   if [ -n "$hits" ]; then
#     echo "FAIL [boundary]: the domain layer imports the web layer:"
#     echo "$hits"
#     fail=1
#   fi
#
# IF A CHECK GUARDS A PATH THAT DOES NOT EXIST YET, SAY SO OUT LOUD. Writing the gate
# before the module is good practice; letting it stay silent is not. A scan over a missing
# directory finds nothing, which looks exactly like a clean result — so the check accrues
# the credibility of a gate while doing nothing, and when the module finally lands (quite
# possibly under a slightly different name) nothing announces that it was missed. A real
# project shipped precisely this on its money modules and the gate had never once run.
#
#   GUARDED="src/billing src/ledger"
#   present=""
#   for d in $GUARDED; do [ -d "$d" ] && present="$present $d"; done
#   if [ -z "$present" ]; then
#     echo "NOTE [boundary]: none of $GUARDED exists yet — this check is DORMANT."
#     echo "                 It arms itself when one appears; if the module lands under a"
#     echo "                 different name, update GUARDED in the same commit."
#   else
#     hits=$(scan_grep 'forbidden_pattern' | grep -E "^($(echo $present | tr ' ' '|'))/")
#     ...
#   fi
#
# {{BOUNDARY_CHECKS}}
