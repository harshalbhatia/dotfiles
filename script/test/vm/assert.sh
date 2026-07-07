#!/usr/bin/env bash
#
# Layer 2: post-bootstrap state assertions, run over SSH against the VM.
#
# Usage: assert.sh <vm-name>
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/../lib.sh"

VM_NAME="${1:?usage: assert.sh <vm-name>}"
SSH_USER="${DOTFILES_TEST_SSH_USER:-admin}"
SSH_PASS="${DOTFILES_TEST_SSH_PASS:-admin}"
VM_IP="$(cat "/tmp/${VM_NAME}.ip")"

vm_ssh() {
  sshpass -p "$SSH_PASS" ssh \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o PubkeyAuthentication=no -o PreferredAuthentications=password \
    -o LogLevel=ERROR -F /dev/null \
    "$SSH_USER@$VM_IP" "$@"
}

fails=0
check() {  # check <description> <remote command>
  local desc="$1"; shift
  if vm_ssh "$@" >/dev/null 2>&1; then
    log_ok "$desc"
  else
    log_fail "$desc"
    fails=$((fails + 1))
  fi
}

log_head "asserting post-bootstrap state in VM"

# Core symlinks exist and resolve into ~/dotfiles.
check "~/.zshrc is a symlink into ~/dotfiles" \
  '[ -L "$HOME/.zshrc" ] && readlink "$HOME/.zshrc" | grep -q "dotfiles/zsh/zshrc.symlink"'
check "~/.gitignore is a symlink into ~/dotfiles" \
  '[ -L "$HOME/.gitignore" ] && readlink "$HOME/.gitignore" | grep -q "dotfiles/git"'
check "~/.p10k.zsh is a symlink into ~/dotfiles" \
  '[ -L "$HOME/.p10k.zsh" ] && readlink "$HOME/.p10k.zsh" | grep -q "dotfiles/zsh"'

# Generated (not tracked) local git identity.
check "~/.gitconfig.local exists with test identity" \
  'grep -q "VM Test" "$HOME/.gitconfig.local"'

# Claude config linking.
check "~/.claude/settings.json linked" '[ -L "$HOME/.claude/settings.json" ]'

# oh-my-zsh + z installed.
check "oh-my-zsh installed" '[ -d "$HOME/.oh-my-zsh" ]'
check "z installed" '[ -f "$HOME/z/z.sh" ]'

# SSH key generated.
check "ed25519 ssh key generated" '[ -f "$HOME/.ssh/id_ed25519.pub" ]'

# Interactive zsh starts cleanly (the ultimate smoke test for zshrc).
check "zsh -i -c exit succeeds" 'zsh -i -c exit'

# exec/ scripts are on PATH in an interactive shell.
check "exec/ on PATH (dot resolves)" 'zsh -i -c "command -v dot" '

# brew bundle state: non-fatal — casks flake; report but do not fail the run.
log_info "brew bundle check (informational)"
if vm_ssh 'eval "$(/opt/homebrew/bin/brew shellenv)"; brew bundle check --file="$HOME/dotfiles/Brewfile"' 2>&1 | tail -5; then
  log_ok "brew bundle check passed"
else
  log_warn "brew bundle check reported missing packages (non-fatal; casks flake)"
fi

if [ "$fails" -eq 0 ]; then
  log_ok "all assertions passed"
else
  die "$fails assertion(s) failed"
fi
