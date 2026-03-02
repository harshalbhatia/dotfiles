#!/bin/sh
#
# Cron
#
# Installs cron jobs defined in dotfiles.
# Preserves any existing cron entries not managed here.

DOTFILES_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"

# Define managed cron jobs (one per line, ending with a # tag for identification)
MANAGED_JOBS="0 9 * * * $DOTFILES_ROOT/script/brew-dump.sh # brew-dump"

# Get existing crontab, stripping out any previously managed jobs
existing=$(crontab -l 2>/dev/null | grep -v '# brew-dump$')

# Combine existing + managed jobs
printf '%s\n%s\n' "$existing" "$MANAGED_JOBS" | crontab -

echo "  Cron jobs installed."
