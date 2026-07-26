# Overlay: Claude Code

Install with `bootstrap.sh . --overlay claude-code`. This README is NOT copied — only
`files/` is.

## Why this is an overlay and not part of the core

The kit's rules are tool-agnostic: `AGENTS.md`, the workflow, the review protocol, the state
file, `scripts/check.sh`, the git hook and CI all work under any CLI agent, or none.

These files do not. They are Claude Code's config format — its hook events, its skill
frontmatter, its subagent definition. Shipping them in the core meant every project got a
`.claude/` directory whether or not anyone used that tool, and it let the kit imply a
neutrality its automation did not have. An engine is an overlay here; so is a host agent.

If you use a different tool, take this overlay's IDEAS and write the equivalent for yours:
the hooks are worth reproducing, and the two skills are thin wrappers over documents that
are already in the core.

## What it adds

| File | What it is |
|---|---|
| `CLAUDE.md` | One-line pointer to `AGENTS.md`. Content never goes here |
| `.claude/settings.json` | Registers the two hooks below |
| `.claude/hooks/gate_on_stop.sh` | Runs the gate if a turn left the watched paths dirty — early feedback, never the rule |
| `.claude/hooks/guard_boundaries.py` | Flags a forbidden import the moment it is written, seconds instead of a commit |
| `.claude/agents/diff-reviewer.md` | Read-only review subagent following `docs/REVIEW_GATE.md` |
| `.claude/skills/handoff/` | `/handoff` — wraps `docs/HANDOFF.md` |
| `.claude/skills/cross-review/` | `/cross-review` — wraps `scripts/review.sh` plus the verification duty |

## What `/cross-review` needs

A SECOND CLI on the machine. `scripts/review.sh` shells out to it, and out of the box it
targets the Codex CLI's interface. Install it and log in, or the skill reports that it is
missing and falls back to the paste-by-hand template in `docs/REVIEW_GATE.md`.

The vendor plugin (`openai/codex-plugin-cc`) is OPTIONAL and is not used by
`scripts/review.sh`; it adds in-session delegation commands. `docs/DEV_SETUP.md` §3 covers
both, including the two cautions worth reading before installing it.

## The hooks are not the gate

`.githooks/pre-commit` is. These fire earlier and only in one tool; they exist to shorten
the feedback loop, not to carry enforcement. Nothing here is load-bearing — deleting the
whole overlay leaves every rule intact and every gate running.
