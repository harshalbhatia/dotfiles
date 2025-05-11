# Manual Tasks
- set caps lock to esc
- mackup backup and restore

# TODO
 - [x] move bin
 - [x] automate linking
 - [x] link bin
 - [x] install oh-my-zsh
 - [x] ssh keygen
 - [x] install powerline fonts
 - [x] brewfile setup
 - [ ] sync iterm settings
 - [ ] global ignore .history
 - [ ] n vs nvm for perf: https://blog.mattclemente.com/2020/06/26/oh-my-zsh-slow-to-load.html
 - [x] prompt for hostname during setup
 - [ ] docs
 - [ ] function for avoid repetetive calling of fonts
 - [ ] execute_after_prompt()
 - [ ] execute_if_not_dir(dir, cmd)
 - [ ] brew is not installed before brewfile installation

# Dotfiles

Personal configuration files for my macOS development environment.

## Overview

This repository contains my personal dotfiles and system configuration for macOS. It includes:

- Shell configuration (zsh with Oh My Zsh)
- Git configuration
- Package management via Homebrew
- Terminal configuration (iTerm2, fonts)
- VPN connection scripts
- And more

## Quick Start

Just run `./script/bootstrap.sh` 🚀

## Features

- Automated setup of development environment
- Package installation via Brewfile
- Dotfile symlink management
- Shell customization with Oh My Zsh
- SSH key generation
- Font installation (Powerline, Nerd Fonts)
- VPN connection scripts

## What Gets Installed

### Command Line Tools
- git, bat, fzf, ripgrep, and more via Homebrew

### Applications
- iTerm2, VSCode, browsers, and more via Homebrew Cask

### Shell Environment
- Oh My Zsh with custom plugins and themes
- Customized terminal prompt with Powerlevel10k
- Useful aliases and functions

## Customization

You can customize these dotfiles by:
1. Modifying the Brewfile to add/remove packages
2. Editing the shell configuration in zsh directory
3. Adding your own dotfiles to the repository

## Maintenance

### Update Brewfile
To update the Brewfile with your current brew setup:
```
bin/dot -b
```

###  Update dotfiles
To update your dotfiles repository with the latest changes:
```
git pull
./script/bootstrap.sh
```
