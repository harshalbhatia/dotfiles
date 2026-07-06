#!/usr/bin/env bash
#
# Layer 2: get the repo into the VM and run bootstrap non-interactively.
#
# Usage: provision.sh <vm-name> <local|github>
#   local  — the working copy was mounted at boot via --dir=dotfiles:...;
#            copy it to ~/dotfiles inside the guest (copy, not symlink, so
#            bootstrap's own symlinking is genuinely exercised) and run
#            script/bootstrap.sh with DOTFILES_NONINTERACTIVE=1.
#   github — run the real published `curl | bash` flow against main.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/../lib.sh"

VM_NAME="${1:?usage: provision.sh <vm-name> <local|github>}"
MODE="${2:?usage: provision.sh <vm-name> <local|github>}"

SSH_USER="${DOTFILES_TEST_SSH_USER:-admin}"
SSH_PASS="${DOTFILES_TEST_SSH_PASS:-admin}"
VM_IP="$(cat "/tmp/${VM_NAME}.ip")"

vm_ssh() {
  sshpass -p "$SSH_PASS" ssh \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR -o ServerAliveInterval=15 -F /dev/null \
    "$SSH_USER@$VM_IP" "$@"
}

case "$MODE" in
  local)
    log_head "provision: local working copy -> ~/dotfiles"
    # Shared dir appears in the guest under "/Volumes/My Shared Files/dotfiles".
    vm_ssh 'SRC="/Volumes/My Shared Files/dotfiles"
      [ -d "$SRC" ] || { echo "shared dir not mounted: $SRC" >&2; exit 1; }
      rm -rf "$HOME/dotfiles"
      # Copy (not symlink) so the guest owns real files; exclude the .git objects
      # we do not need and anything huge.
      mkdir -p "$HOME/dotfiles"
      /usr/bin/rsync -a --exclude .git --exclude exec/llmctx-src "$SRC/" "$HOME/dotfiles/"'
    log_ok "repo copied into guest"

    log_head "running bootstrap (non-interactive) — this takes a while (brew bundle)"
    # Full output goes to ~/bootstrap.log in the guest (fetch it with:
    #   ssh admin@<ip> cat bootstrap.log); stream a filtered view here.
    vm_ssh "set -o pipefail; DOTFILES_NONINTERACTIVE=1 \
      DOTFILES_GIT_NAME='VM Test' DOTFILES_GIT_EMAIL='vm-test@example.com' \
      bash ~/dotfiles/script/bootstrap.sh 2>&1 | tee ~/bootstrap.log | tail -160"
    ;;
  github)
    log_head "provision: real curl|bash install from GitHub main"
    vm_ssh "DOTFILES_NONINTERACTIVE=1 \
      DOTFILES_GIT_NAME='VM Test' DOTFILES_GIT_EMAIL='vm-test@example.com' \
      bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/harshalbhatia/dotfiles/main/script/install.sh)\"" 2>&1 | tail -100
    ;;
  *)
    die "unknown provision mode: $MODE (want local|github)"
    ;;
esac

log_ok "provision ($MODE) finished"
