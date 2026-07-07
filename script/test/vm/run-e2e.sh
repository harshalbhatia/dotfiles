#!/usr/bin/env bash
#
# Layer 2 orchestrator: boot -> provision -> assert -> teardown.
#
# Usage: run-e2e.sh [--github] [--keep] [--full]
#   --github   run the real curl|bash install from GitHub main instead of
#              injecting the local working copy (default: local)
#   --keep     leave the VM running after the test (for debugging);
#              teardown manually with:  script/test/vm/teardown.sh <name>
#   --full     install the entire Brewfile. Default is a smoke Brewfile:
#              one core formula, one cask, one third-party-tap formula —
#              exercises PATH, tap trusting, and both install kinds in
#              minutes instead of hours. (--github implies --full: the
#              curl|bash flow can't be intercepted to swap the Brewfile.)
#
# Env knobs:
#   DOTFILES_TEST_IMAGE          base image (default ghcr.io/cirruslabs/macos-tahoe-base:latest)
#   DOTFILES_TEST_BOOT_TIMEOUT   seconds to wait for IP/SSH (default 300)
#   DOTFILES_TEST_SMOKE_FORMULA / _CASK / _TAP_FORMULA   override smoke picks
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$HERE/../lib.sh"

MODE=local
KEEP=0
FULL=0
for arg in "$@"; do
  case "$arg" in
    --github) MODE=github; FULL=1 ;;
    --keep)   KEEP=1 ;;
    --full)   FULL=1 ;;
    *) die "unknown flag: $arg (want --github, --keep and/or --full)" ;;
  esac
done
export DOTFILES_TEST_FULL="$FULL"

need tart "brew install cirruslabs/cli/tart"
need sshpass "brew install sshpass"

VM_NAME="dotfiles-test-$$"

cleanup() {
  status=$?
  # Salvage the full bootstrap log before the VM disappears.
  if [ -f "/tmp/${VM_NAME}.ip" ]; then
    LOG_DEST="${TMPDIR:-/tmp}/${VM_NAME}-bootstrap.log"
    if sshpass -p "${DOTFILES_TEST_SSH_PASS:-admin}" scp \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o PubkeyAuthentication=no -o PreferredAuthentications=password \
        -o LogLevel=ERROR -F /dev/null \
        "${DOTFILES_TEST_SSH_USER:-admin}@$(cat "/tmp/${VM_NAME}.ip"):bootstrap.log" \
        "$LOG_DEST" 2>/dev/null; then
      log_info "guest bootstrap log saved to $LOG_DEST"
    fi
  fi
  if [ "$KEEP" = "1" ]; then
    log_warn "--keep: leaving VM $VM_NAME running (IP: $(cat "/tmp/${VM_NAME}.ip" 2>/dev/null || echo '?'))"
    log_warn "teardown later with: $HERE/teardown.sh $VM_NAME"
  else
    bash "$HERE/teardown.sh" "$VM_NAME"
  fi
  exit "$status"
}
trap cleanup EXIT

log_head "dotfiles VM e2e — mode=$MODE, brewfile=$([ "$FULL" = 1 ] && echo full || echo smoke), vm=$VM_NAME"

# Only mount the working copy when we intend to use it.
if [ "$MODE" = "local" ]; then
  bash "$HERE/boot.sh" "$VM_NAME" "--dir=dotfiles:$REPO_ROOT:ro"
else
  bash "$HERE/boot.sh" "$VM_NAME"
fi

bash "$HERE/provision.sh" "$VM_NAME" "$MODE"
bash "$HERE/assert.sh" "$VM_NAME"

log_ok "VM e2e ($MODE) passed"
