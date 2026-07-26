# Project boundary checks — SOURCED by scripts/check.sh, never executed on its own.
#
# Available to you here: `scan_grep <extended-regex>` (searches tracked and
# untracked-but-not-ignored files, printing path:line:text) and the `fail` variable.
# Set `fail=1` to fail the build.
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
# {{BOUNDARY_CHECKS}}
