#!/usr/bin/env sh
filename=$(find ~/.cache/swww -type f -printf '%T@ %Tc %P\n' | sort -n | tail | sed -r 's/^.{22}//' | tail -1 | awk '{print $NF}')
dunstify $ncolor -a "PyWall" "Generating Color ..." -i "~/.config/dunst/icons/hyprdots.png" -r 91190 -t 2500

wall=$(cat ~/.cache/swww/$filename)

Pywall= wal -s -i $wall
waltg= wal-telegram --wal -g -r
#Geenerate pywall
$Pywall
if [ -z $Pywall ] ; then
     $waltg &
     dunstify $ncolor -a "Pywall" "Color Generated ..." -i "~/.config/dunst/icons/hyprdots.png" -r 91190 -t 2500
fi
