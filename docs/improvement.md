# Dotfiles Improvement Report

Date: 2026-02-02
Repo: `/Users/hb/dotfiles`

## Executive Summary

Your repo is already **useful, practical, and highly personalized**. The strongest parts are:
- strong automation intent (`script/bootstrap.sh`, `bin/dot`),
- solid package inventory (`Brewfile`),
- meaningful custom tooling (`bin/power-app-manager`, `bin/llm-cli-config`),
- and modular shell config (`zsh/*.zsh`).

To make this "legendary" (portable, reproducible, safe, fast, and maintainable), the biggest upgrades are:
1. **Security hardening** (remove token leaks + `eval` input execution).
2. **Idempotent bootstrap architecture** (single source of truth, no duplicated install paths).
3. **Portability cleanup** (remove machine/user coupling from launch agents and shell paths).
4. **Operational quality** (lint/tests/CI for scripts).
5. **Shell performance** (bring startup from ~1.2s closer to sub-400ms).

---

## Snapshot of Current State

- Tracked files: **50** (`rg --files | wc -l`)
- Main control plane:
  - `script/bootstrap.sh`
  - `bin/dot`
  - `Brewfile`
  - `zsh/zshrc.symlink` + `zsh/*.zsh`
- Measured interactive shell startup baseline (`zsh -i -c exit`, 10 runs):
  - avg: **~1212ms**
  - p95: **~1156ms**
  - first-run warmup observed around **~1948ms**

---

## What You Already Do Well

1. **Separation by concern in zsh config**
   - `zsh/instant.zsh`, `zsh/path.zsh`, `zsh/aliases.zsh`, `zsh/completions.zsh` is the right shape.
2. **Private override hook exists**
   - `zsh/zshrc.symlink:56` loads `~/.zshlocal`.
3. **Homebrew as central package catalog**
   - `Brewfile` is comprehensive and acts as an inventory of dev environment intent.
4. **Custom automation has real value**
   - `bin/power-app-manager` and related docs are a serious, useful system.
5. **Recent cleanup momentum is strong**
   - recent commits show active maintenance and willingness to harden.

---

## Priority Findings (Highest Impact First)

## P0 — Security + Safety

### 1) Token leak in VPN helper output
- Evidence: `bin/gojek-vpn:35` prints `"$token $vpnname $vpn_otp"`.
- Risk: secrets can leak to terminal scrollback, logs, screen recording, and shell history tooling.
- Fix:
  - Remove token echo immediately.
  - If debugging is needed, print only masked token (last 4 chars).

### 2) Command injection risk in screen converter input parsing
- Evidence: `bin/srconv:255`, `bin/srconv:267`, `bin/srconv:276` use `in=$(eval echo "$in")`.
- Risk: if list file contains shell payload, `eval` executes arbitrary commands.
- Fix:
  - Replace with safe expansion strategy (no `eval`), e.g. controlled tilde expansion only.
  - Treat list file lines as data, never as shell code.

---

## P1 — Reproducibility + Portability

### 3) Bootstrap has duplicated install orchestration
- Evidence:
  - `script/bootstrap.sh:290-308` runs `brew bundle` interactively.
  - `script/bootstrap.sh:338-347` then calls `bin/dot`.
  - `bin/dot:145-147` runs `brew bundle --file=...` again.
- Risk: repeated installs, harder troubleshooting, inconsistent behavior.
- Fix:
  - Make **one** orchestrator responsible for package install (prefer `bin/dot` or `bootstrap`, not both).
  - Let the other be a thin wrapper.

### 4) `setup_gitconfig` logic is effectively bypassed
- Evidence:
  - `script/bootstrap.sh:95` checks `git/gitconfig.local.symlink` in repo.
  - That file already exists and is tracked (`git/gitconfig.local.symlink`).
- Risk: onboarding logic doesn’t run as intended; setup path unclear.
- Fix:
  - Check target path in `$HOME` (e.g. `~/.gitconfig.local`) instead.
  - Keep template in repo, generated result untracked/private.

### 5) Hardcoded user path in LaunchAgent plist
- Evidence: `macos/com.user.power-app-manager.plist:10`, `:24`, `:27` use `/Users/hb/...`.
- Risk: breaks on any machine/user mismatch.
- Fix:
  - Treat plist as template and render `$HOME`-aware output during setup.
  - Or generate plist entirely from script at install time.

