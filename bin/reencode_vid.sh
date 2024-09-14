#!/bin/bash

# Encodes one or a bunch of video files using h264_nvenc
# If the file is already encoded at a rate of less than 1.5 GB/hour, it will skip it
# Since we are using quick and dirty encoding

# It will do some simple checks to make sure the encoding pass succeeded and
# If so, it will delete the old and replace the new

ENCODING_RATIO_THRESHOLD=1.5

if [ $# -eq 0 ]; then
    echo "Usage: $0 <file>"
    exit 1
else
    rm -f output_temp.mp4
        
    for file in "$@"; do
        echo ""
        echo "--------------------------------------------------------------------------"
        stats_before=$(vid_stats.sh "$file")
        LENGTH_BEFORE=$(echo "$stats_before" | grep "GB/hour" | awk '{print $2}')
        RATIO_BEFORE=$(echo "$stats_before" | grep "GB/hour" | awk '{print $NF}')

        # if file is less than 0.01 GB/hour RATIO_BEFORE will be empty. Skip
        if [ -z "$RATIO_BEFORE" ]; then
            echo "File too small: $file... Skipping"
            continue
        fi

        if [ -z "$RATIO_BEFORE" ] || [ -z "$LENGTH_BEFORE" ]; then
            echo "Error getting stats for $file... Skipping"
            continue
        fi

        # If the ratio is less than $ENCODING_RATIO_THRESHOLD GB/Hour, skip it, we won't encode it better
        if [ $(echo "$RATIO_BEFORE < $ENCODING_RATIO_THRESHOLD" | bc) -eq 1 ]; then
            echo "Skipping $file, encoding is already good enough"
            continue
        fi

        # check if ratio is not empty
        if [ -z "$RATIO_BEFORE" ]; then
            echo "Error getting stats for $file... Skipping"
            continue
        fi

        echo "Reencoding $file"
        echo "$stats_before"
        echo

        # Meat and potatoes
        fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$file" | bc -l)
        if [ $(echo "$fps < 31" | bc) -eq 1 ]; then
            time ffmpeg -v quiet -stats -y -vsync 0 -threads 0 -hwaccel cuda -hwaccel_output_format cuda -i "$file" -c:v h264_nvenc -crf 18 -preset p3 output_temp.mp4 
        else
            echo "fps is $fps, lowering to 30"
            time ffmpeg -v quiet -stats -y -vsync 0 -threads 0 -hwaccel cuda -hwaccel_output_format cuda -i "$file" -c:v h264_nvenc -crf 18 -filter:v fps=30 -preset p3 output_temp.mp4
        fi
        
        if [ $? -ne 0 ]; then
            echo "Error reencoding $file"
            exit 1
        fi

        echo

        echo "Stat Comparison"
        stats_before=$(vid_stats.sh "$file")
        echo "$stats_before"
        echo "vs."
        stats_after=$(vid_stats.sh output_temp.mp4)
        echo "$stats_after"

        LENGTH_AFTER=$(echo "$stats_after" | grep "GB/hour" | awk '{print $2}')
        RATIO_AFTER=$(echo "$stats_after" | grep "GB/hour" | awk '{print $NF}')

        # If the length is different, ask for confirmation
        if [ "$LENGTH_BEFORE" != "$LENGTH_AFTER" ]; then
            echo
            echo "Length is not the same, Skip? (y/n)"
            read -r answer
            if [ "$answer" == "y" ] || [ "$answer" == "" ]; then
                continue
            fi
        fi

        # If the new ratio is not better, ask for confirmation
        if [ $(echo "$RATIO_AFTER > $RATIO_BEFORE" | bc) -eq 1 ]; then
            echo
            echo "Ratio is not better, Skip? (y/n)"
            read -r answer
            if [ "$answer" == "y" ] || [ "$answer" == "" ]; then
                continue
            fi
        fi
        
        echo "Saving file inplace"
        mv output_temp.mp4 "$file"

        echo ""
    done

    rm -f output_temp.mp4
fi