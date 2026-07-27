# {{PROJECT_NAME}} — What this project is, and what it has decided

This is the project's **permanent knowledge**: what it is, how it is meant to behave, and
every decision that shaped it — each with the reasoning that produced it. A rule recorded
without its reason is a rule the next reader deletes, and they are usually right to.

For a game this is the design document. For a product it is the spec and the decision log.
For a tool it is the scope and the choices behind it. The section names below are a starting
point and are meant to be replaced with this project's own vocabulary.

## How this file is read — never all at once

**This file is NOT in the session reading order.** It grows for the life of the project and
loading it whole would be a bill paid on every task that has nothing to do with it. Agents
read the SECTION they need, found through the Contents below, and cite it by number
(`PROJECT §4.2`) instead of copying its text somewhere else. A quotation is a duplicate; a
citation is not.

That is why the numbering is mandatory and why `scripts/check.sh` enforces that every
section appears in the Contents. A table of contents nobody maintains stops being a
navigation tool and becomes a lie about the file's shape.

## How this file is written

**Every item carries a status:**

- **DECIDED** — settled. Binding on every agent. Contradicting it is a failed task.
- **OPEN** — raised and not resolved. An agent may NEVER resolve one; it stops and asks.

**Who may write what:**

| Change | Who |
|---|---|
| Add an OPEN item, a question, a constraint that emerged | The agent, freely, at any time |
| Mark anything DECIDED | {{OWNER_NAME}} only, explicitly, in that session |
| Change or remove an existing DECIDED item | {{OWNER_NAME}} only |

An agent that hears a decision in conversation records it as **OPEN with a note that the
owner appeared to decide it**, and asks for confirmation. It does not promote it. The cost
of a missed capture is a forgotten question; the cost of a wrongly promoted one is every
future session treating a musing as law.

**Nothing is deleted — it is superseded.** When a decision is replaced, the old item stays,
marked `SUPERSEDED by §x.y`, with its date. The reasoning behind an abandoned direction is
how the next person avoids re-proposing it, and it is the first thing lost when items are
edited in place.

## What does NOT belong here

| Content | Its home |
|---|---|
| What is being worked on right now | `docs/STATE.md` |
| The current phase's scope and non-goals | `docs/PHASES.md` |
| Where code lives, module boundaries, contracts | `docs/ARCHITECTURE.md` |
| How we work: gates, review, task discipline | `docs/WORKFLOW.md` |
| An environment or tooling trap | `docs/GOTCHAS.md` |

The line against `ARCHITECTURE.md` is the one that blurs: **why the product behaves this way
belongs here; where the code lives and what it may reach belongs there.** "Money is stored
as integer minor units" is a decision. "The economy module may not reference the engine" is
architecture.

The line against `PHASES.md`: this file says what the project IS, that one says what we are
building right now and — more usefully — what we are deliberately not building yet.

---

## Contents

<!-- Every "## N." heading below must be listed here, and scripts/check.sh fails when one is
     missing. Keep the numbers stable: other documents cite them. -->

- 1. What this project is

---

## 1. What this project is

{{PROJECT_DESCRIPTION}}

<!-- Everything else is added as it is decided. This file is expected to be nearly empty on
     day one and to grow through conversation — that is the intended shape, not a gap to be
     filled in by generating plausible content. An agent writing sections nobody asked for is
     inventing a project rather than recording one. -->
