# Chezmoi Migration Plan (Suggestion Only)

## 1. Install & Bootstrap (no changes yet)
- Install chezmoi (Homebrew or nix).
- Initialize a new chezmoi repo: `chezmoi init --apply`.
- Configure `chezmoi.toml` with machine-specific data (name/email/hostname).

## 2. Map Your Repo Structure
- Treat your current `dotfiles/` as the source of truth.
- Decide mapping:
  - `zsh/*.symlink` → `dot_zshrc`, `dot_zprofile`, etc.
  - `ghostty/config` → `private_dot_config/ghostty/config`
  - `alacritty/alacritty.toml` → `dot_config/alacritty/alacritty.toml`
  - `bin/*` → `dot_local/bin/*` (or `private_dot_local/bin`)

## 3. Convert Symlink-Driven Files
- Replace `.symlink` convention with chezmoi’s file naming.
- Use `chezmoi add` to import existing files from `$HOME`.

## 4. Replace Bootstrap Logic
- Keep `bin/dot` for package installs or migrate to chezmoi hooks:
  - `run_onchange_*` for Brewfile updates
  - `run_once_*` for one-time steps (fonts, ssh keys)
- Convert interactive prompts to templated data in `chezmoi.toml`.

## 5. Templates & Conditionals
- Add OS checks: `{{ if eq .chezmoi.os "darwin" }}`.
- Move hostname/gitconfig prompts to templated values.

## 6. Apply & Verify
- `chezmoi diff` to confirm changes.
- `chezmoi apply` to test idempotency.

## 7. One-time macOS Settings Capture + Periodic Review
- Create a curated `macos/defaults.sh` that sets only the preferences you care about.
- Add a capture script that exports a **whitelist** of `defaults` domains and writes snapshots for review.
- On the new Mac: run the curated script once to match your baseline.
- On your current Mac: run the capture script periodically, review diffs, and update the whitelist as needed (no fully automatic capture).
