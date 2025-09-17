#!/bin/bash

export XDG_CURRENT_DESKTOP=sway
source ~/.config/system_styles.sh

# FROM: https://github.com/RedBorg/dotfiles-sway-island/blob/master/.config/swaylock/lock.sh

cd $HOME/.config/swaylock

grim -t jpeg screen.jpg

image="icons/0.png"

# this command is crazy fast, but it gaussian blurs and overlays a logo 
# with a speed that is around 3-4 times faster than the time it takes for
# imagemagick to simply composite that logo (no blurring)
# (test is not done in a controlled environment, but you get the idea)
# I FUCKING LOVE FFMPEG!!
#ffmpeg -i screen.jpg -vf \
#  "[in] gblur=sigma=5 [blurred]; movie=$image [logo]; 
#  [blurred][logo] overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2 [out]" \
#  logo-ed_screen.png

#python edit_background_image.py
#lock_icon="icons/lock_infill.png"
lock_icon="icons/lock_icon.png"
unlock_icon="icons/unlock_icon.png"
rm logo-ed_screen.png logo-ed_screen_unlocked.png
rm icons/resized_lock_icon.png icons/resized_unlock_icon.png

if [ "$lock_icon" = "icons/lock_icon.png" ]
then
  image_diameter=400
  ffmpeg -i $lock_icon -vf scale=$image_diameter:$image_diameter icons/resized_lock_icon.png
  ffmpeg -i screen.jpg -i icons/resized_lock_icon.png -filter_complex "[0:v]curves=all='0/0 0.5/0.25 1/0.25'[adjusted];[adjusted]gblur=sigma=10[blurred];[blurred][1:v]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2[out]" -map "[out]" logo-ed_screen.png &
  
  ffmpeg -i $unlock_icon -vf scale=$image_diameter:$image_diameter icons/resized_unlock_icon.png
  #ffmpeg -i screen.jpg -i icons/resized_unlock_icon.png -filter_complex "[0:v]curves=all='0/0 0.5/0.2 1/0.25'[adjusted];[adjusted]gblur=sigma=5[blurred];[blurred][1:v]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2[out]" -map "[out]" logo-ed_screen_unlocked.png &
  ffmpeg -i screen.jpg -i icons/resized_unlock_icon.png -filter_complex "[0:v]curves=all='0/0 0.5/0.25 1/0.25'[adjusted];[adjusted]gblur=sigma=10[blurred];[blurred][1:v]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2[out]" -map "[out]" logo-ed_screen_unlocked.png &
else
  image_radius=255
  image_diameter=$((2*image_radius))
  ffmpeg -i $lock_icon -vf scale=$image_diameter:$image_diameter icons/resized_lock_icon.png
  #Define the offsets, swaylock doesn't seem to perfectly center things
  #Get the dimensions of the screenshot
  screenshot_width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 screen.jpg)
  screenshot_height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 screen.jpg)
  center_x=$((screenshot_width/2))
  center_y=$((screenshot_height/2))
  offset_x=3
  offset_y=2

  # Overlay the logo onto the screenshot
  ffmpeg -i screen.jpg -i icons/resized_lock_icon.png -filter_complex "[0:v]curves=all='0/0 0.5/0.2 1/0.25'[adjusted];[adjusted]gblur=sigma=5[blurred];[blurred][1:v]overlay=$center_x-$image_radius+$offset_x:$center_y-$image_radius+$offset_y[out]" -map "[out]" logo-ed_screen.png
fi

ring_color=FF8C44FF

# Open the unlocked logo soon after swaylock launches
$(sleep 0.5 && imv -f logo-ed_screen_unlocked.png) &

# Sleep until logo-ed_screen.png is created
# Becuse we run our ffmpeg commands in the background
while [ ! -f logo-ed_screen.png ]; do sleep 0.1; done

swaylock \
  --image logo-ed_screen.png \
  --indicator-radius 160 \
  --indicator-thickness 20 \
  --inside-color 00000000 \
  --inside-clear-color 00000000 \
  --inside-ver-color 00000000 \
  --inside-wrong-color 00000000 \
  --key-hl-color $COLOR_DARK_BACKGROUND_ALT \
  --bs-hl-color $COLOR_DARK_BACKGROUND_ALT \
  --ring-color $COLOR_DARK_BACKGROUND \
  --ring-clear-color $COLOR_DARK_BACKGROUND \
  --ring-wrong-color $COLOR_DARK_WARNING \
  --ring-ver-color $COLOR_DARK_BACKGROUND_ALT \
  --line-color 00000000 \
  --font-size 0 \
  --text-ver-color $COLOR_DARK_TEXT \
  --text-wrong-color $COLOR_DARK_WARNING \
  --text-clear "" \
  --separator-color 00000000 \
  --hide-keyboard-layout \
  --ignore-empty-password \
  --show-failed-attempts && sleep 0.5 && pkill -f "logo-ed_screen_unlocked" || pkill -f "logo-ed_screen_unlocked"