#!/usr/bin/env bash
#
# bootstrap installs things.

cd "$(dirname "$0")/.."
DOTFILES_ROOT=$(pwd -P)

set -e

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
  if ! [ -f git/gitconfig.local.symlink ]
  then
    info 'setup gitconfig'

    git_credential='cache'
    if [ "$(uname -s)" == "Darwin" ]
    then
      git_credential='osxkeychain'
    fi

    user ' - What is your github author name?'
    read -e git_authorname
    user ' - What is your github author email?'
    read -e git_authoremail

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

  for src in $(find -H "$DOTFILES_ROOT" -maxdepth 2 -name '*.symlink' ! -path '*.git*')
  do
    dst="$HOME/.$(basename "${src%.*}")"
    link_file "$src" "$dst"
  done

  # Link .finicky.js
  info 'linking Finicky configuration'
  link_file "$DOTFILES_ROOT/.finicky.js" "$HOME/.finicky.js"

  # Create .config directory if it doesn't exist
  if [ ! -d "$HOME/.config" ]; then
    mkdir -p "$HOME/.config"
    success "created ~/.config directory"
  fi

  # Link Ghostty config
  if [ -d "$DOTFILES_ROOT/ghostty" ]; then
    mkdir -p "$HOME/.config/ghostty"
    link_file "$DOTFILES_ROOT/ghostty/config" "$HOME/.config/ghostty/config"
    success "linked ghostty config"
  fi

  # Link Alacritty config
  if [ -d "$DOTFILES_ROOT/alacritty" ]; then
    mkdir -p "$HOME/.config/alacritty"
    link_file "$DOTFILES_ROOT/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
    success "linked alacritty config"
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

install_powerline_fonts() {
  info 'installing powerline fonts'

  git clone https://github.com/powerline/fonts.git ~/.fonts --depth=1
  ~/.fonts/install.sh
  rm -rf ~/.fonts
}

install_nerd_fonts() {
  info 'installing nerd fonts'

  git clone https://github.com/ryanoasis/nerd-fonts ~/.nerd-fonts --depth=1
  ~/.nerd-fonts/install.sh
  rm -rf ~/.nerd-fonts
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

install_brew_deps() {
  user "Do you want to install Brewfile?\n\
        [Y]es, [n]o?"
        read -n 1 action

        case "$action" in
          n )
            brew=false;;
          * )
            brew=true;;
        esac

  if [ "$brew" == "true" ]
    then
      info 'installing brew deps'
      brew bundle
      success "Installed Brewfile"
    fi
}

ssh_keygen() {
  info 'generating ssh keys'

  file="$HOME/.ssh/id_rsa.pub"
  if [ ! -f "$file" ]; then
    ssh-keygen -q -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa <<<y 2>&1 >/dev/null
    eval "$(ssh-agent -s)"
  fi


  success 'copyied ssh key to clipboard'

  pbcopy < ~/.ssh/id_rsa.pub
  cat "$file"
}

# Call setup_hostname early in the script
setup_hostname
setup_gitconfig
install_dotfiles
install_oh_my_zsh
install_powerline_fonts
install_nerd_fonts
install_z
install_brew_deps
ssh_keygen

# If we're on a Mac, let's install and setup homebrew.
if [ "$(uname -s)" == "Darwin" ]
then
  info "installing dependencies"
  if bin/dot 2>&1 | tee /tmp/dotfiles-dot | while read -r data; do info "$data"; done
  then
    success "dependencies installed"
  else
    fail "error installing dependencies"
  fi
fi

echo ''
echo '  All installed!'
