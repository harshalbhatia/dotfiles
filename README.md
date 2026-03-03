# Dotfiles

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/harshalbhatia/dotfiles/main/script/install.sh)"
```

One command on a fresh Mac: installs Xcode CLT, Homebrew, clones this repo, symlinks dotfiles, installs Brewfile packages, configures shell, generates SSH key.

## What's Included

- **Shell** -- zsh + Oh My Zsh + Powerlevel10k, custom aliases/functions
- **Packages** -- everything in `Brewfile` via Homebrew
- **Git** -- global config + per-machine local identity (`~/.gitconfig.local`)
- **SSH** -- ed25519 key generation, copied to clipboard
- **macOS** -- sensible defaults via `macos/set-defaults.sh`
- **Exec** -- custom scripts in `exec/` added to `$PATH`

## Day-to-Day

| Command | What it does |
|---------|-------------|
| `dot` | Re-run bootstrap (update symlinks, brew bundle, etc.) |
| `dot -b` | Dump current brew state to Brewfile |

## Customization

- **Packages**: edit `Brewfile`
- **Shell**: add/edit files in `zsh/`
- **Git identity**: `~/.gitconfig.local` (created on first run, not tracked)
- **Private config**: `~/.zshlocal` (sourced if present)
- **Executables**: drop scripts into `exec/`

## Structure

```
script/install.sh     # Remote entry point (curl-safe)
script/bootstrap.sh   # Main setup orchestrator
zsh/                  # Shell config (symlinked to ~)
git/                  # Git config templates
macos/                # macOS defaults & launch agents
exec/                 # Custom scripts on $PATH
Brewfile              # Homebrew packages
```

## Manual Steps

- Set Caps Lock to Esc (System Settings > Keyboard > Modifier Keys)
- Mackup backup/restore for app preferences
