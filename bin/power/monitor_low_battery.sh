#!/bin/bash

# Define the path to the battery status and capacity
battery_status_path="/sys/class/power_supply/BAT0/status"
battery_capacity_path="/sys/class/power_supply/BAT0/capacity"

# Read the current status and capacity
battery_status=$(cat "$battery_status_path")
battery_capacity=$(cat "$battery_capacity_path")

# Define the battery level threshold
threshold=10

echo $battery_status $battery_capacity

# Check if the battery is discharging and the level is below the threshold
if [[ "$battery_status" == "Discharging" && "$battery_capacity" -lt "$threshold" ]]; then
    # Insert the actions you want to take here
    echo "Battery is low ($battery_capacity%) and discharging. Taking action."
    /root/bin/update_charging_status.sh "Danger"

fi
