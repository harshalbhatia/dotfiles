# Prepend $PATH without duplicates
function _prepend_path() {
	if ! $( echo "$PATH" | tr ":" "\n" | grep -qx "$1" ) ; then
		PATH="$1:$PATH"
	fi
}

# Construct $PATH
# 1. Default paths
# 2. ./node_modules/.bin - shorcut to run locally installed Node bins
# 3. Custom bin folder for n, Ruby, CoreUtils, dotfiles, etc.
PATH='/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'
[ -d /usr/local/bin ] && _prepend_path "/usr/local/bin"
[ -d /usr/local/opt/curl/bin ] && _prepend_path "/usr/local/opt/curl/bin"
[ -d /usr/local/sbin ] && _prepend_path "/usr/local/sbin"
[ -d /usr/local/opt/ruby/bin ] && _prepend_path "/usr/local/opt/ruby/bin"
[ -d /usr/local/opt/coreutils/libexec/gnubin ] && _prepend_path "/usr/local/opt/coreutils/libexec/gnubin"
[ -d $GOPATH/bin:$PATH ] && _prepend_path "$GOPATH/bin:$PATH"
[ -d ~/dotfiles/bin ] && _prepend_path "$HOME/dotfiles/bin"
[ -d ${KREW_ROOT:-$HOME/.krew}/bin:$PATH ] && _prepend_path "${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH
