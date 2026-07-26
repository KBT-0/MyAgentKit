<!-- KIT-OWNED: do not edit locally; change it in the kit and re-sync. -->

# SETUP INTERVIEW — read this, then run it

You are a CLI coding agent. Someone just installed a project foundation kit into this
repository and asked you to set it up. This file is the whole procedure. It assumes you know
nothing else, and it does not depend on any conversation that happened before you read it.

**What was installed.** A set of instruction files, gates and templates that make a
repository safe for agents to work in over a long time: a constitution (`AGENTS.md`), a
workflow (`docs/WORKFLOW.md`), a review protocol (`docs/REVIEW_GATE.md`), a cross-session
memory file (`docs/STATE.md`), a task-handoff template (`docs/HANDOFF.md`), a trap log
(`docs/GOTCHAS.md`), a quality gate (`scripts/check.sh`) wired into git as a pre-commit
hook, and a cross-model review wrapper (`scripts/review.sh`).

**What is missing.** Everything project-specific. The files are full of `{{PLACEHOLDER}}`
markers, and `./scripts/check.sh` FAILS while any of them survive. Your job is to have a
real conversation with the owner, and then fill every one of them with an answer they
actually gave.

---

## Rules for how you run this

These override any habit you have about being efficient.

1. **One topic per turn. Never dump all the questions at once.** A wall of questions gets a
   wall of shallow answers, and shallow answers become rules nobody believes in three weeks.
2. **Wait for the answer.** Do not propose and immediately assume. Do not move on because
   the answer seems obvious to you.
3. **Do not invent answers.** If the owner is unsure, explain the tradeoff in two sentences,
   say what you would pick and why, and let them decide.
4. **Record the RATIONALE for every decision.** A rule without its reason gets deleted six
   months later by someone who cannot see what it was protecting. When you write a rule into
   a file, write the reason next to it.
5. **Anything the owner did not explicitly approve is OPEN, not DECIDED.** Never record a
   decision they merely failed to object to.
6. **Never claim you ran something you did not run.** If a command could not be executed,
   say "not run". This rule is in the constitution you are installing; break it here and the
   whole thing is theatre.
7. **Ask, do not assume, about scale.** A solo hobby project and a five-person team need
   different answers to the same questions, and the kit's defaults lean solo.

---

## Phase 0 — the owner's note

If `docs/kit/BOOTSTRAP_NOTE.md` exists, read it FIRST. It is the owner's agenda for this
setup, written when they ran the installer: a tool they want added, a model they want to
try, a problem they hit last time.

Address every item in it explicitly during the interview. If you end up not doing something
it asks for, say so out loud and say why. Silently ignoring it is the one failure mode this
phase exists to prevent.

If the file does not exist, move on without comment.

## Phase 1 — ecosystem research

Run `setup/RESEARCH_PROTOCOL.md` now, before the project questions, so that any tooling you
recommend later is current rather than remembered.

**If you have no web access, say so plainly and skip this phase.** Do not improvise "what's
new" from training data — you cannot tell how stale it is, and invented ecosystem news is
strictly worse than an honest gap. Note the skip in `RESEARCH_LOG.md` if that file is
present.

Present findings one at a time, each with its COST as well as its benefit. The default
verdict is REJECT. The owner approves or rejects each one.

## Phase 2 — the project interview

One topic per turn. Suggested order, because each answer informs the next:

1. **What is this project, in one paragraph, and who is it for?** You will paste a tightened
   version of their answer into the constitution, so get it concrete.
2. **Stack and shape.** Languages, runtime, build tool, test runner. Is there an engine, a
   server, a database, a mobile client? What does "run the tests" mean here, as a command?
3. **The risky areas — where does a silent bug cost the most?** This is the single most
   project-specific decision in the whole setup: it becomes the trigger list for the review
   gate. Push for specifics. "The payment flow" is useful; "the backend" is not. Ask what
   would be hardest to notice, hardest to attribute, and hardest to undo.
