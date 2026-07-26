# Negative tests for scripts/boundary_checks.sh — SOURCED by check.sh --self-test.
#
# One case per check. Each one: construct the violation, run the gate, assert it FAILS,
# clean up. Set `st_fail=1` when a gate did not reject what it claims to reject.
#
# `sh "$0"` re-runs the gate without the self-test flag, so it exits nonzero on a violation.
#
# REPLACE THIS WHOLE FILE alongside scripts/boundary_checks.sh.
#
# Worked example, matching the example check:
#
#   mkdir -p src/domain && printf 'from myapp.web import router\n' > src/domain/.selftest.py
#   if sh "$0" >/dev/null 2>&1; then
#     echo "  FAIL — domain/web boundary gate stayed green with a violation present."
#     st_fail=1
#   else
#     echo "  ok   — domain/web boundary gate rejects a forbidden import"
#   fi
#   rm -f src/domain/.selftest.py
#
# {{BOUNDARY_SELF_TESTS}}
