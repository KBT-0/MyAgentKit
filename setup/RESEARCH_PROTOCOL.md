<!-- KIT-OWNED: do not edit locally; change it in the kit and re-sync. -->

# RESEARCH PROTOCOL — what changed in the agent-tooling ecosystem

You are a CLI coding agent, running this either as Phase 1 of a project setup
(`setup/INTERVIEW.md`) or as the tooling question inside a project's periodic audit. This
file is the whole procedure; it assumes no prior context.

**Why this exists.** The tooling under an agent-written project moves faster than any one
person can track. Advice baked into a template is stale within months, and a project set up
from stale advice inherits it silently. Folding the tracking into setup is the only way
every new project starts current — and the only way an old decision gets revisited when the
thing it was rejected for stops being true.

**What it is not.** It is not a shopping trip. Most passes should end with nothing adopted.

---

## Before you start: can you actually research?

Check whether you have web access — a real fetch or search tool, not a memory of one.

**If you do not: STOP this phase and say so plainly.** Write "no web access; research pass
skipped" and move on. Do NOT improvise from training data. You cannot tell how stale your
knowledge is, and a confident summary of an ecosystem that has moved on is worse than an
honest gap: the owner will make decisions on it, believing it was checked.

## The baseline: what date are you researching from?

Open `RESEARCH_LOG.md` if the project has one and find the last dated pass. **Your question
is "what changed since that date?"** — not "what exists?". Without a baseline you will
rediscover the same things every time, spend the budget re-reading them, and bury the one
genuinely new item in the noise.

If there is no log, say so, and set today as the baseline for the next pass.

## Scope of the search

Five areas. Nothing else — this is a bounded pass, not a survey of the industry.

1. **Capability changes in the CLI agents actually in use here.** New commands, hooks,
   memory features, context or caching controls, effort settings, sandboxing. Read the
   changelogs; do not rely on blog posts about them.
2. **Official integrations between the tools in use.** A first-party plugin that connects
   two tools the project already pays for is worth far more than a third-party one that
   reimplements it, because it does not become your maintenance problem.
3. **MCP servers relevant to this project's stack** — but see the cost rule below. Most are
   a worse version of a CLI the agent already has.
4. **Cost and token levers.** Prompt caching behaviour, context compaction, model routing,
   reasoning-effort controls, pricing changes. This is usually where the real wins are, and
   it is the area people forget to check.
5. **Anything that would INVALIDATE a decision on the rejected list.** Read
   `docs/WORKFLOW.md`'s "evaluated and rejected" section and ask, item by item, whether the
   reason still holds. A tool rejected for being non-deterministic and unreviewable must be
   reconsidered if it becomes deterministic and git-backed. **A rejection with a dead reason
   is not a decision any more; it is a habit.**

## How to report a finding

Every finding, in this shape, one at a time:

- **What it is** — one or two sentences, plain.
- **What it would change here** — concretely, in this repository. If you cannot name the
  file or the workflow step it touches, it is not a finding, it is news.
- **What it costs.** All three:
  - **Permanent context tokens** — anything loaded into every session: an MCP server's tool
    catalogue, a skill's description, a document added to the reading order. This is a bill
    paid on every turn, forever, whether or not the thing is used.
  - **Money** — subscription, per-call, or a bigger prompt.
  - **Dependency risk** — who maintains it, what breaks when it disappears, whether it can
    be removed later without unpicking the project.
- **Your recommendation**, with the reason.

## The verdict rule

**The default verdict is REJECT.** A tool must EARN its permanent cost, and "it looks
useful" is not payment. The bar is a concrete problem this project has, that this thing
solves, that nothing already installed solves.

Reject in particular:

- Anything duplicating a plain CLI the agent already runs (`git`, `grep`, `jq`, the build
  tool). A wrapper around these buys nothing and costs a catalogue in every request.
- Anything whose value is "the agent can now find code in this codebase". That problem is
  usually architectural decay wearing a tooling costume, and the honest fix is an audit and
  a better module map — not a retrieval layer bolted on top of the rot.
- Anything storing project memory outside git, where it cannot be diffed, reviewed or rolled
  back.
- Anything that runs two agents against each other unattended. Those loops burn a budget
  fast and produce work nobody decided to do.

## Recording the outcome

Append to `RESEARCH_LOG.md`, with today's date:

- Every ACCEPTED finding, with what it changed and why it was worth the cost.
- **Every REJECTED finding, with the reason and what would have to change to reopen it.**
  This half is the point. Without it the next pass re-litigates the same three tools from
  scratch, every time, forever.
- If nothing was adopted, write that, with the date. "Nothing this cycle" is a valid and
  common result, and recording it is what makes the next baseline meaningful.

## Cadence

At every install, and once inside each project's periodic architecture audit. Not
continuously: a research pass costs budget too, and running it on a schedule is what stops
it from being run on a whim.
