# /unity rules

Read on top of the root `AGENTS.md`, never instead of it.

- **Game logic is NOT written here.** It is called from the pure core. MonoBehaviours stay
  thin: gather input, call core, present the result. A rule that lives in a MonoBehaviour is
  a rule the tests cannot reach.
- Assembly split and the reference whitelist: `docs/UNITY_SETUP.md`. The compiler enforces
  it; that is the point of splitting.
- `using {{NET_LIB}}` ONLY inside the adapter assembly. `scripts/check.sh` greps for
  violations. Swapping the networking library should touch exactly one assembly.
- Server build target is headless. Strip client-only code with `#if UNITY_SERVER`.
- Anything already-written and general-purpose belongs on the client side only; it must
  never leak into the pure core.

## The Unity gate

**Unity-side work is not done until PlayMode tests pass.** Run `./scripts/unity_gate.sh`
(Unity Test Framework, EditMode + PlayMode in batchmode; needs Unity installed, and
`UNITY_PATH` set if `unity` is not on PATH).

It is separate from `./scripts/check.sh` on purpose: the fast gate runs on every commit, and
a batchmode run takes minutes per platform. Both still apply — the fast one always, this one
when you touched Unity.

**MCP is not a gate.** It needs a live editor, so it can never run in CI.

## Unity access tiers

Agents may work in Unity — through the editor's APIs, not by blind YAML edits.

**Tier 1 — C# under `Assets/`:** free, normal code rules.

**Tier 2 — scenes, prefabs and components VIA MCP:** allowed. Unity performs the write
through its own APIs, so GUIDs, references and imports stay consistent, and the change is
undoable.

**Tier 3 — editor scripts that GENERATE assets** (prefab builders, importers, bakers):
PREFERRED for anything that must be reproducible. Deterministic, re-runnable, reviewable,
and the diff is the generator rather than its output.

**Tier 4 — direct `.unity` / `.prefab` / `.asset` YAML editing:** narrow use only.
- Allowed: a small surgical diff a human can read — one serialized value.
- Forbidden: structural or hierarchy changes, anything touching GUIDs or fileIDs, ALL
  `.meta` GUID edits (they break references project-wide), bulk `ProjectSettings` rewrites.

**Concurrency rule:** the editor and an agent must never write the same files at once.
Either the agent goes through MCP, so the editor is the only writer, or the editor is closed
while the agent edits files directly. Otherwise Unity overwrites the work — silently, and
usually after you have done a lot of it. If the editor is open and you are about to write
project files directly, STOP and say so.

**Commit hygiene:** scene and prefab changes are committed SEPARATELY from code changes. A
mixed diff is unreviewable — the YAML drowns the code.

**Editor-only tooling stays editor-only.** An assembly under `Assets/Editor/` that references
an editor package does not compile without it. Nothing at runtime, and nothing in the pure
core, may depend on it.

**Design principle — thin scenes, generated content.** A scene is an assembly point:
references and wiring, not a container of baked content. Content comes from a pipeline or a
generator. This keeps scene diffs small, which is what makes agent-driven Unity work
reviewable at all.
