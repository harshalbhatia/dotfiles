#!/usr/bin/env bash
#
# Layer 1: lint the bash/sh scripts. zsh scripts are skipped because the
# linter has no support for the zsh dialect.
#
# Severity defaults to `error` so the gate is meaningful yet passable on an
# existing codebase. Bump with SHELLCHECK_SEVERITY=warning for a stricter pass.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"

SEVERITY="${SHELLCHECK_SEVERITY:-error}"

log_head "shellcheck (severity=$SEVERITY, zsh files skipped)"

need shellcheck "brew install shellcheck"

# Collect bash/sh targets.
targets=()
while IFS= read -r f; do
  case "$(interp_for "$f")" in
    zsh) continue ;;
  esac
  targets+=("$f")
done < <(list_shell_scripts)

if [ "${#targets[@]}" -eq 0 ]; then
  log_warn "no bash/sh scripts found to lint"
  exit 0
fi

# -x: follow `source` where possible. Run from repo root for stable paths.
cd "$REPO_ROOT"
if shellcheck -x -S "$SEVERITY" "${targets[@]}"; then
  log_ok "shellcheck: ${#targets[@]} scripts clean at severity=$SEVERITY"
else
  die "shellcheck reported issues (see above)"
fi
