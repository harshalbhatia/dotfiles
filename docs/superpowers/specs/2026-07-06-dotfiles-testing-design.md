# Dotfiles Testing — Design Spec

Date: 2026-07-06
Repo: `/Users/hb/dotfiles`
Status: Approved (design), pending implementation

## Problem

The setup flow (`script/install.sh` → `script/bootstrap.sh`) is the thing that
breaks on new machines, and there is no way to test it short of wiping a real
Mac. There are also no cheap guardrails: no shellcheck, no syntax checks, no
unit tests. This project adds a two-layer local test system, plus the
non-interactive bootstrap mode required to run the flow unattended.

Decisions locked during brainstorming:

- **Scope:** layered — fast local checks *plus* a full fresh-macOS bootstrap in
  a tart VM.
- **Non-interactive:** add a real `DOTFILES_NONINTERACTIVE` mode (per
  `docs/update-plan.md`), not a brittle expect/pipe wrapper.
- **Run location:** local on-demand only. No GitHub Actions. (tart needs
  Apple-Silicon virtualization that hosted CI runners can't nest.)
- **Repo source into VM:** support both, default to injecting the local working
  copy; optional flag runs the real `curl | bash` from GitHub `main`.

## Non-Goals

- Merging the duplicate brew-install path (bootstrap runs `brew bundle`; `dot`
  also runs it). Real issue, tracked in `docs/improvement.md`, but orthogonal to
  testing — out of scope here.
- Testing the `xcode-select --install` step. It shows a GUI dialog that cannot
  be driven headless; documented as a known coverage gap.
- CI / cloud runners.

## Architecture

```
script/test/
  run.sh              # entrypoint: run.sh {lint|syntax|unit|vm|all}
  lib.sh             # shared logging/helpers for the harness
  lint.sh             # layer 1: shellcheck
  syntax.sh           # layer 1: bash -n / sh -n / zsh -n per shebang
  unit/               # layer 1: bats unit tests
    link_file.bats
  vm/
    boot.sh           # clone base image -> ephemeral VM, start, wait for SSH
    provision.sh      # get repo into VM (local|github), run bootstrap NI
    assert.sh         # layer 2: post-run state checks over SSH
    teardown.sh       # stop + delete VM (trap-guarded)
    run-e2e.sh        # orchestrates boot->provision->assert->teardown
```

## Prerequisite — Non-interactive bootstrap mode

Required for Layer 2; also fixes real new-machine friction. Behaviour is
gated on `DOTFILES_NONINTERACTIVE=1` (or `--non-interactive`). When the flag is
**off**, the interactive path behaves exactly as today.

When on:

- **No prompt ever blocks.** Every `read` is guarded.
- **Hostname:** driven by `DOTFILES_HOSTNAME`. If unset, skip silently.
- **Gitconfig:** driven by `DOTFILES_GIT_NAME` / `DOTFILES_GIT_EMAIL`. Also fix
  the existing bug where `setup_gitconfig` tests the in-repo
  `git/gitconfig.local.symlink` instead of the generated `~/.gitconfig.local`.
  In NI mode, only generate when the target `~/.gitconfig.local` is missing;
  fall back to placeholder name/email if the env vars are unset so the run
  never blocks.
- **Symlink conflicts:** deterministic default = **backup** (set
  `backup_all=true` up front in NI mode), so `link_file` never prompts.
- **SSH keygen:** generate only if missing; no `pbcopy`/clipboard, no key echo
  in NI mode (pbcopy may not exist / be meaningful in a headless VM).
- **reload_zshrc:** skipped in NI mode (never spawn an interactive `zsh`).

## Layer 1 — Fast local checks (seconds)

- **lint.sh:** run `shellcheck` over `script/**`, `exec/*` (shell ones),
  `git-hooks/*`, `zsh/*.symlink`, `macos/*.sh`. Non-shell/binary files skipped.
- **syntax.sh:** for each script, pick the checker from its shebang
  (`bash -n` / `sh -n` / `zsh -n`) and assert it parses.
- **unit/link_file.bats:** exercise the `link_file` decision tree (new link,
  already-correct symlink is skipped, overwrite, backup) against a temp `$HOME`
  by sourcing the function in isolation. This is the highest-value pure logic.

Toolchain (added to Brewfile so it is reproducible): `shellcheck`, `shfmt`,
`bats-core`.

## Layer 2 — Fresh-macOS VM e2e (tart)

- **Image:** `ghcr.io/cirruslabs/macos-sequoia-base:latest` (ships Xcode CLT +
  Homebrew; SSH `admin`/`admin`). Chosen over vanilla because the
  Xcode-CLT-install step can't be tested headless anyway.
- **boot.sh:** `tart clone` the base image to an ephemeral VM named
  `dotfiles-test-<pid>`; `tart run --no-graphics` in the background; poll
  `tart ip` then SSH until reachable (bounded timeout).
- **provision.sh:**
  - *local mode (default):* `tart run --dir=dotfiles:$REPO_ROOT` mounts the
    working copy; inside the VM copy it to `~/dotfiles` (copy, not symlink, so
    bootstrap's own symlinking is genuinely exercised), then run
    `DOTFILES_NONINTERACTIVE=1 ~/dotfiles/script/bootstrap.sh`.
  - *github mode (`--github` flag):* run the real
    `curl -fsSL .../install.sh | bash` against `main`.
- **assert.sh (over SSH):**
  - core symlinks exist and resolve into `~/dotfiles` (e.g. `~/.zshrc`).
  - `~/.gitconfig.local` was generated.
  - `brew bundle check --file=~/dotfiles/Brewfile` passes (or reports only
    known-flaky casks; treated as non-fatal with a warning).
  - `zsh -i -c exit` exits 0.
  - representative `exec/` scripts are resolvable on `PATH`.
- **teardown.sh:** always `tart stop` + `tart delete` the ephemeral VM; wired to
  an `EXIT`/`ERR` trap so a failed run never leaks a VM.
- **Concurrency:** Virtualization.framework licensing caps 2 running macOS VMs;
  the harness uses exactly one.

## Error Handling

- Harness scripts use `set -euo pipefail` and a shared `lib.sh` logger.
- `run.sh vm` fails fast with a clear message if `tart` is missing.
- VM SSH wait and boot have bounded timeouts; on timeout, teardown still runs.
- Layer 1 aggregates failures and returns non-zero if any sub-check fails.

## Deliverables

1. Non-interactive bootstrap mode in `script/bootstrap.sh`.
2. `script/test/` harness (both layers) with `run.sh` entrypoint.
3. Brewfile additions: `shellcheck`, `shfmt`, `bats-core`, `tart`.
4. `docs/testing.md` runbook.

## Verification

- Layer 1 runs green locally.
- Full VM e2e (local mode) completes: boots, provisions, asserts, tears down.
- Non-interactive bootstrap produces the same symlink/state result as the
  interactive path.
