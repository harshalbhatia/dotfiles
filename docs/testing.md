# Testing

Two layers, one entrypoint: `script/test/run.sh`.

| Command | What it does | Time |
|---|---|---|
| `script/test/run.sh fast` | lint + syntax + unit (Layer 1) | seconds |
| `script/test/run.sh lint` | shellcheck over bash/sh scripts | seconds |
| `script/test/run.sh syntax` | `bash -n` / `sh -n` / `zsh -n` on every script | seconds |
| `script/test/run.sh unit` | bats unit tests (`script/test/unit/`) | seconds |
| `script/test/run.sh vm` | bootstrap on a fresh macOS VM, smoke Brewfile (Layer 2) | ~10–15 min (+ one-time ~30 GB image pull) |
| `script/test/run.sh vm --full` | same but installs the entire real Brewfile | 1–2 h |
| `script/test/run.sh all` | fast + vm | — |

Toolchain: `shellcheck`, `shfmt`, `bats-core`, `tart` (all in the Brewfile;
`sshpass` was already there).

## Layer 1 — fast checks

- **lint** skips zsh files (shellcheck has no zsh dialect) and gates at
  severity=`error`. Stricter pass: `SHELLCHECK_SEVERITY=warning script/test/run.sh lint`.
- **syntax** parses every tracked + untracked-but-not-ignored shell script with
  the interpreter its shebang names.
- **unit** exercises `link_file()` from `bootstrap.sh` (create / skip /
  backup / overwrite) in a temp dir. `bootstrap.sh` is sourceable without side
  effects via `BOOTSTRAP_LIB_ONLY=1`.

## Layer 2 — VM e2e (tart)

```
script/test/run.sh vm            # local working copy + smoke Brewfile (default)
script/test/run.sh vm --full     # install the entire real Brewfile
script/test/run.sh vm --github   # real `curl | bash` against GitHub main (implies --full)
script/test/run.sh vm --keep     # leave the VM running for debugging
```

**Smoke Brewfile (default):** instead of installing everything, the guest's
Brewfile is swapped for three representative entries — one core formula
(prefers `jq`), one cask (prefers `the-unarchiver`), and one third-party-tap
formula (prefers `yakitrak/yakitrak/obsidian-cli`, which also exercises
implied-tap trusting). Picks fall back to the first entry of each kind in the
real Brewfile and can be overridden via `DOTFILES_TEST_SMOKE_FORMULA`,
`DOTFILES_TEST_SMOKE_CASK`, `DOTFILES_TEST_SMOKE_TAP_FORMULA`. In smoke mode
`brew bundle check` is a hard assertion; in `--full` it is informational
(casks/mas flake headless).

Flow: `tart clone` the base image → boot headless → wait for SSH →
copy the repo in (or curl from GitHub) → run
`DOTFILES_NONINTERACTIVE=1 script/bootstrap.sh` → assert state over SSH
(symlinks, `~/.gitconfig.local`, oh-my-zsh, z, ssh key, `zsh -i -c exit`,
`exec/` on PATH; `brew bundle check` is informational) → teardown (always,
via trap; `--keep` skips it).

Knobs (env):

- `DOTFILES_TEST_IMAGE` — default `ghcr.io/cirruslabs/macos-tahoe-base:latest`
  (has Xcode CLT + Homebrew preinstalled; SSH `admin`/`admin`).
- `DOTFILES_TEST_BOOT_TIMEOUT` — seconds to wait for IP/SSH (default 300).
- `TART_HOME` — where tart keeps images/VMs (default `~/.tart`). Each cached
  base image is ~25–40 GB.

### Troubleshooting

- **`VZErrorDomain … "Failed to issue audio output sandbox extension"` right
  after "starting VM headless"**: the calling process is inside a sandbox
  (e.g. a `sandbox-exec` wrapper around an agent session). Virtualization
  .framework refuses to start VMs from such contexts regardless of flags —
  run `script/test/run.sh vm` from a plain terminal instead.
- **`failed to lock … .tart/cache … Bad file descriptor` / permission errors
  on `~/.tart`**: point tart elsewhere with `TART_HOME=/path/to/dir`.

### Known coverage gaps

- The `xcode-select --install` step in `script/install.sh` cannot be tested
  headless (GUI dialog); the `-base` images ship CLT preinstalled.
- `mas` installs fail in the VM (no App Store login) — `brew bundle` reports
  them, bootstrap treats bundle errors as non-fatal by design.
- Apple licensing allows max 2 concurrent macOS VMs; the harness uses 1.

## Non-interactive bootstrap

`DOTFILES_NONINTERACTIVE=1 script/bootstrap.sh` (or `--non-interactive`):

- never blocks on a prompt
- hostname: set only if `DOTFILES_HOSTNAME` is set (needs passwordless sudo)
- gitconfig: `DOTFILES_GIT_NAME` / `DOTFILES_GIT_EMAIL` (placeholder fallback)
- symlink conflicts: existing files are backed up (`*.backup`)
- ssh keygen: only if missing; no clipboard
