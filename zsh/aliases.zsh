# Enable aliases to be sudo’ed
alias sudo="sudo "

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias -- -="cd -"

# Shortcuts
# alias ls="ls --color"
alias -- +x="chmod +x"
alias o="open"
alias oo="open ."
alias e="$EDITOR"
alias cc="code ."

# Bat: https://github.com/sharkdp/bat
command -v bat >/dev/null 2>&1 && alias cat="bat --style=numbers,changes"

# Trash
alias rm="trash"

# Download file and save it with filename of remote file
alias get="curl -O -L"

# Run npm script without annoying noise
alias nr="npm run --silent"

# Jest watch
alias j="npx jest --watch"

# Custom
alias be="bundle exec"
alias pd="proctor describe"
alias pe="proctor execute"
alias kx="kubectx"
alias tf="terraform"

# Make a directory and cd to it
function take() {
  mkdir -p $@ && cd ${@:$#}
}

# cd into whatever is the forefront Finder window
function cdf() {
  cd "`osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)'`"
}

# Cd to Git repository root folder
function gr() {
  cd "./$(git rev-parse --show-cdup 2>/dev/null)" 2>/dev/null
}
 
# git clone and cd to a repo directory
function clone() {
  git clone $@
  if [ "$2" ]; then
    cd "$2"
  else
    cd $(basename "$1" .git)
  fi
  if [[ -r "./yarn.lock" ]]; then
    yarn
  elif [[ -r "./package-lock.json" ]]; then
    npm install
  fi
}

# trace route mapper shortcut
function traceroute-mapper {
  open "https://stefansundin.github.io/traceroute-mapper/?trace=$(traceroute -q1 $*)"
}

# vim to nvim

if [ -x "$(command -v nvim)" ]; then
  alias vim="nvim"
fi
