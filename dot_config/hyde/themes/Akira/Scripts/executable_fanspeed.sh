#!/bin/bash

#waybar stuff
# Check cooler boost status
cooler_boost_status=$(cat /sys/devices/platform/msi-ec/cooler_boost)

if [ "$cooler_boost_status" = "off" ]; then
  icon="󰠝"
else
  icon="󰈐"
fi

echo " $icon"