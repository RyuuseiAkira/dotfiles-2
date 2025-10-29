#!/bin/bash

LEVELS=(0 1 2 3)
CURRENT_LEVEL=$(brightnessctl -q -d msiacpi::kbd_backlight g)

# default
ACTION="${1:-i}"

if [[ "$ACTION" == "i" ]]; then
  NEW_LEVEL=$(( (CURRENT_LEVEL + 1) % ${#LEVELS[@]} ))
elif [[ "$ACTION" == "d" ]]; then
  NEW_LEVEL=$(( (CURRENT_LEVEL - 1 + ${#LEVELS[@]}) % ${#LEVELS[@]} ))
else
  echo "Invalid action: $ACTION"
  exit 1
fi

brightnessctl -q -d msiacpi::kbd_backlight s ${LEVELS[$NEW_LEVEL]}

# usage: ./kblightcycle.sh <action>
# action: 
# i to +1 
# d to -1