#!/bin/bash

# if being called by Network Manager, the first argument is the interface, 
# the second the action that has just happened.

# We don't need to call this with connectivity-change

if [ "$1" = "connectivity-change" ];then
    exit 1
fi

# The old version of wondershaper didn't have a version switch. The git 
# version does, so that's how we know how to format the command line.


OldOrNewWonderShaper=$(wondershaper -v | grep -c "Version")

quitting=""

if [ $# = 2 ];then # two arguments from Network Manager
    if [ -n "$1" ];then
        interface="$1"
    fi
    case "$2" in
        vpn-down|down) quitting="Yes";;
        vpn-up|up) quitting="";;
        "") interface="";;  #if there isn't a second argument, Network Manager didn't call it.
    esac
fi

if [ $# = 1 ];then # standalone to quit
    if [ "$1" = "quit" ];then 
        quitting="Yes"
    fi
fi


if [ "$quitting" = "Yes" ] && [ $# = 2 ];then
    if [ -f /tmp/autobandwidth.pid ];then
        ABWPID=$(cat /tmp/autobandwidth.pid)
        rm -rf /tmp/autobandwidth.pid
        kill -9 "$ABWPID" &> /dev/null
    fi
    if [ -f /usr/bin/logger ];then
        /usr/bin/logger "Clearing wondershaper queues on $interface"
        echo "Clearing wondershaper queues on $interface"
    else
        echo "Clearing wondershaper queues on $interface"
    fi
    if [ "$OldOrNewWonderShaper" = 1 ];then
        sudo /sbin/wondershaper -c -a "$interface"  # in case there's a leftover queue
    else
        sudo /sbin/wondershaper clear "$interface"  # in case there's a leftover queue
    fi
    exit 0
fi



if [ ! -f /tmp/autobandwidth.pid ];then

    if [ "$quitting" != "Yes" ];then
        echo "$$" > /tmp/autobandwidth.pid
    fi
    
    # Pausing to let link handshakes finish, since this keeps getting called early...
    sleep 10s
    
    # Pausing while load is above two so that load does not 
    MyLoad=$(cat /proc/loadavg | awk '{print $1}')
    while (( $(echo "$MyLoad > 2" |bc -l) )); do ####EDIT THIS LINE FOR LOAD CHANGES
        echo "Waiting for load to drop below 2"
        sleep 20s
        echo "."
        MyLoad=$(cat /proc/loadavg | awk '{print $1}')
    done

    # determining what interface is up if not passed to it by Network Manager.  
    # Logic is wired first (and lowest number if multiple), then wireless the same way. 
    if [ -z "$interface" ];then
        interface=""

        wired=$(ifconfig | grep -e "eno[0-9]" | grep -c -e "RUNNING")

        case $wired in
            0) echo "No wired connection found on eno[0-9]" ;;
            1) interface=$(ifconfig | grep -e "eno[0-9]" | awk -F ':' '{print $1}') ;;
            2|3|4|5|6|7) interface=$(ifconfig | grep -e "eno[0-9]" | head -1 | awk -F ':' '{print $1}') ;;
        esac
        
        if [ -z "$interface" ];then
            wireless=$(ifconfig | grep -e "wlp[0-9]s[0-9]" | grep -c -e "RUNNING")

            case $wireless in
                0) echo "No wired connection found on wlp[0-9]s[0-9]" ;;
                1) interface=$(ifconfig | grep -e "wlp[0-9]s[0-9]" | awk -F ':' '{print $1}') ;;
                2|3|4|5|6|7) interface=$(ifconfig | grep -e "wlp[0-9]s[0-9]"  | head -1 | awk -F ':' '{print $1}') ;;
            esac
        fi

        if [ -z "$interface" ];then
            if [ -f /usr/bin/logger ];then
                /usr/bin/logger "Autobandwidth unable to find appropriate interface; exiting"
                echo "Autobandwidth unable to find appropriate interface; exiting" >&2
            else
                echo "Autobandwidth unable to find appropriate interface; exiting" >&2
            fi
            rm -rf /tmp/autobandwidth.pid
            exit 99
        fi
    fi
    
    
    if [ "$quitting" = "Yes" ];then
        if [ -f /tmp/autobandwidth.pid ];then
            ABWPID=$(cat /tmp/autobandwidth.pid)
            rm -rf /tmp/autobandwidth.pid
            kill -9 "$ABWPID" &> /dev/null
        fi

        if [ -f /usr/bin/logger ];then
            /usr/bin/logger "Clearing wondershaper queues on $interface"
            echo "Clearing wondershaper queues on $interface"
        else
            echo "Clearing wondershaper queues on $interface"
        fi
        if [ "$OldOrNewWonderShaper" = 1 ];then
            sudo /sbin/wondershaper -c -a "$interface"  # in case there's a leftover queue
        else
            sudo /sbin/wondershaper clear "$interface"  # in case there's a leftover queue
        fi
        rm -rf /tmp/autobandwidth.pid
        exit 0
    fi

    # Adding an additional check here; it was being called twice????

    Running=$(ps aux | grep -v "grep" | grep -c "speedtest-cli")
    
    if [ "$Running" -gt 0 ];then
        if [ -f /usr/bin/logger ];then
            /usr/bin/logger "Speedtest is already running; exiting"
            echo "Speedtest is already running; exiting"
        else
            echo "Speedtest is already running; exiting"
        fi
        exit 1
    fi


        
    # Got our interface and load is low enough, time to make the donuts.
    if [ "$OldOrNewWonderShaper" = 1 ];then
        sudo /sbin/wondershaper -c -a "$interface"  # in case there's a leftover queue
    else
        sudo /sbin/wondershaper clear "$interface"  # in case there's a leftover queue
    fi
    echo "Getting network speed on $interface; this takes a few seconds."
    measured=$(/usr/bin/speedtest-cli --simple | awk -F ':' '{print $2}' | awk '{print $1}' | tail -2)
    odown=$(echo "$measured" | head -1)
    oup=$(echo "$measured" | tail -1)
    down=$(bc <<<"$odown*1000*85/100")
    up=$(bc <<<"$oup*1000*85/100")
    if [ "$up" -lt 5 ] && [ "$down" -lt 5 ];then
        if [ -f /usr/bin/logger ];then
            /usr/bin/logger "Reported rates too low; exiting."
            echo "Reported rates too low; exiting." >&2
            exit 98
        else
            echo "Reported rates too low; exiting." >&2
            exit 98
        fi
    fi
    
    if [ "$OldOrNewWonderShaper" = 1 ];then
        command=$(printf "sudo /sbin/wondershaper -a %s -d %s -u %s" "$interface" "$down" "$up")
    else
        command=$(printf "sudo /sbin/wondershaper %s %s %s" "$interface" "$down" "$up")
    fi
    if [ -f /usr/bin/logger ];then
        /usr/bin/logger "Logged $odown / $oup - Adjusting queues on $interface to $down / $up"
        echo "Logged $odown / $oup - Adjusting queues on $interface to $down / $up"
    else
        echo "Logged $odown / $oup - Adjusting queues on $interface to $down / $up"
    fi
    eval "$command"
    printf "%s: %s/%s" "$interface" "$down" "$up" > /tmp/bandwidthqueues
    rm -rf /tmp/autobandwidth.pid
fi
