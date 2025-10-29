#!/bin/bash

brightness=$(brightnessctl g)

if [ "$brightness" -lt 90 ]; then
    brightnessctl -d msiacpi::kbd_backlight s 2
else
    echo "meow"
fi