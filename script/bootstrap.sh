#!/usr/bin/env bash
#
# bootstrap installs things.

set -e

# When sourced with BOOTSTRAP_LIB_ONLY=1, load only the function definitions
# (used by unit tests) and skip every side effect and the install sequence.
if [ "${BOOTSTRAP_LIB_ONLY:-0}" != "1" ]; then
  cd "$(dirname "$0")/.."
  DOTFILES_ROOT=$(pwd -P)
fi

# Non-interactive mode: no prompt ever blocks; prompts are driven by env vars
# with safe defaults. Enabled by DOTFILES_NONINTERACTIVE=1 or --non-interactive.
# Used by the VM e2e harness (script/test/vm) and useful for unattended setup.
NONINTERACTIVE="${DOTFILES_NONINTERACTIVE:-0}"
for arg in "$@"; do
  case "$arg" in
    --non-interactive|--noninteractive|-y) NONINTERACTIVE=1 ;;
  esac
done

echo ''

info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
  printf "\r  [ \033[0;33m??\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

# Function to prompt for and set hostname on macOS
setup_hostname() {
  if [ "$(uname -s)" == "Darwin" ]; then
    info 'checking hostname configuration'

    current_computer_name=$(scutil --get ComputerName 2>/dev/null || echo "not set")
    current_localhost_name=$(scutil --get LocalHostName 2>/dev/null || echo "not set")
    current_host_name=$(scutil --get HostName 2>/dev/null || echo "not set")

    info "Current ComputerName: $current_computer_name"
    info "Current LocalHostName: $current_localhost_name"
    info "Current HostName: $current_host_name (Note: This might be unset)"

    if [ "$NONINTERACTIVE" = "1" ]; then
      if [ -n "${DOTFILES_HOSTNAME:-}" ]; then
        info "non-interactive: setting hostname to '$DOTFILES_HOSTNAME'"
        sudo -n scutil --set ComputerName "$DOTFILES_HOSTNAME" 2>/dev/null \
          && sudo -n scutil --set LocalHostName "$DOTFILES_HOSTNAME" 2>/dev/null \
          && sudo -n scutil --set HostName "$DOTFILES_HOSTNAME" 2>/dev/null \
          && success "hostname set to '$DOTFILES_HOSTNAME'" \
          || info "could not set hostname (no passwordless sudo?), skipping"
      else
        info "non-interactive: no DOTFILES_HOSTNAME set, skipping hostname"
      fi
      return
    fi

    user "Do you want to set/update the hostname for this Mac? [y/N]"
    if ! read -n 1 -r reply; then
      reply=''
    fi
    echo # Move to a new line

    if [[ "$reply" =~ ^[Yy]$ ]]; then
      user "Enter the new hostname (e.g., MyMacBookPro):"
      if ! read -r new_hostname; then
        new_hostname=''
      fi

      if [ -z "$new_hostname" ]; then
        info "No hostname entered, skipping update."
        return
      fi

      info "Attempting to set hostname to '$new_hostname'. You may be prompted for your password."
      # Refresh sudo timestamp
      sudo -v
      # Loop until sudo credentials are correct.
      while true; do
        # Check if we can run sudo commands.
        sudo -n true 2>/dev/null
        if [ $? -eq 0 ]; then
          break
        fi
        user "Please enter your sudo password:"
        sudo -v # Prompt for password
      done


      if sudo scutil --set ComputerName "$new_hostname" && \
         sudo scutil --set LocalHostName "$new_hostname" && \
         sudo scutil --set HostName "$new_hostname"; then
        success "Hostname successfully set to '$new_hostname'."
        info "Note: You may need to restart your terminal or even reboot for all applications to see the change."
      else
        fail "Failed to set hostname. Please check permissions or run manually."
      fi
    else
      info "Skipping hostname setup."
    fi
  fi
}

reload_zshrc() {
  info 'reload zshrc'
  zsh
}

