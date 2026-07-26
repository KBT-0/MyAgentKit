# MyAgentKit

A foundation for codebases written mostly by AI agents: rules that are **enforced rather
than requested**, memory that survives across tools and sessions, and a setup that
**researches its own ecosystem** instead of shipping advice that was true once. It is not a
template you copy and outgrow — installation is a conversation with an agent, and every
project that uses it can push what it learned back into the kit.

> **Status: v0.1 — extracted from a project in active use; not yet used to bootstrap a
> second project.** `bootstrap.sh` is verified to produce a working skeleton in an empty
> directory, and the gates are verified to fail when they should ([what was
> tested](docs/ACCEPTANCE.md)). What has NOT happened yet is a real setup interview with a
> real owner on a real second project, which is where the rough edges will be. Treat the
> ecosystem-specific notes as unverified until the first research pass runs
> (`RESEARCH_LOG.md`).

Part of my `MyFramework` line of personal foundations — this is the AI-agent one.

## The problem

Codebases written by agents decay as they grow: the same system gets built twice because
nobody could find the first one, and each new session is a little less able to navigate
what the last one wrote. Rules written as prose erode, because nothing enforces them — an
instruction file is a request, and requests get skimmed. Memory fragments: chat history
does not cross sessions, and it certainly does not cross tools, so what the last session
learned is gone. And the tooling underneath all of this moves faster than any one person
can track, so a setup that was current in March is quietly stale by June.

None of that is fixed by a better prompt. It is fixed by structure.

## Core principles

- **Rules live in the compiler and CI, not in prose.** If a boundary matters, a script
  fails when it is crossed.
- **A gate is not finished until it has been proven to go RED**, and it ships with an
  automated negative test. A gate that has only ever been seen passing is an untested
  branch running on every commit.
- **One canonical instruction file.** Tool-specific files (`CLAUDE.md` and friends) are
  one-line pointers to it, never a second copy.
- **If it is not in the state file, it did not happen.** That file is the only cross-tool
  memory — and it is transient: permanent knowledge passes THROUGH it into a real home.
- **The author of a change never reviews it.** Review happens in a fresh session,
  preferably a different model, because the value of a second opinion is that it is
  decorrelated.
- **Small tasks, one module, a verifiable definition of done.** Validation is a gate you
  can run, never the implementer's self-report.
- **Every tool must earn its permanent context cost.** The default verdict on a new tool,
  server or dependency is *no*.

## Quick start

```sh
git clone https://github.com/KBT-0/MyAgentKit.git
cd /path/to/your-project
/path/to/MyAgentKit/bootstrap.sh .          # mechanical copy only
```

Then open your CLI agent in the project and say:

> Read `setup/INTERVIEW.md` and start the setup.

`bootstrap.sh` copies files and configures git hooks. It does not ask you anything and it
does not fill anything in — that is the interview's job, because the decisions it needs
(what is risky here, which boundaries must be enforced, what the gates are) cannot be
answered by a script. Pass `--note "..."` to leave an agenda the interview must address.

## What's in the box

| Path | What it does |
|---|---|
| `bootstrap.sh` | Mechanical install: copy, mkdir, wire the git hooks path, record the kit version |
| `setup/INTERVIEW.md` | The real entry point — a conversational setup an agent runs with you |
| `setup/RESEARCH_PROTOCOL.md` | How the agent researches the current tooling ecosystem before advising you |
| `core/` | The universal layer: constitution, workflow, review gate, handoff template, state file, gates, hooks |
| `overlays/unity/` | Optional per-stack layer. Unity first; an overlay is added, never assumed |
| `patterns/` | Optional reading — the reasoning behind specific hard-won designs. Not copied by default |
| `docs/` | Long-form rationale: why each rule exists, and the failure mode it prevents |
| `sync-kit.sh` | Propagate kit updates into a project that already installed it |
| `RESEARCH_LOG.md` | Dated findings with verdicts — including rejections, so they are not re-litigated |

## How updates work

Files are one of two kinds. **Kit-owned** files carry a header saying so; `sync-kit.sh`
overwrites them wholesale. **Project-owned** files — the constitution, the workflow, the
check script, the reviewer definition — are customised per project and are never
overwritten. After overwriting, `sync-kit.sh` prints the `CHANGELOG.md` entries added since
your recorded version, so you can hand-apply the rest deliberately.

Updates also flow the other way. Every project using the kit asks one question in its
periodic audit: *did we learn anything this cycle that belongs in the kit rather than
here?* If yes, the kit changes first, then the project syncs. That is why
`RESEARCH_LOG.md` exists.

## Where this came from

Extracted from `project_leeway`, a Unity + .NET multiplayer game written almost entirely by
CLI agents over roughly two months. Nothing here was designed in the abstract: every rule
is in the kit because something broke without it. The five founding lessons — including
three gates that reported PASS while protecting nothing — are written up in
`RESEARCH_LOG.md` with the failure each one prevents.

MIT licensed.
