#################
##     NOTE    ##
## Use .zshrc! ##
#################

#
# ~/.bashrc
#

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
export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH


source ~/.config/system_styles.sh

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias apps='wofi --gtk-dark --prompt "Program" --show drun'

export PS1='[\u@\h $(echo $(dirname \w)|sed -e "s;\(/.\)[^/]*;\1;g")/$(basename \w)]\$ '
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

update_system_on_boot.sh
