#!/bin/bash

# Get the app_id of the focused window
focused_app=$(swaymsg -t get_tree | jq '.. | select(.focused? == true).app_id')

# Check if the focused application is Chromium
if [[ $focused_app == *"chromium"* ]]; then
  # Use wtype to simulate the Ctrl+W key press
  wtype -M Ctrl w -m Ctrl
else #if [[ "$focused_app" == *"foot"* ]]; then
  # Move to window to the left
  wtype -M win h -m win
fi
