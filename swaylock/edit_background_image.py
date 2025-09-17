import subprocess
import re

def run_ffmpeg_cmd(cmd):
    """Execute an FFmpeg command with subprocess and return the stderr."""
    process = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, shell=True)
    return process.stderr

def adjust_brightness(input_image, logo_image, output_image):
    """Apply the calculated brightness adjustment to the image."""
    curves_filter = "curves=all='0/0 0.5/0.1 1/0.15'"
    filter_complex = f"[0:v]{curves_filter},eq=brightness={brightness_adjustment}[adjusted];[adjusted]gblur=sigma=5[blurred];[blurred][1:v]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2[out]"
    cmd = f'ffmpeg -i {input_image} -i {logo_image} -filter_complex "{filter_complex}" -map "[out]" {output_image}'
    subprocess.run(cmd, shell=True)


# Main
input_image = 'screen.jpg'
logo_image = 'icons/logo.png'
output_image = 'logo-ed_screen.png'

# Apply the brightness adjustment
adjust_brightness(input_image, logo_image, output_image)

#print("Brightness adjustment applied based on analysis.")

