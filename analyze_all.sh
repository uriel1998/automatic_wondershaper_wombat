#!/bin/bash

# Analyzing a total average of the logfile.
#Mon 1 00:01
#Ping: 16.828 ms
#Download: 14.05 Mbit/s
#Upload: 1.02 Mbit/s

#averaging

downloadspeed=$(cat ~/speedlog.txt | grep Download: | awk '{ print $2 }' | sort -g | awk -vORS=" " '{ print $1 }' | sed 's/ $//' | awk '{s=0; for (i=1;i<=NF;i++)s+=$i; print s/NF;}')
uploadspeed=$(cat ~/speedlog.txt | grep Upload: | awk '{ print $2 }' | sort -g | awk -vORS=" " '{ print $1 }' | sed 's/ $//' | awk '{s=0; for (i=1;i<=NF;i++)s+=$i; print s/NF;}')

echo "Down: $downloadspeed"
echo "Up: $uploadspeed"
# if apply
# then call wondershaper with values
# need to see what interface is being used