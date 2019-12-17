#!/bin/bash

#requires bc package
# awk
#speedtest-cli
# ifconfig
# editing sudoers file, yuck
# optional: loggers

quitting=""
case "$1" in
    [Qq]*) quitting="Yes";;
    *) quitting="";;
esac

if [ ! -f /tmp/autobandwidth.pid ];then
    #echo "$$" > /tmp/autobandwidth.pid
    # Pausing while load is above two so that load does not 
    MyLoad=$(cat /proc/loadavg | awk '{print $1}')
    while [[ "$MyLoad" > 2 ]];do
        echo "Waiting for load to drop below 2"
        sleep 20s
        echo "."
        MyLoad=$(cat /proc/loadavg | awk '{print $1}')
    done

    # determining what interface is up.  Logic is wired first (and lowest 
    # number if multiple), then wireless the same way. 
    interface=""

    wired=$(ifconfig | grep -e "eno[0-9]" | grep -c -e "UP")

    case $wired in
        0) echo "No wired connection found on eno[0-9]" ;;
        1) interface=$(ifconfig | grep -e "eno[0-9]" | awk -F ':' '{print $1}') ;;
        2|3|4|5|6|7) interface=$(ifconfig | grep -e "eno[0-9]" | head -1 | awk -F ':' '{print $1}') ;;
    esac
    
    if [ -z "$interface" ];then
        wireless=$(ifconfig | grep -e "wlp[0-9]s[0-9]" | grep -c -e "UP")

        case $wireless in
            0) echo "No wired connection found on wlp[0-9]s[0-9]" ;;
            1) interface=$(ifconfig | grep -e "wlp[0-9]s[0-9]" | awk -F ':' '{print $1}') ;;
            2|3|4|5|6|7) interface=$(ifconfig | grep -e "wlp[0-9]s[0-9]"  | head -1 | awk -F ':' '{print $1}') ;;
        esac
    fi

    if [ -z "$interface" ];then
        if [ -f /usr/bin/logger ];then
            /usr/bin/logger "Autobandwidth unable to find appropriate interface; exiting"
            echo "Autobandwidth unable to find appropriate interface; exiting"
        else
            echo "Autobandwidth unable to find appropriate interface; exiting"
        fi
        rm -rf /tmp/autobandwidth.pid
        exit 99
    fi

    if [ "$quitting" = "Yes" ];then
        if [ -f /usr/bin/logger ];then
            /usr/bin/logger "Clearing wondershaper queues on $interface"
            echo "Clearing wondershaper queues on $interface"
        else
            echo "Clearing wondershaper queues on $interface"
        fi
        sudo wondershaper clear "$interface"
        rm -rf /tmp/autobandwidth.pid
        exit 0
    fi

    # Got our interface and load is low enough, time to make the donuts.
    sudo wondershaper clear "$interface"  # in case there's a leftover queue
    echo "Getting network speed on $interface; this takes a few seconds."
    measured=$(/usr/bin/speedtest-cli --simple | awk -F ':' '{print $2}' | awk '{print $1}' | tail -2)
    down=$(echo "$measured" | head -1)
    up=$(echo "$measured" | tail -1)
    down=$(bc <<<"$down*100*85/100")
    up=$(bc <<<"$up*100*85/100")
    command=$(printf "sudo wondershaper %s %s %s" "$interface" "$down" "$up")
    if [ -f /usr/bin/logger ];then
        /usr/bin/logger "Adjusting queues on $interface to $down / $up"
        echo "Adjusting queues on $interface to $down / $up"
        echo "$measured"
    else
        echo "Adjusting queues on $interface to $down / $up"
        echo "$measured"
    fi
    eval "$command"
    rm -rf /tmp/autobandwidth.pid
fi