#!/bin/bash

iDIR="$HOME/.config/mako/icons"

# Get brightness
get_brightness() {
	echo $(brightnessctl -m | cut -d, -f4 | grep -Po "\d+")
}

# Get icons
get_icon() {
	current=$(get_brightness)
	if   [ "$current" -le "20" ]; then
		icon="$iDIR/brightness-20.png"
	elif [ "$current" -le "40" ]; then
		icon="$iDIR/brightness-40.png"
	elif [ "$current" -le "60" ]; then
		icon="$iDIR/brightness-60.png"
	elif [ "$current" -le "80" ]; then
		icon="$iDIR/brightness-80.png"
	else
		icon="$iDIR/brightness-100.png"
	fi

    echo "$icon"
}

# Notify
notify_user() {
	notify-send -u low -c setting_overlay -h string:x-canonical-private-synchronous:sys-notify -h int:value:$(get_brightness) -i "$(get_icon)" " " #"$(get_brightness)"
}

brightnessctl set -- "$1" && notify_user && brightnessctl get > /tmp/last_brightness && chown jake:jake /tmp/last_*
