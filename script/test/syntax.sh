#!/usr/bin/env bash
#
# Layer 1: parse every shell script with its interpreter's -n (no-exec) mode.
# Catches syntax errors — the dumbest and most common new-machine breakage.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"

log_head "syntax check (bash -n / sh -n / zsh -n)"

need zsh

fails=0 checked=0
while IFS= read -r f; do
  interp="$(interp_for "$f")"
  checked=$((checked + 1))
  if "$interp" -n "$REPO_ROOT/$f" 2>/tmp/dotfiles-syntax.$$; then
    :
  else
    log_fail "$f ($interp -n)"
    sed 's/^/      /' /tmp/dotfiles-syntax.$$ >&2 || true
    fails=$((fails + 1))
  fi
done < <(list_shell_scripts)
rm -f /tmp/dotfiles-syntax.$$

if [ "$fails" -eq 0 ]; then
  log_ok "syntax: $checked scripts parsed cleanly"
else
  die "syntax: $fails of $checked scripts failed to parse"
fi
