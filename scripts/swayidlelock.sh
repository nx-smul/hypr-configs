#!/bin/bash

#Swayidle Timing 
swayidle \
    timeout 900 'hyprctl dispatch dpms off' \
    resume 'hyprctl dispatch dpms on' & 
 swaylock -c 000000ff --image ~/Downloads/bgpp.jpg
 kill %%
 