setup_gitconfig() {
  if ! [ -f "$HOME/.gitconfig.local" ]
  then
    info 'setup gitconfig'

    git_credential='cache'
    if [ "$(uname -s)" == "Darwin" ]
    then
      git_credential='osxkeychain'
    fi

    if [ "$NONINTERACTIVE" = "1" ]; then
      git_authorname="${DOTFILES_GIT_NAME:-Dotfiles User}"
      git_authoremail="${DOTFILES_GIT_EMAIL:-dotfiles@example.com}"
      info "non-interactive: gitconfig as '$git_authorname <$git_authoremail>'"
    else
      user ' - What is your github author name?'
      read -e git_authorname
      user ' - What is your github author email?'
      read -e git_authoremail
    fi

    sed -e "s/AUTHORNAME/$git_authorname/g" -e "s/AUTHOREMAIL/$git_authoremail/g" -e "s/GIT_CREDENTIAL_HELPER/$git_credential/g" git/gitconfig.local.symlink.example > git/gitconfig.local.symlink

    success 'gitconfig'
  fi
}


link_file () {
  local src=$1 dst=$2

  local overwrite= backup= skip=
  local action=

  if [ -f "$dst" -o -d "$dst" -o -L "$dst" ]
  then

    if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]
    then

      local currentSrc="$(readlink $dst)"

      if [ "$currentSrc" == "$src" ]
      then

        skip=true;

      else

        user "File already exists: $dst ($(basename "$src")), what do you want to do?\n\
        [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
        read -n 1 action

        case "$action" in
          o )
            overwrite=true;;
          O )
            overwrite_all=true;;
          b )
            backup=true;;
          B )
            backup_all=true;;
          s )
            skip=true;;
          S )
            skip_all=true;;
          * )
            ;;
        esac

      fi

    fi

    overwrite=${overwrite:-$overwrite_all}
    backup=${backup:-$backup_all}
    skip=${skip:-$skip_all}

    if [ "$overwrite" == "true" ]
    then
      rm -rf "$dst"
      success "removed $dst"
    fi

    if [ "$backup" == "true" ]
    then
      mv "$dst" "${dst}.backup"
      success "moved $dst to ${dst}.backup"
    fi

    if [ "$skip" == "true" ]
    then
      success "skipped $src"
    fi
  fi

  if [ "$skip" != "true" ]  # "false" or empty
  then
    ln -s "$1" "$2"
    success "linked $1 to $2"
  fi
}

install_dotfiles () {
  info 'installing dotfiles'

  local overwrite_all=false backup_all=false skip_all=false

  # In non-interactive mode, resolve conflicts deterministically by backing up
  # the existing file rather than prompting.
  if [ "$NONINTERACTIVE" = "1" ]; then backup_all=true; fi

  for src in $(find -H "$DOTFILES_ROOT" -maxdepth 2 -name '*.symlink' ! -path '*.git*')
  do
    dst="$HOME/.$(basename "${src%.*}")"
    link_file "$src" "$dst"
  done

  # Link .finicky.js
  info 'linking Finicky configuration'
  link_file "$DOTFILES_ROOT/config/.finicky.js" "$HOME/.finicky.js"

  # Create .config directory if it doesn't exist
  if [ ! -d "$HOME/.config" ]; then
    mkdir -p "$HOME/.config"
    success "created ~/.config directory"
  fi

  # Link Ghostty config
  if [ -d "$DOTFILES_ROOT/config/ghostty" ]; then
    mkdir -p "$HOME/.config/ghostty"
    link_file "$DOTFILES_ROOT/config/ghostty/config" "$HOME/.config/ghostty/config"
    success "linked ghostty config"
  fi

  # Link Alacritty config
  if [ -d "$DOTFILES_ROOT/config/alacritty" ]; then
    mkdir -p "$HOME/.config/alacritty"
    link_file "$DOTFILES_ROOT/config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
    success "linked alacritty config"
  fi

  # Link Topgrade config
  if [ -f "$DOTFILES_ROOT/config/topgrade/topgrade.toml" ]; then
    link_file "$DOTFILES_ROOT/config/topgrade/topgrade.toml" "$HOME/.config/topgrade.toml"
    success "linked topgrade config"
  fi

  # Link Claude Code config
  if [ -d "$DOTFILES_ROOT/config/claude" ]; then
    mkdir -p "$HOME/.claude"
    link_file "$DOTFILES_ROOT/config/claude/settings.json" "$HOME/.claude/settings.json"
    # Link custom agents
    if [ -d "$DOTFILES_ROOT/config/claude/agents" ]; then
      mkdir -p "$HOME/.claude/agents"
      for agent in "$DOTFILES_ROOT/config/claude/agents"/*.md; do
        [ -f "$agent" ] && link_file "$agent" "$HOME/.claude/agents/$(basename "$agent")"
      done
    fi
    # Link custom skills into ~/.agents/skills (canonical) — ~/.claude and ~/.codex symlink from there
    if [ -d "$DOTFILES_ROOT/config/claude/skills" ]; then
      mkdir -p "$HOME/.agents/skills" "$HOME/.claude/skills" "$HOME/.codex/skills"
      for skill in "$DOTFILES_ROOT/config/claude/skills"/*/; do
        skill_name="$(basename "$skill")"
        link_file "$skill" "$HOME/.agents/skills/$skill_name"
        link_file "$HOME/.agents/skills/$skill_name" "$HOME/.claude/skills/$skill_name"
        link_file "$HOME/.agents/skills/$skill_name" "$HOME/.codex/skills/$skill_name"
      done
    fi
    success "linked claude code config"
  fi

  # Configure iTerm2 to use dotfiles preferences
  if [ -d "$DOTFILES_ROOT/config/iterm" ]; then
    info "configuring iTerm2 to use dotfiles preferences"
    defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$DOTFILES_ROOT/config/iterm"
    defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
    success "iTerm2 configured to load prefs from dotfiles"
  fi
}