### 6) Legacy launchctl subcommands still used
- Evidence:
  - `bin/dot:62`, `:97`, `:103`
  - `script/setup-power-app-manager.sh:39`, `:77`
  - `bin/power-app-manager:272`, `:292`
- Risk: fragile behavior over time; inconsistent modern macOS service control.
- Fix:
  - Migrate to modern `launchctl bootstrap/bootout` flow and explicit enable/disable semantics.

### 7) Mixed scheduler strategy for same “chime” use case
- Evidence:
  - Launchd path in `bin/dot` (`sound` commands).
  - Cron path in `zsh/ten_minute_chime.zsh`.
- Risk: duplicate mechanisms, drift, harder support.
- Fix:
  - Standardize on **launchd** for macOS user jobs.
  - Keep only one mechanism and one source of truth.

### 8) Dotfiles path assumptions still hardcoded
- Evidence:
  - `zsh/zshrc.symlink:1-6` and wrappers `bin/ivpn.command`, `bin/pvpn.command`, `bin/svpn.command` use `~/dotfiles/...`.
- Risk: clone path changes break config.
- Fix:
  - Resolve repo root dynamically where possible.
  - For shell source files, compute root from current file path and source relative modules.

---

## P1 — Secrets, Identity, and Public/Private Boundaries

### 9) Personal git identity stored directly in tracked file
- Evidence: `git/gitconfig.local.symlink:1-5`.
- Risk: less flexible for multi-identity/multi-machine use; privacy if repo becomes public.
- Fix:
  - Keep only `git/gitconfig.local.symlink.example` tracked.
  - Generate local private file on bootstrap and ignore it.

### 10) Top-level `.gitignore` is too minimal for an active automation repo
- Evidence: `.gitignore:1` only `.history`.
- Risk: local runtime artifacts keep reappearing as untracked noise.
- Fix:
  - Add focused ignore patterns for known ephemeral/runtime files.
  - Keep ignores tight to avoid hiding real config accidentally.

---

## P2 — Reliability + Maintainability

### 11) Many scripts lack strict mode (`set -euo pipefail`)
- Evidence: e.g. `bin/gojek-vpn`, `bin/llm-cli-config`, `bin/power-app-manager`, `bin/analyze-energy-usage`.
- Risk: silent failures, unset var bugs, partial writes.
- Fix:
  - Add strict mode where safe.
  - For intentionally tolerant scripts, comment exceptions explicitly.

### 12) Shell quoting is inconsistent in utility functions
- Evidence:
  - `zsh/aliases.zsh:43` uses unquoted `$@`.
  - `zsh/aliases.zsh:58` `git clone $@`.
  - `zsh/aliases.zsh:62` unquoted command substitution.
- Risk: paths with spaces/globs behave unpredictably.
- Fix:
  - Quote arrays/args (`"$@"`, `"$(...)"`) and avoid unsafe splitting.

### 13) `bin/power-app-manager` is valuable but monolithic (766 lines)
- Evidence: single large script handling config, discovery, orchestration, CLI.
- Risk: hard to test and evolve safely.
- Fix:
  - Split into modules (`lib/power/state.sh`, `lib/power/apps.sh`, `lib/power/launchd.sh`, CLI entrypoint).
  - Keep command parser thin.

### 14) Config/state files are `source`d directly
- Evidence:
  - `bin/power-app-manager:120`, `:400`
- Risk: code execution if files are corrupted/malicious.
- Fix:
  - Prefer parse-only formats (TOML/YAML/JSON) + parser.
  - If keeping shell format, validate keys and file permissions before sourcing.

### 15) Tracked compiled binary in repo (`bin/llmctx`)
- Evidence: `bin/llmctx` is Mach-O arm64, ~2.7MB while source exists under `bin/llmctx-src/`.
- Risk: architecture lock-in, larger diffs, unclear provenance/rebuild path.
- Fix:
  - Build on-demand from source or release via artifacts.
  - Keep source as truth and document reproducible build command.

### 16) Dependency manager drift (Anaconda vs Miniconda)
- Evidence:
  - `Brewfile:56` installs `cask "anaconda"`.
  - `zsh/zshrc.symlink:60-67` points to Miniconda Caskroom path.
- Risk: fragile conda init state and user confusion.
- Fix:
  - Pick one conda distribution and align Brewfile + shell init.

