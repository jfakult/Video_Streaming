#!/bin/bash

# Status can either be 'Charging' or 'Discharging'

last_profile=$(cat /tmp/last_power_profile)
if [[ "$last_profile" != "power-saver" && "$last_profile" != "balanced" ]]
then
    last_profile="balanced"
    echo $last_profile > /tmp/last_power_profile && chown jake:jake /tmp/last*
fi

last_power=$(cat /tmp/last_brightness)
if [ -z "$last_brightness" ]; then
	last_brightness="50"
	echo $last_brightness > /tmp/last_brightness && chown jake:jake /tmp/last*
fi

if [ "$1" = "Charging" ]; then
    echo "Device is currently charging."
    brightnessctl set $last_brightness
    current_profile=$(powerprofilesctl get)
    if [ "$current_profile" = "performance" ]; then
        echo "Current power profile is performance."
        exit 0
    fi
    ~/bin/power/set_power_profile.sh performance $current_profile
elif [ "$1" = "Discharging" ]; then
    echo "Device is currently discharging."
    ~/bin/power/set_power_profile.sh $last_profile
elif [ "$1" = "Danger" ]; then
    echo "Battery is dangerously low"
    ~/bin/power/set_power_profile.sh "power-saver"
else
    echo "Unknown status."
fi

if [ "$(powerprofilesctl get)" = "power-saver" ]; then
	brightnessctl set 0
fi
