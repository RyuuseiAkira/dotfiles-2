#!/bin/bash

device="platform::mute"  # LED device

# Function to check audio mute status
is_audio_muted() {
  pamixer "${srce}" --get-mute | grep -q "false"
}

# Toggle LED based on audio mute status
if is_audio_muted; then
  brightnessctl -q -d "$device" s 0
else
  brightnessctl -q -d "$device" s 1
fi
