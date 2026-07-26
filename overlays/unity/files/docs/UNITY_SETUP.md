# UNITY_SETUP.md — assembly layout, core wiring, VCS settings, MCP scope

Do this before writing Unity gameplay or networking code. An agent cannot create the Unity
project — {{OWNER_NAME}} owns that in Unity Hub. Everything below is what turns the
architecture boundaries into things the compiler enforces.

## 1. Version control settings (do these first)

In `Edit → Project Settings`:

- **Editor → Asset Serialization → Mode: Force Text.** Binary scenes and prefabs cannot be
  diffed, reviewed or merged. Without this, every scene change is an opaque blob and the
  review gate is decorative.
- **Editor → Version Control → Mode: Visible Meta Files.** `.meta` files carry the GUIDs
  that hold every reference in the project together. They are repository content.
- **Register UnityYAMLMerge** as git's merge driver for `*.unity` and `*.prefab`. It ships
  with the editor. Without it, a scene conflict is resolved by hand in YAML, which is how
  references get quietly broken.

## 2. Assembly layout (one asmdef per module)

One folder per assembly under `Assets/`, each with its own `.asmdef`. The names mirror the
module map in `docs/ARCHITECTURE.md`.

```
Assets/
  Client/            {{ASM_PREFIX}}.Client.asmdef
  Server/            {{ASM_PREFIX}}.Server.asmdef
  Shared/            {{ASM_PREFIX}}.Shared.asmdef
  Net/Adapter/       {{ASM_PREFIX}}.Net.Adapter.asmdef
```

### Reference whitelist — the boundary, enforced by the compiler

| Assembly | May reference | Must NOT reference |
|---|---|---|
| `{{ASM_PREFIX}}.Shared` | the pure core, Unity engine | Client, Server, {{NET_LIB}} |
| `{{ASM_PREFIX}}.Net.Adapter` | the pure core, Shared, **{{NET_LIB}}** | Client, Server |
| `{{ASM_PREFIX}}.Server` | the pure core, Shared, Net.Adapter | Client |
| `{{ASM_PREFIX}}.Client` | the pure core, Shared, Net.Adapter | Server |

**{{NET_LIB}} is imported ONLY inside the adapter assembly.** Keep the folder name
recognisable, because the grep gate below keys on the path. Swapping the networking library
should then touch exactly one assembly — that is the entire reason for this split.

### The matching gate

Add to `scripts/boundary_checks.sh`:

```sh
hits=$(scan_grep 'using {{NET_LIB}}' | grep '^unity/' | grep -v 'Net/Adapter')
if [ -n "$hits" ]; then
  echo "FAIL [boundary]: {{NET_LIB}} outside the adapter assembly:"
  echo "$hits"
  fail=1
fi
```

And its negative test, in `scripts/boundary_selftests.sh` — not optional:

```sh
mkdir -p unity/Assets/Client && printf 'using {{NET_LIB}};\n' > unity/Assets/Client/.selftest.cs
if sh "$0" >/dev/null 2>&1; then
  echo "  FAIL — {{NET_LIB}} confinement gate stayed green with a violation present."
  st_fail=1
else
  echo "  ok   — {{NET_LIB}} confinement gate rejects an import outside the adapter"
fi
rm -f unity/Assets/Client/.selftest.cs
```

## 3. Consuming the pure core from Unity

The core is engine-free C# living outside the Unity project. Wire it as a **local UPM
package** rather than copying sources:

1. Add a `package.json` beside the core, once:

   ```json
   {
     "name": "{{CORE_PACKAGE_NAME}}",
     "version": "0.0.1",
     "displayName": "Core",
     "description": "Pure C# logic. No Unity."
   }
   ```

2. Give the core an `.asmdef` with `"noEngineReferences": true`, and reference it from
   `{{ASM_PREFIX}}.Shared`.

3. Register it in `Packages/manifest.json`:

   ```json
   "{{CORE_PACKAGE_NAME}}": "file:{{CORE_PATH}}"
   ```

`"noEngineReferences": true` is the load-bearing line. If Unity ever needs an engine
reference inside the core, the boundary is being violated — fix the layout, do not add the
reference.

## 4. MCP — how agents reach the editor

Agents drive the editor through an MCP server (the access tiers are in `unity/AGENTS.md`).
The server is ultimately {{OWNER_NAME}}'s call, but this overlay ships a default rather than
an empty decision, because "pick an MCP server" is a research task with a wrong answer:

**Default: CoplayDev's [`MCP for Unity`](https://github.com/CoplayDev/unity-mcp) (MIT).**
It is tool-agnostic — it configures whichever MCP clients it detects, so it is not tied to
one vendor's cloud account or one editor. That property matters more than the feature list:
a server bound to a single vendor adds a service dependency you do not control on top of a
beta you cannot pin.

```
Unity → Package Manager → Add package from git URL:
  https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity#<release-tag>
then: Window → MCP for Unity → Configure All Detected Clients
```

Needs Python 3.10+ (via `uv`) on the machine.

**Pin a release tag, never `#main`.** A moving dependency breaks the project silently and
at the worst moment; bumping the pin is a deliberate task, not a side effect of someone
reinstalling. Check the tag list and take the newest release rather than copying a version
out of this document — the pin below is not maintained here, and a stale one is worse than
no suggestion.

**Verify the catalogue against the version you actually installed.** Everything in the next
section was walked against an installed copy's `Editor/Tools/` source, not against its
documentation. Do the same after any bump: the tool groups are where the surprises live.

### Scope: decide it, then enforce it in the right place

Reasonable defaults for what an agent may drive:

- **In scope:** scene and GameObject operations, component add/remove and serialized value
  edits, prefab create/instantiate/apply, script editing, and read-only introspection.
  Introspection especially — a hierarchy report costs a fraction of what dumping scene YAML
  into context does.
- **Out of scope:** destructive project-wide operations, `ProjectSettings` rewrites, render
  pipeline or quality changes, package install/removal, `.meta` and GUID edits, and builds.

**Two findings that cost real time, both worth checking against whatever server you pick:**

1. **Tool groups do not match your scope list.** In the server that was audited, everything
   listed as out of scope above — package management, builds, graphics and physics
   settings, asset delete/move, and a tool that invokes ANY editor menu item — lived in the
   always-on default group. The names are reassuring; the groupings are not. Read the tool
   catalogue yourself rather than trusting the group labels.
2. **A per-tool deny list in the MCP CLIENT is bypassable.** A batch-execute tool runs a
   list of calls editor-side and checks only the editor's own enabled-tools state. It never
   sees the client's permission list, so a tool disabled in the client and enabled in Unity
   is still reachable. **Enforce scope in the editor's own tools window, not in the client
   config.**

Whatever cannot be enforced by mechanism is out of scope BY RULE, which means a review of
any MCP-driven change has to look for it. Say so explicitly rather than implying the
checkbox covered it.

### MCP is not a gate, and it is not free

It needs a live editor, so it can never run in CI — the gate is `scripts/unity_gate.sh`.

Every enabled MCP server injects its whole tool catalogue into every request, whether or not
a tool is called. Enable it for Unity-touching work and turn it off afterwards
(`docs/WORKFLOW.md`, MCP hygiene).

## Done when

- The assemblies above exist with the reference whitelist applied.
- The core is referenced from `{{ASM_PREFIX}}.Shared` and compiles inside Unity.
- `./scripts/check.sh` passes, and `./scripts/check.sh --self-test` shows the
  {{NET_LIB}}-confinement gate going red.
- `./scripts/unity_gate.sh` runs and reports a nonzero executed-test count.
