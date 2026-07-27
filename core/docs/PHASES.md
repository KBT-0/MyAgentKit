# Phases — what we are building now, and what we are deliberately not

Read every session. It is short on purpose: the CURRENT phase in full, everything after it
in one line each. Detail arrives when a phase becomes current, not before — a plan written
for a phase three steps away is mostly aspiration, and aspiration in an always-loaded file
is a bill with nothing behind it.

**The non-goals are the useful half.** "Build the inventory system" gives an agent no edge
to stop at, so it invents scope: it adds persistence, a UI, an event system, and returns one
monolithic file touching five modules. "Build the grid placement rules; do NOT add
persistence, do NOT write UI" is the same task with a fence around it. Scope invention is
the most expensive habit an agent has, and this file is the cheapest cure.

The reasoning behind phase-shaped work — ordering by risk rather than by dependency, why
each phase should be independently useful — is in `patterns/staged-prototype.md` if the
project took it. This file is the working document, not the argument for it.

## Lifecycle

A phase is **episodic**: true for as long as it runs, then gone. When it closes, its detail
is DELETED from this file — history lives in git — after anything permanent has been moved
to its real home:

- A decision the phase produced → `docs/PROJECT.md`, as a numbered item
- A module, boundary or contract → `docs/ARCHITECTURE.md`
- A process or gate lesson → `docs/WORKFLOW.md`
- An environment trap → `docs/GOTCHAS.md`

That is the same harvest-then-prune rule `docs/STATE.md` follows, one scale up. The three
files differ only in how long their contents stay true:

| File | Horizon | On completion |
|---|---|---|
| `docs/PROJECT.md` | Permanent | Superseded, never deleted |
| `docs/PHASES.md` | This phase | Deleted after harvest |
| `docs/STATE.md` | Right now | Deleted when the task is done |

A multi-item operation with checkboxes is NOT a phase — it gets its own throwaway file
(`docs/WORKFLOW.md`). Phases are standing; operations are disposable.

---

## Current phase: {{CURRENT_PHASE}}

**The question it answers:** {{PHASE_QUESTION}}

<!-- One sentence. What do we not know, or what risk are we retiring? If it cannot be put as
     a question, the phase is a wish list rather than a phase. -->

**In scope**

{{PHASE_IN_SCOPE}}

**NOT in scope — do not build these yet**

{{PHASE_OUT_OF_SCOPE}}

<!-- Spend as much effort here as on the list above. Each entry names the phase it belongs to
     instead, so "not yet" does not read as "never". An agent that finds itself needing
     something on this list STOPS and reports rather than quietly widening the phase. -->

**Done when**

{{PHASE_ACCEPTANCE}}

<!-- Commands or observations, never adjectives. "The simulation runs 100 days at seed 42
     with no price outside its declared band" is a criterion. "The economy feels balanced" is
     not — unless it names WHO decides and when, which makes a subjective criterion valid.
     An unowned subjective criterion is not a criterion. -->

---

## After this one

<!-- One line per phase, in order, and no more than a line. The question it will answer is
     enough; scope and criteria are written when it becomes current. Reordering this list is
     a decision and belongs in docs/PROJECT.md with its reasoning — this is the view, not the
     authority. -->

{{LATER_PHASES}}
