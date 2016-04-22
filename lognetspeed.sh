#!/bin/bash

# Logs in this manner:
#Mon 1 00:01
#Ping: 16.828 ms
#Download: 14.05 Mbit/s
#Upload: 1.02 Mbit/s

date +%a\ \%u\ %H:%M | tee -a ~/speedlog.txt
speedtest --simple | tee -a ~/speedlog.txt	
echo " " >> ~/speedlog.txt
