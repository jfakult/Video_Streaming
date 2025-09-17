#!/bin/bash

pgrep -f iwgtk -U root >/dev/null 
if [ $? -eq 0 ]; then
    sudo pkill -U root -f iwgtk
else
    (sudo -E iwgtk >/dev/null 2>/dev/null &)
fi