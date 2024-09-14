#!/bin/bash

source ~/.config/system_styles.sh

function display_notification() {
    # Build the notification message
    notification_message=""
    for mode in "${modes[@]}"; do
        # Friendly names and comparison keys
        # Capitalize the layout name for the notification
        friendly_name=$(echo $mode | tr "-" " " | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')

        # Pad the output
        friendly_name="  $friendly_name"
        length=${#friendly_name}

        # Calculate how much padding is needed
        padding_needed=20 #$((30 - length))
        echo $padding_needed,$mode

        # If padding is needed, append spaces to the end of the variable
        if [ $padding_needed -gt 0 ]; then
            printf -v friendly_name "%-${padding_needed}s" "$friendly_name"
        fi

        # Ensure the variable is exactly 40 characters by trimming or padding
        friendly_name=${friendly_name:0:40}

        # Check if this is the current layout
        if [[ "$mode" == *"$1"* ]]; then
            # Highlight the current layout
            text_color="$COLOR_DARK_TEXT"
            background_color="$COLOR_DARK_BACKGROUND_ALT"
        else
            text_color="$COLOR_DARK_TEXT_ALT" # Add some transparency to make it looks semi-disabled
            background_color="$COLOR_DARK_BACKGROUND"
        fi

        notification_message+="<span color='$text_color' background='$background_color' \
        line-height='3'>$friendly_name</span>\n"
    done

    # Send the notification
    notify-send " " "$notification_message" --category=toggle -h string:x-dunst-stack-tag:toggle
}

# Acceptable profiles: 'performance', 'balanced', 'power-save'

modes=(power-saver balanced performance)
if [ -z "$1" ]; then
    echo "Toggling power mode"

    current=$(powerprofilesctl get)
    for i in ${!modes[@]}; do
        if [ "${modes[$i]}" == "$current" ]; then
            next=$((i + 1))
            if [ $next -ge ${#modes[@]} ]; then
                next=0
            fi
            echo "setting to ${modes[$next]}" 
            # Don't recurse if next is empty
            if [ -z "${modes[$next]}" ]; then
                echo "No next mode"
            else
                ~/bin/power/set_power_profile.sh ${modes[$next]}
            fi
            break
        fi
    done
else
    powerprofilesctl set $1
    display_notification $1
fi

# if $2 exists, save it to /tmp/last_power_profile
if [ ! -z "$2" ]; then
    echo $2 > /tmp/last_power_profile
    chown jake:jake /tmp/last*
fi