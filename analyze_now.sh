#!/bin/bash

# Attempting to get a statistical average
#Mon 1 00:01
#Ping: 16.828 ms
#Download: 14.05 Mbit/s
#Upload: 1.02 Mbit/s

#averaging
#date +%a\ \%u\ %H:%M | tee -a ~/speedlog.txt
cat ~/speedlog.txt | grep Download: | awk '{ print $2 }' | sort -g | awk -vORS=" " '{ print $1 }' | sed 's/ $//' | awk '{s=0; for (i=1;i<=NF;i++)s+=$i; print s/NF;}'
cat ~/speedlog.txt | grep Upload: | awk '{ print $2 }' | sort -g | awk -vORS=" " '{ print $1 }' | sed 's/ $//' | awk '{s=0; for (i=1;i<=NF;i++)s+=$i; print s/NF;}'

