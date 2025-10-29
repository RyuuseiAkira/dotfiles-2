#!/bin/bash

# u can touch ts
BLINK_DELAY="0.3"
HOT_TEMP="87"
KB_ON="brightnessctl -q -d msiacpi::kbd_backlight s 1" # max brightness: 3
KB_OFF="brightnessctl -q -d msiacpi::kbd_backlight s 0" # min

COOLER_BOOST_FILE="/sys/devices/platform/msi-ec/cooler_boost" # Path to cooler boost status file

# extract temperature from output
extract_temp() {
  "$@" | jq -r '.text' | grep -oP '\d+°C' | grep -oP '\d+'
}

# send notification
send_notification() {
  notify-send -a "Power" -u critical "Temperature" "$1 temperature is $2°C! Please turn on turbo fan"
}

kb_led() {
  current_kb_brightness=$(brightnessctl -q -d msiacpi::kbd_backlight g)

  for i in {1..3}; do
    $KB_ON
    sleep $BLINK_DELAY
    $KB_OFF
    sleep $BLINK_DELAY
  done

  if [[ "$current_kb_brightness" -ge 1 && "$current_kb_brightness" -le 3 ]]; then
    brightnessctl -q -d msiacpi::kbd_backlight s "$current_kb_brightness"
    echo "Keyboard backlight restored to $current_kb_brightness"
  fi
}

is_cooler_boost_on() {
  if [ -f "$COOLER_BOOST_FILE" ]; then
    current_state=$(cat "$COOLER_BOOST_FILE")
    if [[ "$current_state" == "on" ]]; then
      return 0 # on
    fi
  fi
  return 1 # off or file not found ?
}

cpu_temp=$(extract_temp cpuinfo.sh --use amd)
gpu_temp=$(extract_temp gpuinfo.sh --use amd)

if is_cooler_boost_on; then
  echo "Cooler boost is currently ON"
else
  if [ -n "$cpu_temp" ] && [ "$cpu_temp" -gt $HOT_TEMP ]; then
    #send_notification "CPU" "$cpu_temp"
    #echo "CPU temperature is $cpu_temp°C. Blinking keyboard backlight."
    kb_led
  elif [ -n "$gpu_temp" ] && [ "$gpu_temp" -gt $HOT_TEMP ]; then
    #send_notification "GPU" "$gpu_temp"
    #echo "GPU temperature is $gpu_temp°C. Blinking keyboard backlight."
    kb_led
  fi
fi