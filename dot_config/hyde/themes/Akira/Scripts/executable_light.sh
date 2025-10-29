#!/bin/bash

function cleanup() {
  echo "Exiting..."
}

trap cleanup SIGINT

while true; do
  for level in 3 0; do
    brightnessctl -q -d msiacpi::kbd_backlight s $level
    sleep 0.1
  done
done
