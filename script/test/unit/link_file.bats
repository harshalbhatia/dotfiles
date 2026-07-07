#!/usr/bin/env bats
#
# Unit tests for link_file() in script/bootstrap.sh — the symlink decision tree
# that decides whether to create, skip, overwrite, or back up a destination.

setup() {
  # Load only the function definitions from bootstrap.sh (no install sequence).
  export BOOTSTRAP_LIB_ONLY=1
  source "${BATS_TEST_DIRNAME}/../../bootstrap.sh"

  # link_file reads these as globals (normally set by install_dotfiles).
  overwrite_all=false
  backup_all=false
  skip_all=false

  TESTDIR="$(mktemp -d)"
  # Neutralize bootstrap's `set -e` so bats can evaluate assertions itself.
  set +e
}

teardown() {
  rm -rf "$TESTDIR"
}

@test "creates a symlink when the destination does not exist" {
  echo original > "$TESTDIR/src"
  link_file "$TESTDIR/src" "$TESTDIR/dst"
  [ -L "$TESTDIR/dst" ]
  [ "$(readlink "$TESTDIR/dst")" = "$TESTDIR/src" ]
}

@test "skips when the destination already points at the same source" {
  echo original > "$TESTDIR/src"
  ln -s "$TESTDIR/src" "$TESTDIR/dst"
  run link_file "$TESTDIR/src" "$TESTDIR/dst"
  [ "$status" -eq 0 ]
  [[ "$output" == *skipped* ]]
  [ "$(readlink "$TESTDIR/dst")" = "$TESTDIR/src" ]
}

@test "backs up an existing regular file when backup_all=true" {
  echo original > "$TESTDIR/src"
  echo preexisting > "$TESTDIR/dst"
  backup_all=true
  link_file "$TESTDIR/src" "$TESTDIR/dst"
  [ -L "$TESTDIR/dst" ]
  [ "$(readlink "$TESTDIR/dst")" = "$TESTDIR/src" ]
  [ -f "$TESTDIR/dst.backup" ]
  [ "$(cat "$TESTDIR/dst.backup")" = preexisting ]
}

@test "overwrites an existing regular file when overwrite_all=true" {
  echo original > "$TESTDIR/src"
  echo preexisting > "$TESTDIR/dst"
  overwrite_all=true
  link_file "$TESTDIR/src" "$TESTDIR/dst"
  [ -L "$TESTDIR/dst" ]
  [ "$(readlink "$TESTDIR/dst")" = "$TESTDIR/src" ]
  [ ! -e "$TESTDIR/dst.backup" ]
}
