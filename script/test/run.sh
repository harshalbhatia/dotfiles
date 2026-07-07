#!/usr/bin/env bash
#
# Dotfiles test entrypoint.
#
#   run.sh lint     shellcheck (bash/sh scripts)
#   run.sh syntax   bash -n / sh -n / zsh -n on every script
#   run.sh unit     bats unit tests
#   run.sh fast     lint + syntax + unit (Layer 1, no VM)
#   run.sh vm       fresh-macOS bootstrap in a tart VM (Layer 2)
#   run.sh all      fast + vm
#
# VM flags are passed through, e.g.:  run.sh vm --github
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$HERE/lib.sh"

usage() {
  sed -n '2,20{/^#/p}' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

run_unit() {
  log_head "bats unit tests"
  need bats "brew install bats-core"
  bats "$HERE/unit"
}

cmd="${1:-fast}"
shift || true

case "$cmd" in
  lint)   bash "$HERE/lint.sh" ;;
  syntax) bash "$HERE/syntax.sh" ;;
  unit)   run_unit ;;
  fast)
    bash "$HERE/lint.sh"
    bash "$HERE/syntax.sh"
    run_unit
    log_ok "Layer 1 (fast) passed"
    ;;
  vm)     bash "$HERE/vm/run-e2e.sh" "$@" ;;
  all)
    bash "$HERE/run.sh" fast
    bash "$HERE/vm/run-e2e.sh" "$@"
    ;;
  -h|--help|help) usage 0 ;;
  *) log_fail "unknown command: $cmd"; usage 1 ;;
esac
