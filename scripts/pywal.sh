 #!/usr/bin/env s

dunstify $ncolor "theme" -a "Generating Color ..." -i "~/.config/dunst/icons/hyprdots.png" -r 91190 -t 2200

wall=$(cat ~/.cache/swww/eDP-1)

Pywall= wal -s -i $wall
waltg= wal-telegram --wal -g -r
#Geenerate pywall
$Pywall
if [ -z $Pywall ] ; then
     $waltg &
     dunstify $ncolor "theme" -a "Color Generated ..." -i "~/.config/dunst/icons/hyprdots.png" -r 91190 -t 2200
fi