4. **Hard boundaries.** What must never depend on what? Which of those can be enforced by a
   compiler, a project reference, or a grep — rather than by prose in a document? Every
   boundary you can enforce becomes a check in `scripts/check.sh`; every one you cannot,
   note honestly as unenforced.
5. **Gates.** What exists today and what should: build, tests, lint, type check, engine
   tests, anything slow enough to be opt-in.
6. **People and tools.** Solo or a team? Which CLI agents and models, on what budget? Which
   is the scarce budget and which is the generous one? This fills the model-routing table.
7. **Does this project need a design document?** A game or a product with unsettled
   mechanics does. A CLI tool with an obvious scope does not — and a design document nobody
   reads is worse than none, because the constitution will keep pointing at it.

## Phase 3 — the design document (only if Phase 2 said yes)

Do NOT generate a design document from a template. Interview the owner the way a design
partner would:

- Challenge weak ideas. Say when something contradicts something they said earlier.
- Surface the contradictions rather than smoothing them over.
- Record every decision with its rationale.
- Tag each item **DECIDED** or **OPEN**. Never mark something DECIDED that the owner has not
  explicitly approved, and never resolve an OPEN item yourself later — that is the rule the
  constitution enforces on every agent that follows you.

Write it wherever the owner wants it; `docs/DESIGN.md` is the default. Whatever you choose
becomes `{{DESIGN_DOC}}` everywhere else.

## Phase 4 — write the foundation

Now fill in the files. Work through the placeholders below; `grep -rn '{{[A-Z_]*}}' .` finds
any you missed, and the gate will find the rest.

An installed overlay brings its own placeholders, which are not in these tables — the grep
above is what catches them, and the overlay's own document explains each one.

### Identity and people

| Placeholder | What goes in |
|---|---|
| `{{PROJECT_NAME}}` | The repository's name, as it should read in a heading |
| `{{PROJECT_DESCRIPTION}}` | The one-paragraph answer from Phase 2, tightened |
| `{{OWNER_NAME}}` | Who decides. Used throughout the duties section |
| `{{DESIGN_DOC}}` | Path to the design document, or the literal phrase "the project README" if there is none |
| `{{DESIGN_DOC_LINE}}` | One line in `AGENTS.md` saying where design authority lives and how to read it selectively |
| `{{LANGUAGE_EXCEPTION}}` | Empty if everything is in English. If a document is deliberately in another language, name it and say why |

### Risk and review

| Placeholder | What goes in |
|---|---|
| `{{RISKY_AREAS}}` | The Phase 2 list, as specific nouns. Gates and CI are already listed permanently — do not repeat them |
| `{{TOP_RISK_PRIORITY}}` | The single worst failure mode, as the first review priority, with what makes it expensive |
| `{{REVIEWER_MODEL}}` | The strongest model available for reviews |

### Architecture

| Placeholder | What goes in |
|---|---|
| `{{RUNTIME_TOPOLOGY}}` | A small diagram plus one line per process: what it is, what authority it has |
| `{{REPO_LAYOUT}}` | The folder tree with one line each. Only real folders |
| `{{MODULE_MAP}}` | A table per area: module, responsibility, one line. A map, not documentation |
| `{{BOUNDARY_ENFORCEMENT}}` | Numbered: each rule and WHAT enforces it. Write "not enforced" where nothing does |
| `{{BOUNDARY_RULES}}` | The same boundaries stated as rules in the constitution |
| `{{TESTED_AREA}}` | Which part of the tree may not receive untested code |

### Gates

