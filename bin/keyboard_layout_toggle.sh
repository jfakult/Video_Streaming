#!/bin/bash

# Called from sway keyboard_shortcuts.conf: bindsym $mod+$alt+Space

# To get the current active layout:
# swaymsg -t get_inputs | jq -r '.[] | select(.type=="keyboard") | .xkb_active_layout_name' | head -1
# English (Dvorak), English (US)

# Old xkb config:
#input "type:keyboard" {
#	xkb_layout us,us
#	xkb_variant dvorak,
#	xkb_options grp:shifts_toggle,caps:backspace
#}

#!/bin/bash

# Define your layouts and variants here in the format "layout:variant"
# If a layout does not have a variant, just leave it as "''"
# To view options:
# localectl list-x11-keymap-layouts - gives you layouts (~100 on modern systems)
# localectl list-x11-keymap-variants [layout] gives you variants for this layout (or all variants if no layout specified, ~300 on modern systems)
# localectl list-x11-keymap-options | grep grp:

source ~/.config/system_styles.sh

layouts=("us:''" "us:dvorak")

# Retrieve the current layout and variant combination
# Convert to lower case
current_layout=$(swaymsg -t get_inputs | jq -r '.[] | select(.type=="keyboard") | .xkb_active_layout_name' | head -n 1)

# Convert to lower case and replace (US) with ('')
current_layout=$(echo "$current_layout" | tr '[:upper:]' '[:lower:]' | sed "s/(us)/('')/")

echo Current layout is $current_layout

# Determine the index of the current layout
current_index=-1
for i in "${!layouts[@]}"; do
   layout_variant="${layouts[$i]}"
   layout=${layout_variant%%:*}
   variant=${layout_variant#*:}

   # Construct the layout name as it appears in swaymsg output
   layout_name="$layout"
   [[ -n "$variant" ]] && layout_name+=" ($variant)"

   if [[ "$current_layout" == *"$variant"* ]]; then
       current_index=$i
       break
   fi
done

# Determine the next layout's index
# If current layout is not found or is the last one, cycle back to the first layout
next_index=$(( (current_index + 1) % ${#layouts[@]} ))

# Extract the next layout and variant
next_layout_variant="${layouts[$next_index]}"
next_layout=${next_layout_variant%%:*}
next_variant=${next_layout_variant#*:}

# Apply the layout change
swaymsg input type:keyboard xkb_layout "$next_layout"
swaymsg input type:keyboard xkb_variant "$next_variant"

# Build the notification message
notification_message=""
for layout_variant in "${layouts[@]}"; do
    layout=${layout_variant%%:*}
    variant=${layout_variant#*:}

    # Friendly names and comparison keys
    # Capitalize the layout name for the notification
    friendly_layout_name=$(echo $layout | tr '[:lower:]' '[:upper:]')
    # First letter capitalized only and replace '' with Qwerty
    friendly_variant_name=$(echo $variant | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}' | sed "s/''/Qwerty/")

    # Pad the output
    friendly_name="  $friendly_layout_name $friendly_variant_name"
    length=${#friendly_name}

    # Calculate how much padding is needed
    padding_needed=20 #$((40 - length))

    # If padding is needed, append spaces to the end of the variable
    if [ $padding_needed -gt 0 ]; then
        printf -v friendly_name "%-${padding_needed}s" "$friendly_name"
    fi

    # Ensure the variable is exactly 40 characters by trimming or padding
    friendly_name=${friendly_name:0:40}

    # Check if this is the current layout
    if [[ "$variant" == *"$next_variant"* ]]; then
        echo "New layout is $friendly_layout_name $friendly_variant_name"
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

#echo "$notification_message"

# Send the notification
notify-send " " "$notification_message" --category=toggle -h string:x-dunst-stack-tag:toggle
