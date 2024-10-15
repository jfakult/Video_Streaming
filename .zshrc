# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=8192
SAVEHIST=8192
unsetopt beep
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/jake/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

export ZSH_PLUGINS="/usr/share/zsh/plugins"

alias automount="systemctl start udiskie --user"
alias s="$HOME/bin/launch_sway.sh"
alias shut="shutdown now"
alias nordstart="sudo systemctl start nordvpnd && nordvpn connect"
alias wifi="wifi.sh"
alias record="pw-record -P '{ stream.capture.sink=true }'"

function nordstop() {
	pkill -f nordvpn
	pkill -f nordlynx 2>/dev/null
	nordvpn disconnect
	sudo systemctl stop nordvpnd
}

export PATH=~/bin:$PATH
export XDG_CURRENT_DESKTOP=sway

source ~/.config/system_styles.sh

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

setopt PROMPT_SUBST
# Custom prompt
prompt_dir() {
	  echo "$(dirname "${PWD}" | sed -e "s;\(/.\)[^/]*;\1;g" -e "s;^/;;" -e "s;/$;;" -e "s;/;/;g")/$(basename "${PWD}")"
}
export PROMPT='[%n@%m $(prompt_dir)]$ '


export NNN_FIFO=/tmp/nnn.fifo
export NNN_PLUG="i:preview-tui"
export NNN_TERMINAL=kitty
function open() {
	# Wrap in parentheses to avoid seeing background task output
	(xdg-open "$@" >/dev/null &)
}

alias gs="git status"
function gp() {
	git pull && git add . && git commit -m "$1" && git push
}

function get_wins() {
	search="app_id"
	if [ -n "$1" ]; then
		search=$1
	fi
	swaymsg -t get_tree | jq ".." | grep -P "^  \"$search"
}

#### Activate zsh plugins ####
ZSH_PLUGINS_LIST=("zsh-autosuggestions" "zsh-syntax-highlighting")

source $HOME/.config/zsh-syntax-highlighting/zsh-syntax-highlighting.sh

for plugin in "${ZSH_PLUGINS_LIST[@]}"; do
	source $ZSH_PLUGINS/$plugin/$plugin.plugin.zsh
done

update_system_on_boot.sh
