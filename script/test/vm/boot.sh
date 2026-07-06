#!/usr/bin/env bash
#
# Layer 2: clone the base image to an ephemeral VM and start it headless.
# Prints nothing on stdout except progress logs; state is communicated via the
# VM name the caller chose (see run-e2e.sh).
#
# Usage: boot.sh <vm-name> [extra tart-run args...]
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/../lib.sh"

VM_NAME="${1:?usage: boot.sh <vm-name> [tart run args...]}"
shift

BASE_IMAGE="${DOTFILES_TEST_IMAGE:-ghcr.io/cirruslabs/macos-tahoe-base:latest}"
SSH_USER="${DOTFILES_TEST_SSH_USER:-admin}"
SSH_PASS="${DOTFILES_TEST_SSH_PASS:-admin}"
BOOT_TIMEOUT="${DOTFILES_TEST_BOOT_TIMEOUT:-300}"   # seconds to wait for SSH

need tart "brew install cirruslabs/cli/tart"
need sshpass "brew install sshpass"

log_info "cloning $BASE_IMAGE -> $VM_NAME (first pull downloads ~25-40GB)"
tart clone "$BASE_IMAGE" "$VM_NAME"

log_info "starting VM headless"
# --no-audio: headless contexts can lack the audio-output sandbox entitlement,
# which otherwise fails VM start with VZErrorDomain "audio output sandbox
# extension"; a test VM needs no sound anyway.
tart run --no-graphics --no-audio "$@" "$VM_NAME" &
TART_RUN_PID=$!
echo "$TART_RUN_PID" > "/tmp/${VM_NAME}.tartpid"

log_info "waiting for IP (timeout ${BOOT_TIMEOUT}s)"
VM_IP="$(tart ip "$VM_NAME" --wait "$BOOT_TIMEOUT")"
[ -n "$VM_IP" ] || die "could not obtain VM IP within ${BOOT_TIMEOUT}s"
log_ok "VM IP: $VM_IP"

log_info "waiting for SSH"
deadline=$(( $(date +%s) + BOOT_TIMEOUT ))
until sshpass -p "$SSH_PASS" ssh \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=5 -o LogLevel=ERROR -F /dev/null \
    "$SSH_USER@$VM_IP" true 2>/dev/null; do
  [ "$(date +%s)" -lt "$deadline" ] || die "SSH not reachable within ${BOOT_TIMEOUT}s"
  sleep 5
done
log_ok "SSH reachable: $SSH_USER@$VM_IP"

# Hand the IP to the caller via a well-known file (stdout carries logs).
echo "$VM_IP" > "/tmp/${VM_NAME}.ip"
