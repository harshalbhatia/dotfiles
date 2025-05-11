# perf check
# zmodload zsh/zprof

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Ignore permission issues
export ZSH_DISABLE_COMPFIX=true
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Fallback theme (if Powerlevel10k is not present)
ZSH_THEME="robbyrussell"

plugins=(git kubectl history-substring-search zsh-autosuggestions zsh-syntax-highlighting mise)

source $ZSH/oh-my-zsh.sh
source ~/powerlevel10k/powerlevel10k.zsh-theme
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
