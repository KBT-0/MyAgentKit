# Permanent, episodic, momentary — three horizons, three files

Project knowledge does not have two shelf lives, it has three, and collapsing them is how a
codebase ends up with either a state file nobody can read or a design document nobody
trusts.

| Horizon | File | True for | When the work ends |
|---|---|---|---|
| **Permanent** | `docs/PROJECT.md` | The life of the project | Superseded, never deleted |
| **Episodic** | `docs/PHASES.md` | The current phase | Deleted, after harvesting |
| **Momentary** | `docs/STATE.md` | Right now | Deleted when the task is done |

The test is one question: **is this still true after the current phase ends?** Yes →
PROJECT. No, but needed for the whole phase → PHASES. Only right now → STATE.

## Why the middle one was missing, and what it cost

The kit shipped without it, and the founding project grew it anyway — a `PROTOTYPE_SCOPE.md`
appeared, unprompted, listing each stage's question, what to build, what NOT to build, and
how to tell it was done. A document that a project invents on its own is a document the kit
should have shipped.

What it prevents is the single most expensive agent habit: **scope invention.** Told "build
the inventory system", an agent has no edge to stop at, so it adds persistence, a UI and an
event system and returns one monolithic file touching five modules. Told "build the grid
placement rules; do NOT add persistence, do NOT write UI — those are later phases", it
builds the thing. The non-goals are the useful half of a specification and the half everyone
skips, so they need a home that is read every session.

Without that home the non-goals land in the state file, where they are deleted the moment
the current task finishes, and the next session re-invents the same scope.

## Why PROJECT.md is not in the reading order

It grows for the life of the project. The founding project's reached 905 lines. Loading it
per session would be a bill paid on every task that has nothing to do with it, which is the
failure `context-is-a-budget.md` describes.

So it is read by SECTION, through a numbered Contents, and cited by number rather than
quoted. That distinction carries weight: **a quotation is a duplicate and drifts; a citation
cannot.** When STATE.md says "per PROJECT §4.2" there is exactly one copy of the decision.

And because a rule like that erodes — the Contents falls behind, the file stops being
navigable, and the next reader gives up and loads the whole thing — `scripts/check.sh`
fails when a numbered section is missing from the Contents. The navigation is mechanical or
it is fiction.

## Why an agent may write OPEN but never DECIDED

The appealing version of a living document is one the agent fills in from conversation.
The dangerous version is the same sentence.

An agent that records decisions autonomously will eventually promote a musing to a DECIDED
item, do it silently, and every session after that treats it as law — while the constitution
says in its hardest rule that agents implement and do not design. The document meant to hold
the owner's decisions becomes the place the agent's inferences accumulate, and nobody can
tell which is which afterwards.

The split that keeps both halves:

- **OPEN: the agent writes freely.** Capturing a question costs nothing; losing one is
  expensive, and losing them is exactly what happens when the only home is a chat log.
- **DECIDED: the owner only, explicitly, in that session.** An agent that hears a decision
  records it as OPEN with a note that the owner appeared to settle it, and asks.

The asymmetry is deliberate. A wrongly captured question is noise someone deletes in a
minute. A wrongly promoted decision is invisible, binding, and compounds.

## Why there is no ROADMAP.md

It was considered and rejected. A separate roadmap creates a seam with no clear side:
"offline support in v2" is both a decision and a plan, so it gets written twice or lost.
It is also small, changes rarely, and mostly describes horizons far enough away to be
aspiration — and aspiration in an always-loaded file is a bill with nothing behind it.

The long view lives at the bottom of `PHASES.md` as one line per future phase. Detail is
written when a phase becomes current. Reordering that list is a decision, so the reasoning
goes in PROJECT.md; the list itself is a view, not an authority.

Four permanent homes (PROJECT, ARCHITECTURE, WORKFLOW, GOTCHAS) is already a routing table
an agent consults on every prune. Adding a fifth whose boundary is unclear is how routing
tables start being got wrong.

## The failure mode all of this prevents

Decisions made in conversation, recorded nowhere, re-litigated three weeks later with
nobody able to say why the first answer was rejected — while the state file grows into a
diary and the design document, if it exists at all, describes a project that no longer
exists.