install_oh_my_zsh() {
  info 'installing oh my zsh'
  FILE=~/.oh-my-zsh
  if [ -d "$FILE" ]; then
      echo "$FILE already exists."
  else
      echo "$FILE does not exist. Installing"
      git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
      # Plugins
      git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
      git clone --depth=1 https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
      git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
      git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
      git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
  fi
}

install_z() {
  info 'installing z'

  FILE=~/z
  if [ -d "$FILE" ]; then
      echo "$FILE already exists."
  else
      echo "$FILE does not exist. Installing"
      git clone --depth=1 https://github.com/rupa/z ~/z
  fi
}

install_cron_jobs() {
  info 'installing cron jobs'
  if sh "$DOTFILES_ROOT/cron/install.sh"; then
    success "cron jobs installed"
  else
    fail "error installing cron jobs"
  fi
}

ssh_keygen() {
  info 'generating ssh keys'

  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"

  file="$HOME/.ssh/id_ed25519.pub"
  if [ ! -f "$file" ]; then
    ssh-keygen -q -t ed25519 -N '' -f "$HOME/.ssh/id_ed25519" <<<y 2>&1 >/dev/null
    eval "$(ssh-agent -s)"
  fi

  if [ "$NONINTERACTIVE" = "1" ]; then
    success 'ssh key ready (non-interactive: not copied to clipboard)'
    return
  fi

  success 'copied ssh key to clipboard'

  pbcopy < "$file"
  cat "$file"
}

run_bootstrap() {
  # Fresh machines (and non-login shells, e.g. SSH'd test VMs) don't have
  # /opt/homebrew/bin on PATH yet; without this, every `brew` call below
  # silently fails with "command not found".
  if ! command -v brew >/dev/null 2>&1 && [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  setup_hostname
  setup_gitconfig
  install_dotfiles
  install_oh_my_zsh
  install_z
  ssh_keygen
  install_cron_jobs

  # macOS defaults
  "$DOTFILES_ROOT/macos/set-defaults.sh"

  # Brew bundle (non-fatal: some casks may fail to download)
  export HOMEBREW_CURL_RETRIES=5

  # Newer Homebrew refuses formulas from untrusted third-party taps, which
  # aborts `brew bundle` on fresh machines. Taps listed in the Brewfile are
  # our own declared intent, so trust them up front. Older brews have no
  # `trust` subcommand — skip there.
  if brew trust --help >/dev/null 2>&1; then
    info "trusting Brewfile taps"
    sed -nE 's/^tap "([^"]+)".*/\1/p' "$DOTFILES_ROOT/Brewfile" | while read -r t; do
      brew trust "$t" >/dev/null 2>&1 || info "could not trust tap: $t"
    done
  fi

  info "installing brew packages (pass 1)"
  if ! brew bundle --verbose --file="$DOTFILES_ROOT/Brewfile"; then
    info "some packages failed — retrying once"
    brew bundle --verbose --file="$DOTFILES_ROOT/Brewfile" || info "brew bundle finished with errors (run 'brew bundle' to retry later)"
  fi

  echo ''
  echo '  All installed!'
}

# Only run the install sequence when executed directly, not when sourced by
# unit tests (BOOTSTRAP_LIB_ONLY=1).
if [ "${BOOTSTRAP_LIB_ONLY:-0}" != "1" ]; then
  run_bootstrap
fi
