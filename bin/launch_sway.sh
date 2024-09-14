#/bin

# To load in the env vars (since this is spawned by exec)
source ~/.config/system_styles.sh

# Basically we need to manually modify or overwrite some config files on the fly
# For any graphical service that doesn't allow us to customize it with our own env vars
# Manually dump our WM theme into sway config
echo "set \$tab_color $COLOR_DARK_BACKGROUND" > ~/.config/sway/env
echo "set \$font_color $COLOR_DARK_TEXT" >> ~/.config/sway/env
echo "font $FONT $FONT_SIZE" >> ~/.config/sway/env

# Manually dump our WM theme into yambar config
# Have to use sed to modify in place since the yambar guy never closed https://codeberg.org/dnkl/yambar/issues/96
sed -i'' "s/background_color: \&background_color .*/background_color: \&background_color ${COLOR_DARK_BACKGROUND:1}/g" "$HOME/.config/yambar/config.yml"
sed -i'' "s/text_color: \&text_color .*/text_color: \&text_color ${COLOR_DARK_TEXT:1}/g" "$HOME/.config/yambar/config.yml"
sed -i'' "s/text_color_dim: \&text_color_dim .*/text_color_dim: \&text_color_dim ${COLOR_DARK_TEXT_ALT:1}/g" "$HOME/.config/yambar/config.yml"
sed -i'' "s/text_color_error: \&text_color_error .*/text_color_error: \&text_color_error ${COLOR_DARK_TEXT_ERROR:1}/g" "$HOME/.config/yambar/config.yml"


#Galendae (calendar) style overwrite
sed -i'' "s/background_color=.*/background_color=${COLOR_DARK_BACKGROUND:0:7}/g" "$HOME/.config/galendae/galendae.conf"
sed -i'' "s/foreground_color=.*/foreground_color=${COLOR_DARK_TEXT:0:7}/g" "$HOME/.config/galendae/galendae.conf"
sed -i'' "s/fringe_date_color=.*/fringe_date_color=${COLOR_DARK_TEXT_ALT:0:7}/g" "$HOME/.config/galendae/galendae.conf"
sed -i'' "s/highlight_color=.*/highlight_color=${COLOR_DARK_HIGHLIGHT:0:7}/g" "$HOME/.config/galendae/galendae.conf"


sway_sock=$(sway --get-socketpath)

if [ -z "$sway_sock" ]; then
    #WLR_DRM_DEVICES=/dev/dri/card0:/dev/dri/card1
    sway &
else
    pkill -f ^swayidle
    pkill -f ^yambar
    pkill -f sway-audio-idle-inhibit
    swaymsg -s $sway_sock reload
fi

touch /tmp/sway_launched