| Placeholder | What goes in |
|---|---|
| `{{BUILD_TEST_COMMAND}}` | One shell command that builds and tests. It runs on every commit — keep it fast |
| `{{BOUNDARY_CHECKS}}` | **Replace the whole of `scripts/boundary_checks.sh`**: one grep per enforceable boundary, each setting `fail=1` |
| `{{BOUNDARY_SELF_TESTS}}` | **Replace the whole of `scripts/boundary_selftests.sh`**: one negative test per check above. Not optional — see below |
| `{{TOOLCHAIN}}` / `{{TOOLCHAIN_PATH_SETUP}}` / `{{TOOLCHAIN_SETUP_NOTES}}` / `{{TOOLCHAIN_SETUP_STEP}}` | What the gate needs on PATH, how to find it in a non-login shell, how CI installs it. `{{TOOLCHAIN_PATH_SETUP}}` is a directory to prepend, not a line of code |
| `{{DEFAULT_BRANCH}}` | The branch CI runs on |
| `{{STACK_IGNORE_RULES}}` | Stack-appropriate `.gitignore` rules. Remember: the re-include block stays LAST |
| `{{GATED_PATHS}}` / `{{GATED_FILE_PATTERN}}` / `{{BOUNDARY_GUARDS}}` | Which paths the editor-side hooks watch, mirroring the checks above |

### Process

| Placeholder | What goes in |
|---|---|
| `{{WORKTREE_POLICY}}` | A table: path, worktrees yes/no/conditional, and the condition. Anything with a huge cache or a shared database is a "no" or a "needs its own" |
| `{{MODEL_ROUTING}}` | Which model gets judgement work, which gets volume, and which budget is scarce |
| `{{REJECTED_DECISIONS}}` | Everything considered and turned down in this interview, with the reason and what would reopen it |
| `{{PROJECT_STOP_RULES}}` | Project-specific reasons an agent must stop and ask |
| `{{PROJECT_SETUP_STEPS}}` | Anything else a fresh clone needs |
| `{{MODULE}}` | Only in `MODULE_AGENTS_TEMPLATE.md` — copy that file per module and fill it there |

### Then, in this order

1. **Write the boundary checks and their negative tests together.** They live in two files
   that `scripts/check.sh` sources: `scripts/boundary_checks.sh` and
   `scripts/boundary_selftests.sh`. Replace each file WHOLE — that is why they are separate
   files rather than a marked region inside the gate script, and it is not a stylistic
   preference: the first person to fill a marked region left the comment character on the
   first line, and the entire check sat inert inside a comment while the gate reported PASS.
   For every check you add, add the case that constructs the violation and asserts the gate
   rejects it. A gate you have only seen pass has not been tested; it is an untested branch
   that runs on every commit. Both files ship with a worked example.
2. **Run `./scripts/check.sh`.** Show the owner the real output. If it fails, fix the cause.
3. **Run `./scripts/check.sh --self-test`.** Show that output too. If a gate does not go red
   when its failure is injected, it is protecting nothing — fix it before you continue.
4. **Initialise `docs/STATE.md`**: what was set up, what is open, what the owner still has to
   do, with a tool+model trace. Full sentences.
5. **Delete what does not apply.** An overlay or a section for something this project does
   not have is not harmless — it is a lie the next agent will believe.
6. **Commit.** If the repository has no commit gate yet, wire it:
   `git config core.hooksPath .githooks`.

## Phase 5 — backflow

Ask the owner one question:

> "Did anything from this setup belong in the kit itself, rather than only in this project?"

A rule you had to invent because the kit lacked it, a placeholder that was ambiguous, a
question you needed that this file does not ask — those belong upstream. If the answer is
yes, produce a ready-to-apply patch for the kit repository plus a `CHANGELOG.md` entry, and
tell the owner where to send it.

This is not a courtesy. It is the only mechanism by which the kit gets better instead of
drifting further from the projects that use it.

---

## When you are finished

Report, briefly and honestly:

- What was decided, and what stayed OPEN.
- The real output of `./scripts/check.sh` and of `./scripts/check.sh --self-test`.
- Anything you could not verify, named as "not run".
- What the owner still has to do by hand.
