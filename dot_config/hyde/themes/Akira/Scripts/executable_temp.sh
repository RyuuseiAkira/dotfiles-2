#!/bin/bash
cooler_boost_file="/sys/devices/platform/msi-ec/cooler_boost"

# Color definitions
red='\033[31m'
green='\033[32m'
reset='\033[0m'  # Reset color 

# Get temp
cputemp=$(cpuinfo.sh --use amd | jq -r '.text' | grep -oP '\d+°C')
gputemp=$(gpuinfo.sh --use amd | jq -r '.text' | grep -oP '\d+°C')

#decor cause i dont like minimalist :D
echo "┌─Temperatures─────┐"
echo
echo -e "${red}    Cpu:${reset}  $cputemp" 
echo -e "${green}    Gpu:${reset}  $gputemp"
echo
echo "└──────────────────┘"
echo "  ˚. ✦.˳·˖✶ ⋆.✧˚."
echo

# Check cooler boost state
current_state=$(cat "$cooler_boost_file")
# print current stage
if [[ "$current_state" == "on" ]]; then
  echo -e "Current cooler boost state: ${green}ON${reset}"
else
  echo -e "Current cooler boost state: ${red}OFF${reset}"
fi
# meow
echo
echo "Enter and type password to toggle cooler boost"
read -n1 -s -r
sudo /home/akira/.config/hyde/themes/Akira/Scripts/toggle_turbo.sh

exit