---

## P2 — DX + Documentation

### 17) README has stale TODO-centric intro and mixed maturity notes
- Evidence: `README.md:1-17` opens with manual tasks and internal TODOs.
- Risk: onboarding signal is weaker than it should be.
- Fix:
  - Move TODOs to `docs/roadmap.md`.
  - Keep README focused on setup, profile selection, and troubleshooting.

### 18) No automated quality gate in repo
- Evidence: no `.github/workflows/`, no script lint pipeline.
- Risk: regressions are manual.
- Fix:
  - Add CI for shell lint/format + syntax checks + markdown lint.

---

## Legendary Dotfiles Blueprint (Target State)

## 1) Single declarative entrypoint
- `bin/setup` becomes the canonical orchestration command.
- `script/bootstrap.sh` either wraps `bin/setup` or is removed.

## 2) Profile-based installs
- Split package intent:
  - `Brewfile.base`
  - `Brewfile.work`
  - `Brewfile.personal`
  - `Brewfile.heavy`
- Setup uses `DOTFILES_PROFILE=work` to select files.

## 3) Private/public separation by design
- Public repo: portable defaults only.
- Private machine data:
  - `~/.zshlocal`
  - local git identity file
  - provider tokens, VPN secrets, one-off scripts

## 4) Modular script architecture
- `lib/` for common shell utilities (logging, OS checks, file linking, retry).
- Keep each command script small and testable.

## 5) Quality automation
- Add pre-commit + CI:
  - ShellCheck
  - shfmt
  - simple smoke tests (`zsh -n`, `bash -n`, `sh -n`)
  - optional: secret scan (gitleaks)

## 6) Performance budget
- Declare startup budget: e.g. p95 `zsh -i -c exit` < 400ms.
- Track and optimize plugin load and heavy init blocks.

---

## Concrete 30-Day Roadmap

### Week 1 — Critical hardening
- Remove token output from `bin/gojek-vpn`.
- Remove `eval` from `bin/srconv` path parsing.
- Align conda strategy (Anaconda vs Miniconda).
- Decide single scheduler strategy (launchd only).

### Week 2 — Reproducibility
- Merge duplicate install flows (`bootstrap` vs `bin/dot`).
- Fix gitconfig generation logic (`script/bootstrap.sh`).
- Template power-app-manager plist with dynamic home path.

### Week 3 — Script quality
- Add strict mode where safe.
- Normalize quoting in zsh functions/aliases.
- Break `bin/power-app-manager` into modules.

### Week 4 — Automation + docs
- Add CI workflow for lint/syntax checks.
- Refactor README to onboarding-first structure.
- Add `docs/architecture.md` + `docs/runbook.md`.

---

## Fast Wins (Can Be Done in One Sitting)

- [ ] Remove `echo "$token ..."` from `bin/gojek-vpn:35`.
- [ ] Replace `eval echo` in `bin/srconv:255,267,276`.
- [ ] Update LaunchAgent setup to modern launchctl subcommands.
- [ ] Stop maintaining both cron and launchd paths for chime.
- [ ] Move tracked personal git identity to local/private generation path.

---

## Suggested Metrics to Track Going Forward

- Shell startup p95 (`zsh -i -c exit`).
- Time for first bootstrap on clean machine.
- Time for repeat bootstrap (idempotent run).
- Number of manual prompts in bootstrap.
- CI pass rate for shell lint/syntax checks.

---

## Reference Standards Used for This Review

- Homebrew Bundle docs (dump/check/cleanup workflow): `https://docs.brew.sh/Brew-Bundle-and-Brewfile`
- launchd guidance and launchctl domain model: `https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html`
- launchctl man page (legacy `load/unload` alternatives): `https://manp.gs/mac/1/launchctl`
- GitHub SSH key guidance (`ed25519`): `https://docs.github.com/en/authentication/connecting-to-github-with-ssh`
- ShellCheck: `https://github.com/koalaman/shellcheck`
- shfmt: `https://github.com/mvdan/sh`
- Optional dotfile management model reference: `https://www.chezmoi.io/`

---

## Final Assessment

You already have the hard part: **taste + automation intent + useful custom tools**.

If you execute the P0/P1 items and adopt the target architecture incrementally, this repo becomes:
- safer,
- dramatically more portable,
- easier to evolve,
- and genuinely "legendary" in day-to-day reliability.
