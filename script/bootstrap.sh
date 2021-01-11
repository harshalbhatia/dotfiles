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

setup_gitconfig () {
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

  for src in $(find -H "$DOTFILES_ROOT" -maxdepth 2 -name '*.symlink' -not -path '*.git*')
  do
    dst="$HOME/.$(basename "${src%.*}")"
    link_file "$src" "$dst"
  done
}

install_oh_my_zsh() {
  info 'installing oh my zsh'
  FILE=~/.oh-my-zsh
  if [ -d "$FILE" ]; then
      echo "$FILE already exists."
  else 
      echo "$FILE does not exist. Installing"
      git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
      # Plugins
      git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
      git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
      git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
      git clone https://github.com/lukechilds/zsh-nvm ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-nvm
  fi
}

install_powerline_fonts() {
  info 'installing powerline fonts'

  git clone https://github.com/powerline/fonts.git ~/.fonts --depth=1
  ~/.fonts/install.sh
  rm -rf ~/.fonts
}

install_nvm() {
  info 'installing nvm'

  FILE=$HOME/.nvm
  if [ -d "$FILE" ]; then
      echo "$FILE already exists."
  else 
      echo "$FILE does not exist. Installing"
      export NVM_DIR="$HOME/.nvm" && (
      git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
      cd "$NVM_DIR"
      git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
    ) && \. "$NVM_DIR/nvm.sh"
  fi
}

install_z() {
  info 'installing z'

  FILE=~/z
  if [ -d "$FILE" ]; then
      echo "$FILE already exists."
  else 
      echo "$FILE does not exist. Installing"
      git clone https://github.com/rupa/z ~/z
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

setup_gitconfig
install_dotfiles
install_oh_my_zsh
install_powerline_fonts
install_nvm
install_z
install_brew_deps
ssh_keygen

# If we're on a Mac, let's install and setup homebrew.
if [ "$(uname -s)" == "Darwin" ]
then
  info "installing dependencies"
  if source bin/dot | while read -r data; do info "$data"; done
  then
    success "dependencies installed"
  else
    fail "error installing dependencies"
  fi
fi

echo ''
echo '  All installed!'