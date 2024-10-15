#!/bin/bash

function show_stats {
    if [ ! -f "$file" ]; then
        echo "File $file does not exist"
        return
    fi
    echo "$file"
    #ffprobe -show_format "$file"
    OUTPUT=$(ffprobe -show_format "$file" -v quiet | grep -P "duration|size")
    DURATION=$(echo "$OUTPUT" | grep "duration" | cut -d "=" -f 2)
    SIZE=$(echo "$OUTPUT" | grep "size" | cut -d "=" -f 2)

    # Based on scale=4, minimum file size is 100kb before divide by 0 errors happen
    echo -e min: $(bc <<< "scale=2; $DURATION / 60")"\t\t"GB: $(bc <<< "scale=4; $SIZE / 1024 / 1024 / 1024")"\t\t"GB/hour: $(bc <<< "scale=6; ($SIZE / 1024 / 1024 / 1024) / ($DURATION / 3600)")
    echo
}

if [ $# -eq 0 ]; then
    for file in *.mp4; do
        show_stats $file
    done

    for file in *.wmv; do
        show_stats $file
    done
else
    for file in "$@"; do
        show_stats $file
    done
fi
