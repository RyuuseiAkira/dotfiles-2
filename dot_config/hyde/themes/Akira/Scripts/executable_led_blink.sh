#!/usr/bin/env bash

PID_FILE="/tmp/webcam_led_blink.pid"
device=udevadm info -a -n /dev/video0 | grep "ATTR{name}==" | cut -d '=' -f 3

# check webcam status
is_webcam_on() {
  webcam_status=$(cat /sys/devices/platform/msi-ec/webcam 2>/dev/null)
  echo "Webcam status: $webcam_status"
  if [ "$webcam_status" = "on" ]; then
    return 0
  else
    return 1
  fi
}

# blink LED
blink_led() {
  trap "rm -f $PID_FILE; exit" SIGTERM SIGINT

  while true; do
    brightnessctl -q -d platform::mute s 1
    sleep 0.5
    brightnessctl -q -d platform::mute s 0
    sleep 0.5

    if [ ! -f "$PID_FILE" ]; then
      echo "off blink_led"
      exit 0
    fi
  done
}

function start_blinking() {
  if is_webcam_on; then
    # Check if a PID file alr exists
    if [ -f "$PID_FILE" ]; then
      echo "running"
      return 1
    fi

    blink_led &
    echo $$ > "$PID_FILE"
    echo "Webcam is on, blinking LED started"
    notify-send -a "t2" -r 91190 -t 800 -i "$HOME/.local/share/icons/Wallbash-Icon/media/cam-on.svg" "Camera on"
    return 0
  else
    echo "Webcam is off"
    # Remove PID file if it exists
    if [ -f "$PID_FILE" ]; then
      rm -f "$PID_FILE"
      echo "Removed PID file"
      notify-send -a "t2" -r 91190 -t 800 -i "$HOME/.local/share/icons/Wallbash-Icon/media/cam-off.svg" "Camera off"
    fi
    return 1
  fi
}

function stop_blinking() {
  if [ -f "$PID_FILE" ]; then
    kill $(cat $PID_FILE)
    rm -f $PID_FILE
    echo "Blinking stopped"
    return 0
  else
    echo "cam off"
    return 1
  fi
}

# Usage:
case "$1" in
  start)
    start_blinking
    ;;
  stop)
    stop_blinking
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac
