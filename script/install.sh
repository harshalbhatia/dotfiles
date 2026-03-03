#!/usr/bin/env bash
set -e

DOTFILES_DIR="$HOME/dotfiles"

# Xcode CLT
if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install
  until xcode-select -p &>/dev/null; do sleep 5; done
fi

# Homebrew (Apple Silicon)
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Clone
if [ ! -d "$DOTFILES_DIR" ]; then
  git clone https://github.com/harshalbhatia/dotfiles "$DOTFILES_DIR"
fi

# Bootstrap
bash "$DOTFILES_DIR/script/bootstrap.sh"
