#!/bin/sh

governor=$(cpufreqctl.auto-cpufreq -g | tr ' ' '\n' | head -n 1)

text_icon="" #default

case $governor in
    "performance")
        text_icon=""
        ;;
    "balance_power")
        text_icon=""
        ;;
    "powersave")
        text_icon=""
        ;;
    *)
        #keep defaults if bla bla
        ;;
esac

tooltip_text="${governor}"

echo "{\"text\":\"${text_icon}\",\"tooltip\":\"${tooltip_text}\"}"