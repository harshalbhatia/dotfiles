# Prepend $PATH without duplicates
function _prepend_path() {
	if [[ ":${PATH}:" != *":$1:"* ]]; then
		PATH="$1${PATH:+:${PATH}}"
	fi
}

# Construct $PATH
# 1. Default paths
# 2. ./node_modules/.bin - shorcut to run locally installed Node bins
# 3. Custom bin folder for n, Ruby, CoreUtils, dotfiles, etc.

# To use default PATH instead of overwriting, comment below line.
# PATH='/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin' # Initial base PATH, often handled by system

# Homebrew specific paths
_prepend_path "/opt/homebrew/bin" # General homebrew bin
_prepend_path "/opt/homebrew/sbin" # General homebrew sbin
_prepend_path "/opt/homebrew/opt/openssl@3/bin"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig"

# User-specific paths

_prepend_path "$HOME/dotfiles/exec"
_prepend_path "$HOME/.cargo/bin" # For Rust/Cargo, if used

# Other common paths (check if still needed/installed)
# _prepend_path "/usr/local/bin" # Already often in default PATH or covered by Homebrew
# _prepend_path "/usr/local/sbin" # Already often in default PATH or covered by Homebrew


export PATH

