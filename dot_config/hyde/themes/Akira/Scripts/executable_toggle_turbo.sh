#!/bin/bash

green='\033[32m'
red='\033[31m'
reset='\033[0m' 
cooler_boost_file="/sys/devices/platform/msi-ec/cooler_boost"
#read
current_state=$(cat "$cooler_boost_file")
#change
if [[ "$current_state" == "off" ]]; then
    new_state="on"
else
    new_state="off"
fi
clear
sudo -S echo "$new_state" > "$cooler_boost_file"
echo -e "${green}SUCCESS${reset}"
current_state=$(cat "$cooler_boost_file")
if [[ "$current_state" == "on" ]]; then
  echo -e "Current cooler boost state: ${green}ON${reset}"
else
  echo -e "Current cooler boost state: ${red}OFF${reset}"
fi
read -n1 -s -r
exit