#!/usr/bin/env bash
#
# Shared helpers for the dotfiles test harness.

# Repo root, resolved from this file's location (script/test/lib.sh -> ../..).
TEST_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$TEST_LIB_DIR/../.." && pwd -P)"
export REPO_ROOT

# --- logging ---------------------------------------------------------------
_c() { printf '\033[%sm' "$1"; }
log_info()  { printf '  [ %s..%s ] %s\n' "$(_c 00\;34)" "$(_c 0)" "$1"; }
log_ok()    { printf '  [ %sOK%s ] %s\n' "$(_c 00\;32)" "$(_c 0)" "$1"; }
log_warn()  { printf '  [ %sWARN%s ] %s\n' "$(_c 0\;33)" "$(_c 0)" "$1"; }
log_fail()  { printf '  [%sFAIL%s] %s\n' "$(_c 0\;31)" "$(_c 0)" "$1" >&2; }
log_head()  { printf '\n%s==>%s %s\n' "$(_c 1\;36)" "$(_c 0)" "$1"; }

die() { log_fail "$1"; exit "${2:-1}"; }

need() { command -v "$1" >/dev/null 2>&1 || die "required tool not found: $1${2:+ ($2)}"; }

# --- shell-script discovery ------------------------------------------------
# True if a repo-relative path is a zsh file (rc modules and *.zsh.symlink).
_is_zsh_file() {
  case "$1" in
    zsh/*.zsh|*.zsh.symlink|zsh/zshrc.symlink) return 0 ;;
    *) return 1 ;;
  esac
}

# Print, one per line, every shell script in the repo — tracked plus
# untracked-but-not-ignored, so newly added scripts are checked before commit.
# A file counts as a shell script if it is a zsh rc file, ends in .sh, or has a
# shell shebang. Binaries, vendored sources, and non-shell files are skipped.
list_shell_scripts() {
  local f
  {
    cd "$REPO_ROOT" && git ls-files && git ls-files --others --exclude-standard
  } | sort -u | while IFS= read -r f; do
    case "$f" in
      exec/llmctx|exec/llmctx-src/*) continue ;;   # compiled binary + rust src
    esac
    [ -f "$REPO_ROOT/$f" ] || continue
    if _is_zsh_file "$f" || [ "${f##*.}" = "sh" ]; then
      printf '%s\n' "$f"
      continue
    fi
    # Otherwise include only if it carries a shell shebang.
    case "$(head -n1 "$REPO_ROOT/$f" 2>/dev/null)" in
      '#!'*sh) printf '%s\n' "$f" ;;
    esac
  done
}

# Pick the interpreter for a script: zsh files -> zsh, else from the shebang,
# else bash.
interp_for() {
  _is_zsh_file "$1" && { echo zsh; return; }
  case "$(head -n1 "$REPO_ROOT/$1" 2>/dev/null)" in
    *zsh*) echo zsh ;;
    *bash*) echo bash ;;
    *sh)   echo sh ;;
    *) echo bash ;;
  esac
}
