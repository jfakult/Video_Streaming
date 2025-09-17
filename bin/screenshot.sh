#!/bin/bash

SDIR="$HOME/Documents/Screenshots"
# yyyy-mm-dd-hh:mm:ss
date_str=$(date +%Y-%m-%d-%H:%M:%S)
mode="full"
if [ -n "$1" ]; then
	mode="$1"
fi

if [ "$mode" == "full" ]; then
	grim -o $(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name') $SDIR/$date_str.png
elif [ "$mode" == "select" ]; then
	grim -g "$(slurp)" $SDIR/$date_str.png
elif [ "$mode" == "window" ]; then
	grim -g "$(swaymsg -t get_tree | jq -r '.. | select(.type?) | select(.focused==true) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')" $SDIR/$date_str.png
else
	echo "Invalid mode: $mode"
	echo "Valid modes: full, select, window"
	exit 1
fi

# Make sure the screenshot was saved
if [ -f $SDIR/$date_str.png ]; then
	wl-copy < $SDIR/$date_str.png

	echo $SDIR/$date_str.png > /tmp/last_screenshot
	notify-send --category screenshot -h string:x-canonical-private-synchronous:sys-notify -i "$SDIR/$date_str.png" " "

	echo Screenshot saved to $SDIR/$date_str.png
fi