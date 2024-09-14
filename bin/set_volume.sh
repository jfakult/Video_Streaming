#!/bin/bash

# Much code modified from https://github.com/JaKooLit/Ja_HyprLanD-dots.git

iDIR="$HOME/.config/mako/icons"

# Get Volume
get_volume() {
	# alsa_output.pci-0000_c1_00.6.analog-stereo1
	volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2*100}')
	mute=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o MUTED)
	if [[ "$mute" == "MUTED" ]]; then
		echo "0"
	else
		echo "$volume"
	fi
}

# Get icons
get_icon() {
	current=$(get_volume)
	if [[ "$current" -eq "0" ]]; then
		echo "$iDIR/volume-mute.png"
	elif [[ ("$current" -ge "0") && ("$current" -le "30") ]]; then
		echo "$iDIR/volume-low.png"
	elif [[ ("$current" -ge "30") && ("$current" -le "60") ]]; then
		echo "$iDIR/volume-mid.png"
	elif [[ ("$current" -ge "60") && ("$current" -le "150") ]]; then
		echo "$iDIR/volume-high.png"
	fi
}

# Notify
notify_user() {
	notify-send -u low -c setting_overlay -h string:x-canonical-private-synchronous:sys-notify -h int:value:$(get_volume) -i "$(get_icon)" "$(get_volume)"
}

# Get icons
get_mic_icon() {
	current=$(pamixer --default-source --get-volume)
	if [[ "$current" -eq "0" ]]; then
		echo "$iDIR/microphone.png"
	elif [[ ("$current" -ge "0") && ("$current" -le "30") ]]; then
		echo "$iDIR/microphone.png"
	elif [[ ("$current" -ge "30") && ("$current" -le "60") ]]; then
		echo "$iDIR/microphone.png"
	elif [[ ("$current" -ge "60") && ("$current" -le "100") ]]; then
		echo "$iDIR/microphone.png"
	fi
}
# Notify
notify_mic_user() {
	notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$(get_mic_icon)" "Mic-Level : $(pamixer --default-source --get-volume) %"
}

if [ "$2" == "mic" ]; then
	if [ "$1" == "mute" ]; then
		wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && notify_mic_user
	else
		wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0
		wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "$1" && notify_mic_user
	fi
elif [ "$1" == "mute" ]; then
	wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && notify_user
else
	wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
	wpctl set-volume @DEFAULT_AUDIO_SINK@ -- "$1"
	if [ "$(get_volume)" -gt "150" ]; then
		wpctl set-volume @DEFAULT_AUDIO_SINK@ 150%
	fi
	notify_user
fi
