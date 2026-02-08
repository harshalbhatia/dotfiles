# Idempotent Dotfiles Setup Plan

## 1. Pick a single orchestration entrypoint
- Make `bin/dot` the canonical setup command.
- Update `script/bootstrap.sh` to delegate to `bin/dot`, or remove Brew-related steps from bootstrap to avoid duplicate installs.

## 2. Make every step “check‑then‑do”
### `script/bootstrap.sh`
- **Hostname**: only prompt if hostname is unset or differs from desired value; add `DOTFILES_HOSTNAME` env var for non-interactive runs.
- **Git config**: only prompt if `git/gitconfig.local.symlink` is missing; add `DOTFILES_GIT_NAME` and `DOTFILES_GIT_EMAIL` env vars.
- **Symlinks**: in non-interactive mode, default to a deterministic action (backup or skip) to avoid prompts.
- **Fonts + z**: guard installs with presence checks so re-runs are no-ops.
- **SSH keygen**: only generate if missing; avoid repeated clipboard output on re-run.
- **Reload zshrc**: remove or make optional to avoid spawning shells on re-run.

### `bin/dot`
- **macOS defaults**: allow opt-in via flag (`--defaults`) or env var (`DOTFILES_APPLY_DEFAULTS=1`).
- **brew update**: make optional (`--brew-update`).
- **brew bundle**: keep as default (idempotent).

## 3. Add a non-interactive mode
- Add `--non-interactive` or `DOTFILES_NONINTERACTIVE=1`.
- Skip prompts; use env vars for hostname and gitconfig; default link conflict action.

## 4. Remove duplicate Brew install path
- Option A (recommended): remove `install_brew_deps` and `bin/dot` call from `bootstrap.sh` and just call `bin/dot` once.
- Option B: keep bootstrap for dotfiles only and do not call `bin/dot` inside it.

## 5. Make bootstrap re-runnable without side effects
- Guard each step with a check.
- Add optional `--dry-run` to show intended changes.

## 6. Documentation (optional)
- Note canonical command and flags if you want to update README.
