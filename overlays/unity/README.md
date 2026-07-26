# Overlay: Unity

Install with `bootstrap.sh . --overlay unity`. This README is NOT copied — only `files/` is.

## What it adds

| File | What it is |
|---|---|
| `unity/AGENTS.md` | Folder rules: the four access tiers, the concurrency rule, commit hygiene, thin scenes |
| `unity/CLAUDE.md` | Pointer |
| `docs/UNITY_SETUP.md` | Assembly layout, consuming a pure core from Unity, VCS settings, MCP scope |
| `scripts/unity_gate.sh` | The Unity Test Framework gate, batchmode, with its evidence checks |
| `docs/kit/unity.gitignore-fragment` | `.gitignore` rules to append by hand |

## Why the Unity gate is a separate script

`scripts/check.sh` stays fast and Unity-free: it runs on every commit through the pre-commit
hook, and a Unity batchmode run takes minutes per platform. The Unity gate is opt-in and
runs when Unity-side work is finished, or on a schedule.

It is also deliberately not wired into `check.sh`, so installing this overlay does not
require editing a project-owned file. Ordinary work is unaffected by an overlay you took.

## Two things to do by hand after installing

1. **Append the gitignore fragment.** `bootstrap.sh` copies files; it does not merge into an
   existing `.gitignore`. Paste the fragment into the "Stack-specific rules" section — and
   keep the re-include block at the very END of the file, because git applies the LAST
   matching rule.
2. **Add the boundary check.** The networking library confinement (only the adapter assembly
   may import it) belongs in `scripts/boundary_checks.sh`, with its negative test in
   `scripts/boundary_selftests.sh`. `docs/UNITY_SETUP.md` gives both, ready to paste.

## What this overlay assumes

That the project keeps its game logic in a pure, engine-free core and treats Unity as one
consumer of it. If the project is Unity all the way down, most of the value here does not
apply — take `unity/AGENTS.md` and the gate, and skip the rest.
