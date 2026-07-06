#!/usr/bin/env bash
#
# Layer 2 orchestrator: boot -> provision -> assert -> teardown.
#
# Usage: run-e2e.sh [--github] [--keep]
#   --github   run the real curl|bash install from GitHub main instead of
#              injecting the local working copy (default: local)
#   --keep     leave the VM running after the test (for debugging);
#              teardown manually with:  script/test/vm/teardown.sh <name>
#
# Env knobs:
#   DOTFILES_TEST_IMAGE          base image (default ghcr.io/cirruslabs/macos-tahoe-base:latest)
#   DOTFILES_TEST_BOOT_TIMEOUT   seconds to wait for IP/SSH (default 300)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$HERE/../lib.sh"

MODE=local
KEEP=0
for arg in "$@"; do
  case "$arg" in
    --github) MODE=github ;;
    --keep)   KEEP=1 ;;
    *) die "unknown flag: $arg (want --github and/or --keep)" ;;
  esac
done

need tart "brew install cirruslabs/cli/tart"
need sshpass "brew install sshpass"

VM_NAME="dotfiles-test-$$"

cleanup() {
  status=$?
  if [ "$KEEP" = "1" ]; then
    log_warn "--keep: leaving VM $VM_NAME running (IP: $(cat "/tmp/${VM_NAME}.ip" 2>/dev/null || echo '?'))"
    log_warn "teardown later with: $HERE/teardown.sh $VM_NAME"
  else
    bash "$HERE/teardown.sh" "$VM_NAME"
  fi
  exit "$status"
}
trap cleanup EXIT

log_head "dotfiles VM e2e — mode=$MODE, vm=$VM_NAME"

# Only mount the working copy when we intend to use it.
if [ "$MODE" = "local" ]; then
  bash "$HERE/boot.sh" "$VM_NAME" "--dir=dotfiles:$REPO_ROOT:ro"
else
  bash "$HERE/boot.sh" "$VM_NAME"
fi

bash "$HERE/provision.sh" "$VM_NAME" "$MODE"
bash "$HERE/assert.sh" "$VM_NAME"

log_ok "VM e2e ($MODE) passed"
