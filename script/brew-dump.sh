#!/bin/sh
#
# brew-dump.sh
#
# Dumps currently installed Homebrew packages to the dotfiles Brewfile.
# Mails local user on failure.

BREWFILE="$HOME/dotfiles/Brewfile"

# Ensure brew is in PATH (cron has a minimal environment)
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"

if ! output=$(brew bundle dump --force --file="$BREWFILE" 2>&1); then
  echo "$output" | mail -s "brew-dump failed" "$USER"
fi
