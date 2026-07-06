#!/usr/bin/env bash
#
# Layer 2: stop and delete the ephemeral test VM. Safe to call repeatedly and
# on VMs in any state — every step is best-effort.
#
# Usage: teardown.sh <vm-name>
set -uo pipefail   # deliberately no -e: teardown must always run to the end
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/../lib.sh"

VM_NAME="${1:?usage: teardown.sh <vm-name>}"

log_head "tearing down VM $VM_NAME"

# Graceful stop (tart sends SIGINT, escalates to SIGKILL after --timeout),
# then delete. Both best-effort: the VM may already be stopped or gone.
tart stop --timeout 30 "$VM_NAME" 2>/dev/null || true
if tart delete "$VM_NAME" 2>/dev/null; then
  log_ok "VM $VM_NAME stopped and deleted"
else
  log_info "VM $VM_NAME not present (or already deleted)"
fi

# Reap the backgrounded `tart run` process if it is still around.
if [ -f "/tmp/${VM_NAME}.tartpid" ]; then
  pid="$(cat "/tmp/${VM_NAME}.tartpid")"
  kill "$pid" 2>/dev/null || true
fi
rm -f "/tmp/${VM_NAME}.ip" "/tmp/${VM_NAME}.tartpid"
