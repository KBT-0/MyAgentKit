#!/usr/bin/env python3
"""PostToolUse(Edit|Write): catch a forbidden import the moment it is written.

CI catches it too. This hook only shortens the feedback loop from "next commit" to "next
second", which is the difference between a one-line fix and an argument with a rebase.

Configured by the setup interview: one entry per enforced boundary, mirroring the greps in
scripts/check.sh. If the two disagree, scripts/check.sh is the authority — it is what CI
runs, and this file is convenience for a single tool.
"""
import json
import sys

# (path fragment, file suffix, forbidden tokens, message)
BOUNDARIES = [
    # ("/src/domain/", ".py", ("from myapp.web", "import myapp.web"),
    #  "the domain layer must not depend on the delivery layer"),
    # {{BOUNDARY_GUARDS}}
]

data = json.load(sys.stdin)
tool_input = data.get("tool_input", {})
path = tool_input.get("file_path", "")
content = (tool_input.get("content", "") or "") + (tool_input.get("new_str", "") or "")

for fragment, suffix, tokens, why in BOUNDARIES:
    if fragment not in path or not path.endswith(suffix):
        continue
    hits = [t for t in tokens if t in content]
    if not hits:
        continue
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": (
            f"BOUNDARY VIOLATION in {path}: {hits} — {why}. "
            f"This will not survive CI (scripts/check.sh). Fix it now, before the next edit "
            f"builds on top of it."
        ),
    }}))
    break
