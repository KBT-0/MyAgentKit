# Dev setup — per clone

Things git cannot carry inside a commit. Run them once in every fresh clone, on every
machine — and note that a Windows shell and a WSL shell on the same box count as two
separate setups.

## 1. Wire the commit gate

```sh
git config core.hooksPath .githooks
```

`.githooks/pre-commit` runs `./scripts/check.sh` and aborts the commit when it fails.
`core.hooksPath` is local configuration, not repository content, so **a clone without this
line has NO gate** — the commit succeeds and CI catches the problem later, if at all.

Verify it is live:

```sh
git config core.hooksPath        # -> .githooks
```

`git commit --no-verify` skips the gate. That hatch exists for {{OWNER_NAME}}'s WIP commits.
Agents must not use it (`AGENTS.md`).

## 2. Toolchain on PATH

`check.sh` needs {{TOOLCHAIN}}. Per-user installs are the usual trap here: they work in your
interactive shell and are missing from the non-login shell a git hook runs in, so the gate
fails for a reason that has nothing to do with the code.

{{TOOLCHAIN_SETUP_NOTES}}

If the gate fails with "command not found", that is this — not a broken build.

## 3. Prove the gate actually works

Once, on a fresh clone:

```sh
./scripts/check.sh --self-test
```

It injects each gate's failure condition and asserts the gate rejects it. A green
`CHECK: PASS` tells you the tree is clean; only the self-test tells you the gate could have
told you otherwise.

{{PROJECT_SETUP_STEPS}}
