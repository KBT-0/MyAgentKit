# CHANGELOG

What changed in the kit, dated, newest first. `sync-kit.sh` prints the entries added since
a project's recorded kit version, so an entry must say what a project OWNER has to do —
not just what moved. Mark anything needing hand-application with **ACTION**.

Versions are `MAJOR.MINOR`. MINOR adds or refines; MAJOR changes a rule or a file layout in
a way that existing projects must reconcile by hand.

WHY an entry exists belongs in `RESEARCH_LOG.md`; this file records WHAT changed.

---

## v0.1 — 2026-07-26

First extraction. The kit's Layer 1 (universal core), the Unity overlay and the optional
patterns were taken from `project_leeway`, a Unity + .NET multiplayer project written
almost entirely by CLI agents. Nothing here was designed in the abstract; every rule was
paid for by that project.

Founding content, with the failure each rule prevents recorded in `RESEARCH_LOG.md`
(Backflow findings, 2026-07-26):

- Gates must be proven RED before they count, and each ships with an automated negative
  test — `core/scripts/check.sh --self-test`.
- Gates, CI and review tooling are a permanent risky area in every project's review gate.
- The cross-session state file is transient: completed work is deleted, permanent findings
  are tagged `[LESSON]` / `[GOTCHA]` and routed to a permanent home before deletion, and
  the rot gate keys on an empty "Active work" section rather than a line count.
- CLI output parsing strips ANSI escapes and never writes an extracted field as silently
  blank.
- Always-loaded documents are a recurring token bill and are kept small and stable.

**ACTION** — none. There is no earlier version to upgrade from.
