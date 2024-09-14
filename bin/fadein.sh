#!/bin/bash

# Sloppy script to fade in and out an application window

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <app_id> <display_duration> <fade_in_duration> <fade_out_duration>"
    exit 1
fi

# App ID of the target application
APP_ID="$1"

# Duration of the fade in and out in seconds
FADE_IN_DURATION="$3"
FADE_OUT_DURATION="$4"
# How long to display the app at full opacity
DISPLAY_DURATION="$2"

# Initial and final opacity
INITIAL_OPACITY=0
FINAL_OPACITY=1
CURRENT_OPACITY=$INITIAL_OPACITY


# Calculate the increment step for opacity change (assuming 10 steps for smoothness)
INCREMENT=$(bc <<< "($FINAL_OPACITY - $INITIAL_OPACITY)/10")
# Calculate sleep duration to match the fade-in and fade-out duration
SLEEP_DURATION_IN=$(bc <<< "$FADE_IN_DURATION/10")
SLEEP_DURATION_OUT=$(bc <<< "$FADE_OUT_DURATION/10")

# Function to change opacity
change_opacity() {
    local opacity=$1
    swaymsg "[app_id=\"$APP_ID\"] opacity $opacity"
}

# Fade in
for i in $(seq 1 10); do
    current_opacity=$(bc <<< "$INITIAL_OPACITY + $INCREMENT*$i")
    change_opacity $current_opacity
    sleep $SLEEP_DURATION_IN
done

# Display at target opacity for a specified duration
sleep $DISPLAY_DURATION

# Fade out
for i in $(seq 1 10); do
    current_opacity=$(bc <<< "$TARGET_OPACITY - $INCREMENT*$i")
    change_opacity $current_opacity
    sleep $SLEEP_DURATION_OUT
done